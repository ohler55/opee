
require 'socket'

module Opee
  # Creates a Digest Object for specified directories and passes on the result
  # to a Opee::Collector.
  class SocketInspector
    attr_accessor :acceptThread
    attr_accessor :buf
    

    def initialize(port)
      @acceptThread = Thread.start() do
        server = TCPServer.new port
        loop do
          Thread.start(server.accept()) do |con|
            buf = ""
            con.puts("Welcome to the Inspector\r")
            con.print("\xff\xfd\x03\xff\xfd\x01") # ask to be character at a time mode
            con.print("> ")
            while line = con.recv(100)
              len = line.size()
              break if 0 == len

              line.each_byte { |x| print("#{x} ") }
              puts "[#{line.size()}]"

              # determine input type (telnet command, char mode, line mode)
              o1 = line[0].ord()
              if 255 == o1
                handle_telnet_command(con, line)
                next
              end
              if 1 == len || (2 == len && "\000" == line[1]) # single char mode
                # TBD use case here instead
                case o1
                when 4
                  break
                when 16 # ^p
                  # TBD up history stack
                  buf = ""
                when 63 # ?
                  help(con, buf)
                  con.print("> ")
                when 8, 127 # backspace or delete
                  buf.chop!()
                  con.putc(8)
                  con.putc(" ")
                  con.putc(8)
                when 9 # tab
                  # completions
                when 13 # line termination
                  cmd = buf.strip()
                  buf = ""
                  con.puts("\r")
                  break if exe_cmd(con, cmd)
                  con.print("> ")
                else
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
      op = OPS[key]
      if nil != op
        return send(op.fun, con, arg_str)
      else
        con.puts("Command #{cmd} not implemented yet\r")
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
      Opee::Env.stop()
      con.puts("All Actors stopped(paused).\r")
      false
    end

    def start(con, line)
      Opee::Env.start()
      con.puts("All Actors restarted.\r")
      false
    end

    # TBD status (of all queues)
    # TBD actor_show

    class Op
      attr_accessor :op
      attr_accessor :fun
      attr_accessor :args
      attr_accessor :short_help
      attr_accessor :long_help

      def initialize(op, fun, args, short_help, long_help)
        @op = op
        @args = args
        @fun = fun
        @short_help = short_help
        @long_help = long_help
      end
    end # Op

    OPS = {
      "help" => Op.new("help", :bye, "[<command>]", "Help on command or all commands", nil),
      "bye" => Op.new("bye", :bye, nil, "closes the connection", nil),
      "shutdown" => Op.new("shutdown", :shutdown, nil, "shuts down the application", nil),
      "actor_count" => Op.new("actor_count", :actor_count, nil, "returns number of active Actors", nil),
      "queue_count" => Op.new("queue_count", :queue_count, nil, "returns number of queued requests", nil),
      "busy" => Op.new("busy", :busy, nil, "returns the busy state of the system", nil),
      "stop" => Op.new("stop", :stop, nil, "stops all processing", nil),
      "start" => Op.new("start", :start, nil, "re-starts processing", nil),
    }


  end # SocketInspector
end # Opee
