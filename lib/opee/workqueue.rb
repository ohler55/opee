
module Opee
  # Implements a work queue Actor that ill distribute jobs to Actors that
  # volunteer to complete those jobs. The primary use is to distribute work or
  # jobs across multiple workers.
  class WorkQueue < Actor

    def initialize(options={})
      @workers = []
      @work_queue = []
      @method = nil
      @max_job_count = 0
      @job_timeout = 3.0
      @add_thread = nil
      super(options)
    end

    # Returns the number of jobs currently on the work queue.
    # @return [Fixnum] number of waiting jobs
    def work_queue_size()
      @work_queue.size
    end

    # Returns the number of worker Actors waiting to process jobs.
    # @return [Fixnum] number of waiting workers
    def worker_count()
      @workers.size
    end

    # Returns the method invoked on the workers to process a job.
    # @return [Symbol] method workers are asked to complete
    def method()
      @workers.size
    end

    # Returns the true if any requests are queued, a request is being
    # processed, or if there are jobs waiting on the work request queue.
    # @return [true|false] true if busy, false otherwise
    def busy?
      !@work_queue.empty? || super
    end

    # Verifies that additional jobs can be added to the work queue before
    # allowing an {#add}() to be called.
    # @see Actor#ask
    def ask(op, *args)
      if :add == op && 0 < @max_job_count && (@work_queue.size() + @queue.size()) >= @max_job_count
        unless 0.0 >= @job_timeout
          @add_thread = Thread.current
          give_up_at = Time.now + @job_timeout
          until Time.now > give_up_at || (@work_queue.size() + @queue.size()) < @max_job_count
            sleep(@job_timeout)
          end
          @add_thread = nil
        end
        raise BusyError.new() unless @work_queue.size() < @max_job_count
      end
      super
    end

    private

    # Processes the initialize() options. Subclasses should call super.
    # @param [Hash] options options to be used for initialization
    # @option options [Symbol] :method method to call on workers
    # @option options [Fixnum] :max_job_count maximum number of jobs
    #         that can be queued before backpressure is applied to the caller.
    # @option options [Float] :job_timeout timeout in seconds to wait
    #         before raising a BusyError if the work queue is too long.
    def set_options(options)
      super(options)
      raise MissingOptionError.new(:method, "for processing jobs") if (@method = options[:method]).nil?
      @max_job_count = options.fetch(:max_job_count, @max_job_count)
      @job_timeout = options.fetch(:job_timeout, @job_timeout)
    end

    # Places a job on the work queue. This method is executed asynchronously.
    # @param [Object] job work to be processed
    def add(job)
      if @workers.empty?
        @work_queue.insert(0, job)
      else
        worker = @workers.pop()
        worker.ask(@method, job)
      end
    end

    # Identifies a worker as available to process jobs when they become
    # available. This method is executed asynchronously.
    # @param [Actor] worker Actor that responds to the {#method}
    def ready(worker)
      if @work_queue.empty?
        @workers.insert(0, worker) unless @workers.include?(worker)
      else
        job = @work_queue.pop()
        @add_thread.wakeup() unless @add_thread.nil?
        worker.ask(@method, job)
      end
    end

  end # WorkQueue
end # Opee
