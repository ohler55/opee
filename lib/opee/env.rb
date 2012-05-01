
module Opee
  class Env

    @@actors = []
    @@log = nil
    @@finish_thread = nil

    def self.add_actor(actor)
      @@actors << actor
    end

    def self.remove_actor(actor)
      @@actors.delete(actor)
    end

    def self.each_actor(&blk)
      @@actors.each { |a| blk.yield(a) }
    end

    def self.actor_count()
      @@actors.size
    end

    def self.shutdown()
      until @@actors.empty?
        a = @@actors.pop()
        a.close()
      end
      @@log = nil
    end

    def self.log(severity, message)
      @@log = Log.new() if @@log.nil?
      @@log.ask(:log, severity, message)
    end

    def self.debug(message)
      log(Logger::Severity::DEBUG, message)
    end

    def self.info(message)
      log(Logger::Severity::INFO, message)
    end

    def self.warn(message)
      log(Logger::Severity::WARN, message)
    end

    def self.error(message)
      log(Logger::Severity::ERROR, message)
    end

    def self.fatal(message)
      log(Logger::Severity::FATAL, message)
    end

    def self.log_rescue(ex)
      @@log = Log.new() if @@log.nil?
      return unless Logger::Severity::ERROR >= @@log.level
      msg = "#{ex.class}: #{ex.message}"
      if Logger::Severity::WARN >= @@log.level
        ex.backtrace.each { |line| msg << "    #{line}\n" }
      end
      @@log.ask(:log, Logger::Severity::ERROR, msg)
    end

    def self.logger()
      @@log = Log.new() if @@log.nil?
      @@log
    end

    def self.logger=(log_actor)
      @@log.close() unless @@log.nil?
      @@log = log_actor
      @@log
    end

    def self.queue_count()
      cnt = 0
      @@actors.each { |a| cnt += a.queue_count() }
      cnt
    end

    def self.stop()
      @@actors.each { |a| a.stop() }
    end

    def self.start()
      @@finish_thread = nil
      @@actors.each { |a| a.start() }
    end

    def self.wait_finish()
      @@finish_thread = Thread.current
      @@actors.each { |a| a.wakeup() }
      while 0 < queue_count()
        sleep(0.2) # actors should wake up when queue is empty
      end
    end

    def self.wake_finish()
      @@finish_thread.wakeup() unless @@finish_thread.nil?
    end

    def self.wait_close()
      while 0 < queue_count()
        wait_finish()
        stop()
        break if 0 == queue_count()
        start()
      end
      @@log = nil
      until @@actors.empty?
        a = @@actors.pop()
        a.close()
      end
    end

  end # Env
end # Opee
