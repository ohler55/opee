
module Opee
  # An Exception indicating an required option was missing.
  class MissingOptionError < Exception
    def initialize(option, msg)
      super("option #{option} for #{msg} missing")
    end
  end # MissingOptionError

  # An Exception indicating an Actor was too busy to complete the requested operation.
  class BusyError < Exception
    def initialize()
      super("Busy, try again later")
    end
  end # BusyError

end # Opee
