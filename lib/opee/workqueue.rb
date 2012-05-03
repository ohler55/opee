
module Opee
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

    def work_queue_size()
      @work_queue.size
    end

    def worker_count()
      @workers.size
    end

    def busy?
      !@work_queue.empty? || super
    end

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

    def set_options(options)
      super(options)
      raise MissingOptionError.new(:method, "for processing jobs") if (@method = options[:method]).nil?
      @max_job_count = options.fetch(:max_job_count, @max_job_count)
      @job_timeout = options.fetch(:job_timeout, @job_timeout)
    end

    def add(job)
      if @workers.empty?
        @work_queue.insert(0, job)
      else
        worker = @workers.pop()
        worker.ask(@method, job)
      end
    end

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
