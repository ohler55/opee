
module Opee
  # Implements a work queue Actor that will distribute method calls to Actors
  # that volunteer to execute those methods. The primary use is to distribute
  # work across multiple workers.
  class AskQueue < Queue

    def initialize(options={})
      super(options)
    end

    # Queues an operation and arguments to be handed off to a worker when the worker is ready.
    # @param [Symbol] op method to queue for the Actor
    # @param [Array] args arguments to the op method
    # @raise [BusyError] if the request queue does not become available in the {#ask_timeout} seconds
    def add_method(op, *args)
      ask(:add, Act.new(op, args))
    end

    private

    # Asks the worker to invoke the method of an Act Object.
    def ask_worker(worker, job)
      raise NoMethodError.new("undefined method for #{job.class}. Expected a method invocation") unless job.is_a?(Actor::Act)
      worker.ask(job.op, *job.args)
    end

  end # AskQueue
end # Opee
