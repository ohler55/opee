
require 'oterm'

module Opee

  class SocketInspector < ::OTerm::Executor

    def initialize(port=6060)
      super()
      register('actor_count', self, :actor_count, 'Returns the number of active Actors.', nil)
      register('actors', self, :actors, 'Displays a list of all Actor names.', nil)
      register('busy', self, :busy, 'Returns the busy state of the system.', nil)
      register('queued', self, :queued, 'Returns the total number of queued requests.', nil)
      register('show', self, :show, '<actor name> Shows the details of an Actor.',
               %|[<actor name>] Shows the details of an Actor. Attributes are:
    name        - identifies the Actor
    state       - state of the Actor [ STOPPED \| RUNNING \| STEP \| CLOSING ]
    busy        - true if the Actor has requested queued
    queued      - number of requested in the queue
    max queue   - maximum number of requested that can be queued
    ask timeout - seconds to wait before rejecting an ask
|)
      register('start', self, :start, '[<actor name>] Start or restart an Actor.', nil)
      register('status', self, :status, 'Displays status of all Actors.',
               %|Displays the Actor name and queued count. If the terminal supports real time
updates the displays stays active until the X character is pressed. While running
options are available for sorting on name, activity, or queue size.|)
      register('step', self, :step, '[<actor name>] Step once.',
               %|Step once for the actor specfified or once for some actor that is
waiting if not actor is identified.
|)
      register('stop', self, :stop, '[<actor name>] Stops an Actor.', nil)
      register('verbosity', self, :verbosity, '[<level>] Show or set the verbosity or log level.', nil)

      @server = ::OTerm::Server.new(self, port, false)
    end

    def join()
      @server.join()
    end

    def shutdown(listener, args)
      # TBD hangs sometimes and gets in an odd loop sometimes
      puts "*** shutdown"
      Env.shutdown()
      puts "*** Env shutdown completed"
      super
      puts "*** OTerm shutdown completed"
    end

    def greeting()
      "Welcome to the Inspector."
    end

    def tab(cmd, listener)
      # TBD depending on the command, try completion on second arg as Actor name
      super
    end

    def actor_count(listener, args)
      listener.out.pl("There are currently #{Opee::Env.actor_count()} active Actors.")
    end

    def actors(listener, args)
      max = 0
      ::Opee::Env.each_actor() do |a|
        max = a.name.size if max < a.name.size
      end
      ::Opee::Env.each_actor() do |a|
        listener.out.pl("  %1$*2$s: %3$s" % [a.name, -max, a.class.to_s])
      end
    end

    def queued(listener, args)
      listener.out.pl("There are currently #{Opee::Env.queue_count()} unprocessed requests queued.")
    end

    def busy(listener, args)
      if Opee::Env.busy?()
        listener.out.pl("One or more actors is busy.")
      else
        listener.out.pl("All actors are idle.")
      end
    end

    def stop(listener, args)
      if nil == args || 0 == args.size()
        ::Opee::Env.stop()
        listener.out.pl("All Actors stopped(paused)")
      else
        args.strip!
        a = ::Opee::Env.find_actor(args)
        if nil == a
          listener.out.pl("--- Failed to find '#{args}'")
        else
          a.stop()
          listener.out.pl("#{a.name} stopped(paused)")
        end
      end
    end

    def start(listener, args)
      if nil == args || 0 == args.size()
        ::Opee::Env.start()
        listener.out.pl("All Actors restarted")
      else
        args.strip!
        a = ::Opee::Env.find_actor(args)
        if nil == a
          listener.out.pl("--- Failed to find '#{args}'")
        else
          a.start()
          listener.out.pl("#{a.name} started")
        end
      end
    end

    def step(listener, args)
      la = ::Opee::Env.logger()
      stop_after = false
      if ::Opee::Actor::STOPPED == la.state
        la.start()
        stop_after = true
      end
      if nil == args || 0 == args.size()
        # TBD be smarter about picking an actor and try not to repeat
        ::Opee::Env.each_actor() do |a|
          if ::Opee::Actor::STOPPED == la.state && 0 < a.queue_count()
            a.step()
            listener.out.pl("#{a.name} stepped")
            break
          end
        end
      else
        a = ::Opee::Env.find_actor(args)
        if nil == a
          listener.out.pl("--- Failed to find '#{args}'")
        else
          a.step()
          listener.out.pl("#{a.name} stepped")
        end
      end
      la.stop() if stop_after
    end

    def verbosity(listener, args)
      v = ::Opee::Env.logger.severity
      if nil != args && 0 < args.size()
        args.strip!
        begin
          v = ::Opee::Env.logger.severity = args
        rescue Exception
          listener.out.pl("'#{line}' is not a value verbosity")
        end
      end
      listener.out.pl("verbosity: #{v}")
    end

    def show(listener, args)
      if nil == args
        listener.out.pl("--- No Actor specified")
        return
      end
      a = ::Opee::Env.find_actor(args)
      if nil == a
        listener.out.pl("--- Failed to find '#{args}'")
      else
        args.strip!
        listener.out.pl("#{a.name}:")
        listener.out.pl("  state:           #{a.state_string()}")
        listener.out.pl("  busy?:           #{a.busy?()}")
        listener.out.pl("  queued count:    #{a.queue_count()}")
        listener.out.pl("  max queue count: #{a.max_queue_count()}")
        listener.out.pl("  ask timeout:     #{a.ask_timeout()}")
      end
    end

    def status(listener, args)
      if listener.out.is_vt100?
        dynamic_status(listener)
      else
        listener.out.pl("  %20s  %-11s  %5s  %5s" % ['Actor Name', 'Q-cnt/max', 'busy?', 'processed'])
        ::Opee::Env.each_actor() do |a|
          listener.out.pl("  %20s  %5d/%-5d  %5s  %5d" % [a.name, a.queue_count(), a.max_queue_count().to_i, a.busy?(), a.proc_count()])
        end
      end
    end

    BY_NAME = 'n'
    BY_ACTIVITY = 'a'
    BY_QUEUE = 'q'

    def dynamic_status(listener)
      o = listener.out
      actors = [] # ActorStat
      sort_by = BY_NAME
      rev = false
      delay = 0.4
      max = 6
      ::Opee::Env.each_actor() do |a|
        actors << ActorStat.new(a)
        max = a.name.size if max < a.name.size
      end
      lines = actors.size + 2
      h, w = o.screen_size()
      lines = h - 2 if lines > h - 2
      o.clear_screen()
      max_q = w - max - 4
      done = false
      while !done
        actors.each { |as| as.refresh() }
        case sort_by
        when BY_NAME
          if rev
            actors.sort! { |a,b| b.name <=> a.name }
          else
            actors.sort! { |a,b| a.name <=> b.name }
          end
        when BY_ACTIVITY
          if rev
            actors.sort! { |a,b| a.activity <=> b.activity }
          else
            actors.sort! { |a,b| b.activity <=> a.activity }
          end
        when BY_QUEUE
          if rev
            actors.sort! { |a,b| a.queued <=> b.queued }
          else
            actors.sort! { |a,b| b.queued <=> a.queued }
          end
        end
        o.set_cursor(1, 1)
        o.bold()
        o.p("%1$*2$s @ Queued" % ['Actor', -max])
        o.attrs_off()
        i = 2
        actors[0..lines].each do |as|
          o.set_cursor(i, 1)
          o.p("%1$*2$s " % [as.name, -max])
          o.set_cursor(i, max + 2)
          case as.activity
          when 0
            o.p(' ')
          when 1
            o.p('.')
          when 2, 3
            o.p('o')
          else
            o.p('O')
          end
          o.p(' ')
          qlen = as.queued
          qlen = max_q if max_q < qlen
          if 0 < qlen
            o.reverse()
            o.p("%1$*2$d" % [as.queued, -qlen])
            o.attrs_off()
          end
          o.clear_to_end()
          i += 1
        end
        o.set_cursor(i, 1)
        o.bold()
        o.p('E) exit  N) by name  A) by activity  Q) by queued  R) reverse  ')
        o.graphic_font()
        o.p(::OTerm::VT100::PLUS_MINUS)
        o.default_font()
        o.p(") faster/slower [%0.1f]" % [delay])
        o.attrs_off()
        c = o.recv_wait(1, delay, /./)
        unless c.nil?
          case c[0]
          when 'e', 'E'
            done = true
          when 'n', 'N'
            sort_by = BY_NAME
            rev = false
          when 'a', 'A'
            sort_by = BY_ACTIVITY
            rev = false
          when 'q', 'Q'
            sort_by = BY_QUEUE
            rev = false
          when 'r', 'R'
            rev = !rev
          when 'f', 'F', '+'
            delay /= 2.0 unless delay <= 0.1
          when 's', 'S', '-'
            delay *= 2.0 unless 3.0 <= delay
          end
        end
      end
      o.pl()
    end

    class ActorStat
      attr_reader :actor
      attr_reader :queued
      attr_reader :activity

      def initialize(a)
        @actor = a
        @proc_cnt = a.proc_count()
        @activity = 0
        @queued = a.queue_count()
      end

      def refresh()
        cnt = @actor.proc_count()
        @activity = cnt - @proc_cnt
        @proc_cnt = cnt
        @queued = @actor.queue_count()
      end

      def name()
        @actor.name
      end

    end # ActorStat

  end # SocketInspector
end # Opee
