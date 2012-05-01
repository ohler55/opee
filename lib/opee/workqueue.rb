
module Opee
  class WorkQueue < Actor

    def initialize(options={})
      @workers = []
      @work_queue = []
      @method = nil
      super(options)
    end

    def work_queue_size()
      @work_queue.size
    end

    private

    def set_options(options)
      raise MissingOptionError.new(:method, "for processing jobs") if (@method = options[:method]).nil?
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
        worker.ask(@method, job)
      end
    end

  end # WorkQueue
end # Opee
