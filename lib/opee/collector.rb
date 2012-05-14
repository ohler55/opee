
module Opee
  # This class is used to collect multiple paths together before proceeding in
  # a system. Two approaches are supported, either let the Collector subclass
  # identify when it is time to move on or put the logic in the Job that is
  # passed between the various Actors.
  #
  # To use a Collector, pass the same data along each path of Actors. All
  # paths should terminate at the Collector. From there the Collector keeps a
  # cache of the data's key and a token that is used to track arrivals. When
  # all paths have converged the next Actor in the process is called.
  class Collector < Actor
    
    def initialize(options={})
      @cache = {}
      @next_actor = nil
      @next_method = nil
      super(options)
    end
    
    # Returns the number of Jobs currently waiting to be matched.
    # @return [Fixnum] current number of Jobs waiting to finish.
    def cache_size()
      @cache.size()
    end

    private

    # Processes the initialize() options. Subclasses should call super.
    # @param [Hash] options options to be used for initialization
    # @option options [Actor] :next_actor Actor to ask to continue when ready
    # @option options [Symbol] :next_method method to ask of the next_actor to continue when ready
    def set_options(options)
      super(options)
      @next_actor = options[:next_actor]
      @next_method = options[:next_method]
      @next_method = @next_method.to_sym if @next_method.is_a?(String)
    end

    # Collects a job and deternines if the job should be moved on to the next
    # Actor or if it should wait until more processing paths have
    # finished. This method is executed asynchronously.
    # @param [Job|Object] job data to process or pass on
    def collect(job, path_id=nil)
      key = job_key(job)
      token = @cache[key]
      token = update_token(job, token, path_id)
      if complete?(job, token)
        @cache.delete(key)
        keep_going(job)
      else
        @cache[key] = token
      end
    end

    # Returns the key associated with the job. If the job responds to :key
    # then that method is called, otherwise the subclass should implement this
    # method. This method is executed asynchronously.
    # @param [Object] job data to get the key for
    # @return [Object] a key for looking up the token in the cache
    def job_key(job)
      raise NotImplementedError.new("neither Collector.job_key() nor Job.key() are implemented") unless job.respond_to?(:key)
      job.key()
    end

    # Updates the token associated with the job. The job or the Collector
    # subclass can use any data desired to keep track of the job's paths that
    # have been completed. This method is executed asynchronously.
    # @param [Object] job data to get the key for
    # @param [Object] token current token value or nil for the first token value
    # @param [Object] path_id an indicator of the path if used
    # @return [Object] a token to keep track of the progress of the job
    def update_token(job, token, path_id)
      raise NotImplementedError.new("neither Collector.update_token() nor Job.update_token() are implemented") unless job.respond_to?(:update_token)
      job.update_token(token, path_id)
    end

    # Returns true if the job has been processed by all paths converging on
    # the collector. This can be implemented in the Collector subclass or in
    # the Job. This method is executed asynchronously.
    # @param [Object] job data to get the key for
    # @param [Object] token current token value or nil for the first token value
    # @return [true|false] an indication of wether the job has completed all paths
    def complete?(job, token)
      raise NotImplementedError.new("neither Collector.complete?() nor Job.complete?() are implemented") unless job.respond_to?(:complete?)
      job.complete?(token)
    end

    # Moves the job onto the next Actor. If the job responds to :keep_going
    # that is used, otherwise the @next_actor and @next_method care used to
    # continue. This method is executed asynchronously.
    # @param [Object] job data to get the key for
    def keep_going(job)
      if job.respond_to?(:keep_going)
        job.keep_going()
      else
        # TBD @next_actor = Env.find_actor(@next_actor) if @next_actor.is_a?(Symbol)
        @next_actor.send(@next_method, job)
      end
    end

  end # Collector
end # Opee
