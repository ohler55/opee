#!/usr/bin/env ruby -wW2
# encoding: UTF-8

[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), "../lib")
].each { |path| $: << path unless $:.include?(path) }

require 'test/unit'
require 'opee'

class OpeeTest < ::Test::Unit::TestCase

  def test_opee_log_log
    #::Opee::Env.logger.ask(:severity=, Logger::INFO)
    ::Opee::Env.logger.severity= Logger::INFO
    ::Opee::Env.log(Logger::INFO, "hello")
    ::Opee::Env.each_actor { |a| puts a.to_s }
    sleep(0.2)
  end

end # OpeeTest
