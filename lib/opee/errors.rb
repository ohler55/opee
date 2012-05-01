
module Opee
  class MissingOptionError < Exception
    def initialize(option, msg)
      super("option #{option} for #{msg} missing")
    end
  end # MissingOptionError

  class BusyError < Exception
    def initialize()
      super("Busy, try again later")
    end
  end # BusyError

end # Opee
