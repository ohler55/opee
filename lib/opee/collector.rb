
module Opee
  # 
  class Collector < Actor

    def initialize(options={})
      @cache = {}
      @next_actor = nil
      @next_method = nil
      super(options)
    end

    private

    def set_options(options)
      super(options)
      @next_actor = options[:next_actor]
      @next_method = options[:next_method]
      @next_method = @next_method.to_sym if @next_method.is_a?(String)
    end

    def collect(job)
      key = job_key(job)
      token = @cache[key]
      token = update_token(job, token)
      if complete?(job, token)
        @cache.delete(key)
        keep_going(job)
      else
        @cache[key] = token
      end
    end

    def job_key(job)
      raise NotImplementedError.new("neither Collector.job_key() nor Job.key() are implemented") unless job.respond_to?(:key)
      job.key()
    end

    def update_token(job, token)
      raise NotImplementedError.new("neither Collector.update_token() nor Job.update_token() are implemented") unless job.respond_to?(:update_token)
      job.update_token(token)
    end

    def complete?(job, token)
      raise NotImplementedError.new("neither Collector.complete?() nor Job.complete?() are implemented") unless job.respond_to?(:complete?)
      job.complete?(token)
    end

    def keep_going(job)
      if job.respond_to?(:keep_going)
        job.keep_going()
      else
        # TBD @next_actor = Env.find_actor(@next_actor) if @next_actor.is_a?(Symbol)
        @next_actor.send(:@next_method, job)
      end
    end

  end # Collector
end # Opee
