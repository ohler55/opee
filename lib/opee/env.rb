
# Opee is an experimental Object-based Parallel Evaluation Environment
#
# The purpose of OPEE is to explore setting up an environment that will run
# completely in parallel with minimum use of mutex synchronization. Actors
# only push the flow forward, never returning values when using the ask()
# method. Other methods return immediately but they should never modify the
# data portions of the Actors. They can be used to modify the control
# parameters of the Actor.
module Opee
  # The Env class hold all the global data for Opee. The global data could
  # have been put directly under the Opee module but it seemed cleaner to keep
  # it all together in an separate class.
  class Env
    # Array of active Actors. This is private and should not be modified
    # directly.
    @@actors = []
    # global logger. This is private and should not be modified directly.
    @@log = nil
    # used to wakup calling thread when ready. This is private and should not
    # be modified directly.
    @@finish_thread = nil
    # Actor that responds to rescue if set. This is private and should not be
    # modified directly. Use the rescuer() or rescuer=() methods instead.
    @@rescuer = nil

    # Adds an Actor to the Env. This is called by the {Actor#initialize}() method.
    # @param [Actor] actor actor to add
    def self.add_actor(actor)
      @@actors << actor
    end

    # Removes an Actor from the Env. This is called by the {Actor#close}() method.
    # @param [Actor] actor actor to remove
    def self.remove_actor(actor)
      @@actors.delete(actor)
    end

    # Iterates over each active Actor and yields to the provided block with
    # each Actor.
    # @param [Proc] blk Proc to call on each iteration
    def self.each_actor(&blk)
      @@actors.each { |a| blk.yield(a) }
    end

    # Locates and return an Actor with the specified name. If there is more
    # than one Actor with the name specified then the first one encountered is
    # returned.
    # @param [String] name name of the Actor
    # @return [Actor|NilClass] the Actor with the name specified or nil
    def self.find_actor(name)
      @@actors.each { |a| return a if name == a.name }
      nil
    end

    # Returns the number of active Actors.
    def self.actor_count()
      @@actors.size
    end

    # Closes all Actors and resets the logger to nil.
    def self.shutdown()
      until @@actors.empty?
        a = @@actors.pop()
        begin
          a.close()
        rescue Exception => e
          puts "*** shutdown error #{e.class}: #{e.message}"
        end
      end
      @@log = nil
    end

    # Asks the logger to log the message if the severity is high enough.
    # @param [Fixnum] severity one of the Logger levels
    # @param [String] message string to log
    def self.log(severity, message)
      @@log = Log.new() if @@log.nil?
      t = Thread.current
      if (name = t[:name]).nil?
        tid = "%d/0x%014x" % [Process.pid, Thread.current.object_id * 2]
      else
        tid = "#{Process.pid}/#{name}"
      end
      @@log.ask(:log, severity, message, tid)
    end

    # Asks the logger to log a message if the current severity level is less
    # than or equal to Logger::DEBUG.
    # @param [String] message string to log
    def self.debug(message)
      log(Logger::Severity::DEBUG, message)
    end

    # Asks the logger to log a message if the current severity level is less
    # than or equal to Logger::INFO.
    # @param [String] message string to log
    def self.info(message)
      log(Logger::Severity::INFO, message)
    end

    # Asks the logger to log a message if the current severity level is less
    # than or equal to Logger::WARN.
    # @param [String] message string to log
    def self.warn(message)
      log(Logger::Severity::WARN, message)
    end

    # Asks the logger to log a message if the current severity level is less
    # than or equal to Logger::ERROR.
    # @param [String] message string to log
    def self.error(message)
      log(Logger::Severity::ERROR, message)
    end

    # Asks the logger to log a message if the current severity level is less
    # than or equal to Logger::FATAL.
    # @param [String] message string to log
    def self.fatal(message)
      log(Logger::Severity::FATAL, message)
    end

    # The log_rescue() method is called and then If a rescuer is set then it's
    # rescue() method is called.
    # @param [Exception] ex Exception to handle
    def self.rescue(ex)
      begin
        log_rescue(ex)
        @@rescuer.rescue(ex) unless @@rescuer.nil?
      rescue Exception => e
        puts "*** #{e.class}: #{e.message}"
        e.backtrace.each { |line| puts "   " + line }
      end
    end

    # Asks the logger to log a Exception class and message if the current
    # severity level is less than or equal to Logger::ERROR. If the current
    # severity is less than or equal to Logger::WARN then the Exception
    # bactrace is also logged.
    # @param [Exception] ex Exception to log
    def self.log_rescue(ex)
      @@log = Log.new() if @@log.nil?
      return unless Logger::Severity::ERROR >= @@log.level
      msg = "#{ex.class}: #{ex.message}"
      if Logger::Severity::WARN >= @@log.level
        ex.backtrace.each { |line| msg << "    #{line}\n" }
      end
      log(Logger::Severity::ERROR, msg)
    end

    # Returns the current Log Actor. If the current logger is nil then a new
    # Log Actor is created and returned.
    # @return [Log] the current logger
    def self.logger()
      @@log = Log.new() if @@log.nil?
      @@log
    end

    # Sets the logger to the provided Log Actor. If the current logger is not
    # nil then the current logger is closed first.
    # @param [Log] log_actor Log Actor to use as the logger
    # @raise [TypeError] raised if the log_actor is not a Log Actor
    def self.logger=(log_actor)
      raise TypeError.new("can't convert #{log_actor.class} into a Opee::Log") unless log_actor.is_a?(Log)
      @@log.close() unless @@log.nil?
      @@log = log_actor
      @@log
    end

    # Returns the current rescuer Actor. The rescuer us the Actor that is
    # sent an Exception if an Exception is raised by an Actor.
    # @return [Actor] the current rescuer
    def self.rescuer()
      @@rescuer
    end

    # Sets the rescuer to the provided Actor.
    # @param [Actor] actor Actor to use as the rescuer and responds to :rescue
    def self.rescuer=(actor)
      @@rescuer = actor
    end

    # Returns the sum of all the requests in all the Actor's queues.
    # @return [Fixnum] total number of items waiting to be processed
    def self.queue_count()
      cnt = 0
      @@actors.each { |a| cnt += a.queue_count() }
      cnt
    end

    # Returns true of one or more Actors is either processing a request or has
    # a request waiting to be processed on it's input queue.
    # @return [true|false] the busy state across all Actors
    def self.busy?
      @@actors.each { |a| return true if a.busy? }
      false
    end

    # Calls the stop() method on all Actors.
    def self.stop()
      @@actors.each { |a| a.stop() }
    end

    # Calls the start() method on all Actors.
    def self.start()
      @@finish_thread = nil
      @@actors.each { |a| a.start() }
    end

    # Waits for all Actors to complete processing. The method only returns
    # when all Actors indicate they are no longer busy.
    def self.wait_finish()
      next_time = Time.now + 5.0
      @@finish_thread = Thread.current
      @@actors.each { |a| a.wakeup() }
      while busy?
        sleep(0.2) # actors should wake up when queue is empty
        if !@@log.nil? && Logger::DEBUG >= @@log.severity
          now = Time.now
          if next_time <= now
            log_status()
            next_time = now + 5.0
          end
        end
      end
    end

    # Wakes up the calling thread when an Actor is finished. It is called by
    # the Actor and should not be called by any other code.
    def self.wake_finish()
      unless @@finish_thread.nil?
        # if thread has already exited the an exception will be raised. Ignore it.
        begin
          @@finish_thread.wakeup() 
        rescue
        end
      end
    end

    # Waits until all Actors are no longer busy and then closes all Actors.
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

    def self.log_status()
      s = "\n  %20s  %5s  %5s\n" % ['Actor Name', 'Q-cnt', 'busy?']
      @@actors.each { |a| s << "  %20s  %5d  %5s\n" % [a.name, a.queue_count(), a.busy?()] }
      info(s)
    end

  end # Env
end # Opee
