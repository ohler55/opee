
module Opee
  # A holder for data processed by Actors. It lends support to the use of
  # Collectors if the support behavior is desired in the Job instead of the
  # Collector itself.
  class Job

    def initialize()
    end

    # Returns the key associated with the job. The default behavior is to
    # raise a NotImplementedError.
    # @return [Object] a key for looking up the token in the cache
    def key()
      object_id()
    end

    # Updates the token associated with the job. The default behavior is to
    # raise a NotImplementedError.
    # @param [Object] token current token value or nil for the first token value
    # @param [Object] path_id an indicator of the path if used
    # @return [Object] a token to keep track of the progress of the job
    def update_token(token, path_id)
      raise NotImplementedError.new("update_token() not implemented")
    end

    # Returns true if the job has been processed by all paths converging on
    # the collector. The default behavior is to raise a NotImplementedError.
    # @param [Object] token current token value or nil for the first token value
    # @return [true|false] an indication of wether the job has completed all paths
    def complete?(token)
      raise NotImplementedError.new("complete?() not implemented")
    end

    private

    # Moves the job onto the next Actor.  Make public if implemented otherwise
    # leave private so it is not called.
    def keep_going()
    end

  end # Job
end # Opee
