
module Opee
  # 
  class Job

    def initialize()
    end

    def key()
      object_id()
    end

    def update_token(token)
      raise NotImplementedError.new("update_token() not implemented")
    end

    def complete?(token)
      raise NotImplementedError.new("complete?() not implemented")
    end

    private

    # Make public if implemented otherwise leave private so it is not called.
    def keep_going()
    end

  end # Job
end # Opee
