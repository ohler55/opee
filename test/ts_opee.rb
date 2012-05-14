#!/usr/bin/env ruby -wW2
# encoding: UTF-8

[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), "../lib")
].each { |path| $: << path unless $:.include?(path) }

require 'test/unit'
require 'opee'

class OpeeTest < ::Test::Unit::TestCase
end # OpeeTest

require 'tc_opee_actor'
require 'tc_opee_log'
require 'tc_opee_env'
require 'tc_opee_workqueue'
require 'tc_opee_collector'
