#!/usr/bin/env ruby -wW2
# encoding: UTF-8

[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), "../lib")
].each { |path| $: << path unless $:.include?(path) }

require 'test/unit'
require 'opee'
require 'relay'

class OpeeTest < ::Test::Unit::TestCase

  def test_wait_close
    a = ::Relay.new(nil)
    a.ask(:relay, 7)
    ::Opee::Env.wait_close()
    assert_equal(7, a.last_data)
    a.close()
  end

end # OpeeTest
