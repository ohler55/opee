
require 'socket'

module Opee
  # Creates a Digest Object for specified directories and passes on the result
  # to a Opee::Collector.
  class SocketInspector
    attr_accessor :acceptThread
    attr_accessor :buf
    

    def initialize(port)
      @history = [] # shared across connections
      @acceptThread = Thread.start() do
        server = TCPServer.new port
        loop do
          # TBD make this a separate console handler class with registered functions and target object.
          Thread.start(server.accept()) do |con|
            buf = ""
            hi = 0 # history pointer
            con.puts("Welcome to the Inspector\r")
            con.print("\xff\xfd\x03\xff\xfd\x01") # ask to be character at a time mode
            con.print("> ")
            while line = con.recv(100)
              len = line.size()
              break if 0 == len

              #line.each_byte { |x| print("#{x} ") }
              #puts "[#{line.size()}]"

              # determine input type (telnet command, char mode, line mode)
              o1 = line[0].ord()
              if 255 == o1
                handle_telnet_command(con, line)
                next
              end
              if 1 == len || (2 == len && "\000" == line[1]) # single char mode
                case o1
                when 0..3, 5..7, 11, 12, 15, 17..31
                  # ignore
                when 4
                  break
                when 14 # ^n
                  if 0 < hi && hi <= @history.size()
                    hi -= 1
                    blen = buf.size()
                    if 0 == hi
                      buf = ""
                    else
                      buf = @history[-hi]
                    end
                    con.print("\r> " + buf)
                    # erase to end of line and come back
                    if buf.size() < blen
                      dif = blen - buf.size()
                      con.print(' ' * dif + "\b" * dif)
                    end
                  end
                when 16 # ^p
                  if hi < @history.size()
                    hi += 1
                    blen = buf.size()
                    buf = @history[-hi]
                    con.print("\r> " + buf)
                    # erase to end of line and come back
                    if buf.size() < blen
                      dif = blen - buf.size()
                      con.print(' ' * dif + "\b" * dif)
                    end
                  end
                when 63 # ?
                  hi = 0
                  help(con, buf)
                  con.print("> ")
                when 8, 127 # backspace or delete
                  hi = 0
                  if 0 < buf.size()
                    buf.chop!()
                    con.putc(8)
                    con.putc(" ")
                    con.putc(8)
                  end
                when 9 # tab
                  hi = 0
                  # completions
                when 13 # line termination
                  hi = 0
                  cmd = buf.strip()
                  buf = ""
                  con.puts("\r")
                  @history << cmd if 0 < cmd.size() && (0 == @history.size() || @history[-1] != cmd)
                  break if exe_cmd(con, cmd)
                  con.print("> ")
                else
                  hi = 0
                  con.putc(line[0])
                  buf << line[0]
                end
              else # line mode
                buf << line
                if 2 <= buf.size() && 13 == buf[-2].ord && 10 == buf[-1].ord
                  cmd = buf.strip()
                  buf = ""
                  break if exe_cmd(con, cmd)
                  con.print("> ")
                end
              end
            end
            con.close
          end
        end
      end # Thread
    end
    
    def handle_telnet_command(con, line)
      # TBD be smarter and really handle correctly
      con.print("\xff\xfb\x03\xff\xfb\x01") # ask to be character at a time mode
    end

    def help(con, line)
      con.puts("Commands:\r")
      OPS.each do |key,op|
        if nil == op.args
          con.puts("  #{op.op} - #{op.short_help}\r")
        else
          con.puts("  #{op.op} #{op.args} - #{op.short_help}\r")
        end
      end
    end

    def exe_cmd(con, cmd)
      return if 0 == cmd.size()
      key, arg_str = cmd.split(" ", 2)
      key.downcase!()
      begin
        op = find_op(key)
        if nil != op
          return send(op.fun, con, arg_str)
        else
          con.puts("Command #{cmd} not implemented yet\r")
        end
      rescue Exception => e
        puts "*** #{e.class}: #{e.message}"
      end
      false
    end

    def bye(con, line)
      true
    end

    def shutdown(con, line)
      puts "Shutting down"
      @acceptThread.exit()
      Env.shutdown()
      true
    end

    def actor_count(con, line)
      con.puts("There are currently #{Opee::Env.actor_count()} active Actors.\r")
      false
    end

    def queue_count(con, line)
      con.puts("There are currently #{Opee::Env.queue_count()} unprocessed requests queued.\r")
      false
    end

    def busy(con, line)
      if Opee::Env.busy?()
        con.puts("One or more actors is busy.\r")
      else
        con.puts("All actors are idle.\r")
      end
      false
    end

    def stop(con, line)
      if nil == line || 0 == line.size()
        ::Opee::Env.stop()
        con.puts("All Actors stopped(paused)\r")
      else
        a = ::Opee::Env.find_actor(line)
        if nil == a
          con.puts("--- Failed to find '#{line}'\r")
        else
          a.stop()
          con.puts("#{a.name} stopped(paused)\r")
        end
      end
      false
    end

    def start(con, line)
      if nil == line || 0 == line.size()
        ::Opee::Env.start()
        con.puts("All Actors restarted\r")
      else
        a = ::Opee::Env.find_actor(line)
        if nil == a
          con.puts("--- Failed to find '#{line}'\r")
        else
          a.start()
          con.puts("#{a.name} started\r")
        end
      end
      false
    end

    def step(con, line)
      la = ::Opee::Env.logger()
      stop_after = false
      if ::Opee::Actor::STOPPED == la.state
        la.start()
        stop_after = true
      end
      if nil == line || 0 == line.size()
        ::Opee::Env.each_actor() do |a|
          if ::Opee::Actor::STOPPED == la.state && 0 < a.queue_count()
            a.step()
            con.puts("#{a.name} stepped\r")
            break
          end
        end
      else
        a = ::Opee::Env.find_actor(line)
        if nil == a
          con.puts("--- Failed to find '#{line}'\r")
        else
          a.step()
          con.puts("#{a.name} stepped\r")
        end
      end
      la.stop() if stop_after
      false
    end

    def status(con, line)
      con.puts("  %20s  %-11s  %5s  %5s\r" % ['Actor Name', 'Q-cnt/max', 'busy?', 'processed'])
      ::Opee::Env.each_actor() { |a| con.puts("  %20s  %5d/%-5d  %5s  %5d\r" % [a.name, a.queue_count(), a.max_queue_count().to_i, a.busy?(), a.proc_count()]) }
      false
    end

    def verbosity(con, line)
      v = ::Opee::Env.logger.severity
      if nil != line && 0 < line.size()
        begin
          v = ::Opee::Env.logger.severity = line
        rescue Exception
          con.puts("'#{line}' is not a value verbosity\r")
        end
      end
      con.puts("verbosity: #{v}\r")
      false
    end

    def history(con, line)
      cnt = 1
      @history.each { |h| con.puts(" %3d  %s\r" % [cnt, h]); cnt += 1 }
      false
    end

    def show(con, line)
      a = ::Opee::Env.find_actor(line)
      if nil == a
        con.puts("--- Failed to find '#{line}'\r")
      else
        con.puts("#{a.name} {\r")
        con.puts("  state:           #{a.state_string()}\r")
        con.puts("  busy?:           #{a.busy?()}\r")
        con.puts("  queued count:    #{a.queue_count()}\r")
        con.puts("  max queue count: #{a.max_queue_count()}\r")
        con.puts("  ask timeout:     #{a.ask_timeout()}\r")
        con.puts("}\r")
      end
    end

    class Op
      attr_accessor :op
      attr_accessor :nickname
      attr_accessor :fun
      attr_accessor :args
      attr_accessor :short_help
      attr_accessor :long_help

      def initialize(op, nick, fun, args, short_help, long_help)
        @op = op
        @nickname = nick
        @args = args
        @fun = fun
        @short_help = short_help
        @long_help = long_help
      end
    end # Op

    def find_op(key)
      op = OPS[key]
      if nil == op
        OPS.each do |k,o|
          if o.nickname == key
            op = o
            break
          end
        end
        OPS[key] = op if nil != op
      end
      op
    end

    OPS = {
      "actor_count" => Op.new("actor_count", "ac", :actor_count, nil, "returns number of active Actors", nil),
      "busy" => Op.new("busy", "busy", :busy, nil, "returns the busy state of the system", nil),
      "bye" => Op.new("bye", "bye", :bye, nil, "closes the connection", nil),
      "help" => Op.new("help", "h", :bye, "[<command>]", "Help on command or all commands", nil),
      "history" => Op.new("history", "hist", :history, nil, "show history of commands excuted", nil),
      "queue_count" => Op.new("queue_count", "qc", :queue_count, nil, "returns number of queued requests", nil),
      "show" => Op.new("show", "describe", :show, nil, "shows the details of an actor", nil),
      "shutdown" => Op.new("shutdown", "shutdown", :shutdown, nil, "shuts down the application", nil),
      "start" => Op.new("start", "restart", :start, "[<actor name>]", "re-starts processing", nil),
      "status" => Op.new("status", "stat", :status, nil, "displays the status of each actor", nil),
      "step" => Op.new("step", "next", :step, nil, "steps once", nil),
      "stop" => Op.new("stop", "pause", :stop, "[<actor name>]", "stops processing", nil),
      "verbosity" => Op.new("verbosity", "v", :verbosity, "[<level>]", "show or set verbosity", nil),
    }

  end # SocketInspector
end # Opee
