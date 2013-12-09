#!/usr/bin/env ruby
# encoding: UTF-8

# Ubuntu does not accept arguments to ruby when called using env. To get warnings to show up the -w options is
# required. That can be set in the RUBYOPT environment variable.
# export RUBYOPT=-w

$VERBOSE = true

require 'socket'

module ODisk
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
            # TBD keep track of telnet mode
            char_mode = false
            buf = ""
            while line = con.recv(100)
              break if 0 == line.size()
              c = line[-1]
              o = c.ord()
              puts "[#{o}] #{line.size()}"
              
              buf += line
              case o
              when 4
                break
              when 63 # ?
                if 1 == buf.size()
                  help(con)
                else
                  help(con)
                  # options
                end
              when 9 # tab
                # completions
              when 0 # client in single character mode
                # execute and reset buf
                char_mode = true
                con.puts("\r")
                break if exe_cmd(con, buf.chop().strip())
                buf = ""
              when 10, 13 # end of line \r or \n
                # execute and reset buf
                cmd = buf.chop().strip()
                break if exe_cmd(con, cmd)
                buf = ""
              end
              # build command
              # if ? then offer completion options
              puts "buf: #{buf}"
            end
            con.close
          end
        end
      end # Thread
    end
    
    def help(con)
      con.puts("you are on your own for now")
    end

    def exe_cmd(con, cmd)
      return if 0 == cmd.size()
      if "bye" == cmd
        return true
      end
      if "exit" == cmd
        puts "Exiting"
        @acceptThread.exit()
        return true
      end
      con.puts("Command #{cmd} not implemented yet\r")
      false
    end

  end # SocketInspector
end # ODisk


inspector = ODisk::SocketInspector.new(5959)
inspector.acceptThread.join()
