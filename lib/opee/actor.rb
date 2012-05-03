
module Opee

  class Actor
    STOPPED = 0
    RUNNING = 1
    CLOSING = 2
    STEP    = 3

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
      Env.add_actor(self)
      set_options(options)
      @loop = Thread.start(self) do |me|
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
            Env.log_rescue(e)
          end
        end
      end
    end

    def set_options(options)
      @max_queue_count = options.fetch(:max_queue_count, @max_queue_count)
      @ask_timeout = options.fetch(:ask_timeout, @ask_timeout)
    end

    # deep copy and freeze args if not already frozen or primitive types
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

    def ask(op, *args)
      timeout_ask(@ask_timeout, op, *args)
    end

    def on_idle(op, *args)
      @idle_mutex.synchronize {
        @idle.insert(0, Act.new(op, args))
      }
      @loop.wakeup() if RUNNING == @state
    end

    def priority_ask(op, *args)
      @priority_mutex.synchronize {
        @priority.insert(0, Act.new(op, args))
      }
      @loop.wakeup() if RUNNING == @state
    end

    def method_missing(m, *args, &blk)
      raise NoMethodError.new("undefine method '#{m}' for #{self.class}", m, args) unless respond_to?(m, true)
      ask(m, *args)
    end

    def queue_count()
      @queue.length + @priority.length + @idle.length
    end

    def busy?
      @busy || !@queue.empty? || !@priority.empty? || !@idle.empty?
    end

    def ask_timeout()
      @ask_timeout
    end

    def max_queue_count
      @max_queue_count
    end

    def stop()
      @state = STOPPED
    end

    def step(max_wait=5)
      @state = STEP
      @step_thread = Thread.current
      @loop.wakeup()
      sleep(max_wait)
    end

    def wakeup()
      @loop.wakeup()
    end

    def start()
      @state = RUNNING
      @loop.wakeup()
    end

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

    def ask_timeout=(timeout)
      @ask_timeout = timeout
    end

    def max_queue_count=(max)
      @max_queue_count = max
    end

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
