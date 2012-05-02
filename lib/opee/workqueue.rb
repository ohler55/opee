
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

    private

    def set_options(options)
      super(options)
      raise MissingOptionError.new(:method, "for processing jobs") if (@method = options[:method]).nil?
      @max_job_count = options.fetch(:max_job_count, @max_job_count)
      @job_timeout = options.fetch(:job_timeout, @job_timeout)
    end

    def ask(op, *args)
      if :add == op && 0 < @max_job_count && @work_queue.size() >= @max_job_count
        @add_thread = Thread.current
        sleep(@job_timeout) unless 0.0 >= @job_timeout
        @add_thread = nil
        raise BusyError.new() unless @work_queue.size() < @max_job_count
      end
      super
    end

    def add(job, timeout=3.0)
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
