
module Opee
  # The Actor class is the base class for all the asynchronous Objects in
  # OPEE. It accepts requests through the ask() method and excutes those
  # methods on a thread dedicated to the Actor.
  class Actor
    # value of @state that indicates the Actor is not currently processing requests
    STOPPED = 0
    # value of @state that indicates the Actor is currently ready to process requests
    RUNNING = 1
    # value of @state that indicates the Actor is shutting down
    CLOSING = 2
    # value of @state that indicates the Actor is processing one request and
    # will stop after that processing is complete
    STEP    = 3

    # The current processing state of the Actor
    attr_reader :state
    # name of the actor
    attr_reader :name

    # Initializes the Actor with the options specified. A new thread is
    # created during intialization after calling the set_options() method.
    # @param [Hash] options options to be used for initialization
    # @option options [Fixnum] :max_queue_count maximum number of requests
    #         that can be queued before backpressure is applied to the caller.
    # @option options [Float] :ask_timeout timeout in seconds to wait
    #         before raising a BusyError if the request queue if too long.
    def initialize(options={})
      @queue = []
      @idle = []
      @priority = []
      @ask_mutex = Mutex.new()
      @priority_mutex = Mutex.new()
      @idle_mutex = Mutex.new()
      @step_thread = nil
      @ask_timeout = 0.0
      @max_queue_count = nil
      @ask_thread = nil
      @state = RUNNING
      @busy = false
      @name = nil
      Env.add_actor(self)
      set_options(options)
      @loop = Thread.start(self) do |me|
        Thread.current[:name] = me.name
        while CLOSING != @state
          begin
            if RUNNING == @state || STEP == @state
              a = nil
              if !@priority.empty?
                @priority_mutex.synchronize {
                  a = @priority.pop()
                }
              elsif !@queue.empty?
                @ask_mutex.synchronize {
                  a = @queue.pop()
                }
                @ask_thread.wakeup() unless @ask_thread.nil?
              elsif !@idle.empty?
                @idle_mutex.synchronize {
                  a = @idle.pop()
                }
              else
                Env.wake_finish()
                sleep(1.0)
              end
              @busy = true
              send(a.op, *a.args) unless a.nil?
              @busy = false
              if STEP == @state
                @step_thread.wakeup() unless @step_thread.nil?
                @state = STOPPED
              end
            elsif STOPPED == @state
              sleep(1.0)
            end
          rescue Exception => e
            Env.rescue(e)
            @busy = false
          end
        end
      end
    end

    # Processes the initialize() options. Subclasses should call super.
    # @param [Hash] options options to be used for initialization
    # @option options [Fixnum] :max_queue_count maximum number of requests
    #         that can be queued before backpressure is applied to the caller.
    # @option options [Float] :ask_timeout timeout in seconds to wait
    #         before raising a BusyError if the request queue is too long.
    def set_options(options)
      @max_queue_count = options.fetch(:max_queue_count, @max_queue_count)
      @ask_timeout = options.fetch(:ask_timeout, @ask_timeout).to_f
      @name = options[:name]
    end

    # Sets the name of the Actor.
    # @param [String] name new name
    def name=(name)
      @name = name
      @loop[:name] = name
    end

    # Calls {#ask}() but uses the specified timeout instead of the default
    # {#ask_timeout} to determine how long to wait if the Actor's queue is full.
    # @param [Fixnum|Float] timeout maximum time to wait trying to add a request to the Actor's queue
    # @param [Symbol] op method to queue for the Actor
    # @param [Array] args arguments to the op method
    # @raise [BusyError] if the request queue does not become available in the timeout specified
    def timeout_ask(timeout, op, *args)
      unless @max_queue_count.nil? || 0 == @max_queue_count || @queue.size() < @max_queue_count
        @ask_thread = Thread.current
        sleep(timeout) unless timeout.nil?
        @ask_thread = nil
        raise BusyError.new() unless @queue.size() < @max_queue_count
      end
      @ask_mutex.synchronize {
        @queue.insert(0, Act.new(op, args))
      }
      @loop.wakeup() if RUNNING == @state
    end

    # Queues an operation and arguments to be called when the Actor is ready.
    # @param [Symbol] op method to queue for the Actor
    # @param [Array] args arguments to the op method
    # @raise [BusyError] if the request queue does not become available in the {#ask_timeout} seconds
    def ask(op, *args)
      timeout_ask(@ask_timeout, op, *args)
    end

    # Queues an operation and arguments to be called when the Actor is has no
    # other requests to process.
    # @param [Symbol] op method to queue for the Actor
    # @param [Array] args arguments to the op method
    def on_idle(op, *args)
      @idle_mutex.synchronize {
        @idle.insert(0, Act.new(op, args))
      }
      @loop.wakeup() if RUNNING == @state
    end

    # Queues an operation and arguments to be called as soon as possible by
    # the Actor. These requests take precedence over other ordinary requests.
    # @param [Symbol] op method to queue for the Actor
    # @param [Array] args arguments to the op method
    def priority_ask(op, *args)
      @priority_mutex.synchronize {
        @priority.insert(0, Act.new(op, args))
      }
      @loop.wakeup() if RUNNING == @state
    end

    # When an attempt is made to call a private method of the Actor it is
    # places on the processing queue. Other methods cause a NoMethodError to
    # be raised as it normally would.
    # @param [Symbol] m method to queue for the Actor
    # @param [Array] args arguments to the op method
    # @param [Proc] blk ignored
    def method_missing(m, *args, &blk)
      raise NoMethodError.new("undefined method '#{m}' for #{self.class}", m, args) unless respond_to?(m, true)
      ask(m, *args)
    end

    # Returns the number of requests on all three request queues, the normal,
    # priority, and idle queues.
    # @return [Fixnum] number of queued requests
    def queue_count()
      @queue.length + @priority.length + @idle.length
    end

    # Returns the true if any requests are queued or a request is being processed.
    # @return [true|false] true if busy, false otherwise
    def busy?()
      @busy || !@queue.empty? || !@priority.empty? || !@idle.empty?
    end

    # Returns the default timeout for the time to wait for the Actor to be
    # ready to accept a request using the {#ask}() method.
    # @return [Float] current timeout for the {#ask}() method
    def ask_timeout()
      @ask_timeout
    end

    # Returns the maximum number of requests allowed on the normal processing
    # queue. A value of nil indicates there is no limit.
    # @return [NilClass|Fixnum] maximum number of request that can be queued
    def max_queue_count()
      @max_queue_count
    end

    # Causes the Actor to stop processing any more requests after the current
    # request has finished.
    def stop()
      @state = STOPPED
    end

    # Causes the Actor to process one request and then stop. The max_wait is
    # used to avoid getting stuck if the processing takes too long.
    # @param [Float|Fixnum] max_wait maximum time to wait for the step to complete
    def step(max_wait=5)
      @state = STEP
      @step_thread = Thread.current
      @loop.wakeup()
      sleep(max_wait)
      @step_thread = nil
    end

    # Wakes up the Actor if it has been stopped or if Env.shutdown() has been called.
    def wakeup()
      @loop.wakeup()
    end

    # Restarts the Actor's processing thread.
    def start()
      @state = RUNNING
      @loop.wakeup()
    end

    # Closes the Actor by exiting the processing thread and removing the Actor
    # from the Env.
    def close()
      @state = CLOSING
      begin
        # if the loop has already exited this will raise an Exception that can be ignored
        @loop.wakeup()
      rescue
        # ignore
      end
      Env.remove_actor(self)
      @loop.join()
    end

    private

    # Sets the {#ask_timeout} value which limits how long a caller will wait
    # before getting a BusyError when calling {#ask}(). This method is
    # executed asynchronously.
    # @param [Float] timeout seconds to set the ask_timeout to
    def ask_timeout=(timeout)
      @ask_timeout = timeout
    end

    # Sets the {#max_queue_count} value which limits the number of requests
    # that can be on the Actor's queue. This method is executed
    # asynchronously.
    # @param [Fixnum] max maximum number of requests or nil for no limit
    def max_queue_count=(max)
      @max_queue_count = max
    end

    # Internal class used to store information about asynchronous method
    # invocations.
    class Act
      attr_accessor :op
      attr_accessor :args

      def initialize(op, args)
        @op = op
        @args = args
      end
    end

  end # Actor
end # Opee
