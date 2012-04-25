
module Opee

  class Actor

    def initialize(options={})
      @queue = []
      @ask_mutex = Mutex.new()
      @ask_timeout = 0.0
      @max_queue_count = nil
      @running = true
      Env.add_actor(self)
      set_options(options)
      @loop = Thread.start(self) do |me|
        begin
          sleep(1.0) if @queue.empty?
          unless @queue.empty?
            a = nil
            @ask_mutex.synchronize {
              a = @queue.pop()
            }
            send(a.op, *a.args)
          end
        rescue Exception => e
          # TBD handle errors by passing them to a error handler
          puts "*** #{e.class}: #{e.message}"
          e.backtrace.each { |line| puts "    " + line }
        end
      end
    end

    def set_options(options)
      # 
    end

    # deep copy and freeze args if not already frozen or primitive types
    def ask(op, *args)
      @ask_mutex.synchronize {
        @queue << Act.new(op, args)
      }
      @loop.wakeup() if @running
    end

    def method_missing(m, *args, &blk)
      ask(m, *args)
    end

    def queue_count()
      @queue.length
    end

    def stop()
      @running = false
    end

    def start()
      @running = true
      @loop.wakeup()
    end

    def close()
      @running = false
      Env.remove_actor(self)
    end

    private

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
