#!/usr/bin/env ruby -wW2
# encoding: UTF-8

[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), "../lib")
].each { |path| $: << path unless $:.include?(path) }

require 'test/unit'
require 'stringio'
require 'opee'

class Worker < ::Opee::Actor

  def initialize(options={})
    @collector = nil
    @work_queue = nil
    super(options)
    @work_queue.ask(:ready, self)
  end
  
  def set_options(options)
    super(options)
    @collector = options[:collector]
    @work_queue = options[:work_queue]
  end

  private

  def do_it(num)
    @collector.ask(:accept, num * 2)
    @work_queue.ask(:ready, self)
  end
  
  def how_busy(num)
    @collector.ask(:accept, @work_queue.work_queue_size())
    sleep(0.1)
    @work_queue.ask(:ready, self)
  end
  
end # Worker

class Collector < ::Opee::Actor
  attr_reader :results

  def initialize(options={})
    @results = []
    super(options)
  end

  private

  def accept(num)
    @results << num
  end
  
end # Collector

class OpeeTest < ::Test::Unit::TestCase

  def test_opee_workqueue_basic
    col = Collector.new()
    wq = ::Opee::WorkQueue.new(:method => :do_it,
                               :max_job_count => 10,
                               :job_timeout => 1.0)
    4.times { |i| Worker.new(:collector => col, :work_queue => wq) }
    10.times { |i| wq.ask(:add, i) }
    ::Opee::Env.wait_close()
    assert_equal([0, 2, 4, 6, 8, 10, 12, 14, 16, 18], col.results.sort())
  end

  def test_opee_workqueue_busy
    col = Collector.new()
    wq = ::Opee::WorkQueue.new(:method => :how_busy,
                               :max_job_count => 4,
                               :job_timeout => 1.0)
    2.times { |i| Worker.new(:collector => col, :work_queue => wq) }
    20.times { |i| wq.ask(:add, i) }
    ::Opee::Env.wait_close()
    assert(4 >= col.results.max)
  end

end # OpeeTest
