#!/usr/bin/env ruby
# encoding: UTF-8

# Ubuntu does not accept arguments to ruby when called using env. To get warnings to show up the -w options is
# required. That can be set in the RUBYOPT environment variable.
# export RUBYOPT=-w

$VERBOSE = true

$: << File.join(File.dirname(__FILE__), "../lib")

$: << File.join(File.dirname(__FILE__), "../../oterm/lib")

require 'opee'


inspector = Opee::SocketInspector.new(6060)
inspector.join()
