
module Opee
  # Implements a work queue Actor that will distribute jobs to Actors that
  # volunteer to complete those jobs. The primary use is to distribute work or
  # jobs across multiple workers.
  class WorkQueue < Queue

    def initialize(options={})
      @method = nil
      super(options)
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

    private

    # Processes the initialize() options. Subclasses should call super.
    # @param [Hash] options options to be used for initialization
    # @option options [Symbol] :method method to call on workers
    def set_options(options)
      super(options)
      raise MissingOptionError.new(:method, "for processing jobs") if (@method = options[:method]).nil?
    end

    # Asks the worker to invoke the default method on a job.
    def ask_worker(worker, job)
      worker.ask(@method, job)
    end

  end # WorkQueue
end # Opee
