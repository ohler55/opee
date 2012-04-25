
module Opee
  class Env

    @@actors = []
    @@log = nil

    def self.add_actor(actor)
      @@actors << actor
    end

    def self.remove_actor(actor)
      @@actors.delete(actor)
    end

    def self.each_actor(&blk)
      @@actors.each { |a| blk.yield(a) }
    end

    def self.shutdown()
      # TBD pop and close each actor
    end

    def self.log(severity, message)
      @@log = Log.new() if @@log.nil?
      @@log.ask(:log, severity, message)
    end

    def self.logger()
      @@log = Log.new() if @@log.nil?
      @@log
    end

  end # Env
end # Opee
