#!/usr/bin/env ruby -wW2
# encoding: UTF-8

if __FILE__ == $0
  # TBD temporary, remove when testing is complete
  [ File.dirname(__FILE__),
    File.join(File.dirname(__FILE__), "../../lib")
  ].each { |path| $: << path unless $:.include?(path) }

  while (ix = ARGV.index('-I'))
    x,path = ARGV.slice!(ix, 2)
    $: << path
  end
end

require 'optparse'
require 'opee'
require 'reader'
require 'calculator'
require 'summary'

$verbose = Logger::WARN
$dir = '.'

opts = OptionParser.new
opts.on("-v", "increase verbosity")                            { $verbose -= 1 unless 0 == $verbose }
opts.on("-h", "--help", "Show this display")                   { puts opts; Process.exit!(0) }
dirs = opts.parse(ARGV)

if 1 != dirs.size
  puts opts
  Process.exit!(0)
end

::Opee::Env.logger.formatter = proc { |s,t,p,m|
  ss = 'DIWEF'[s]
  "#{ss} [#{t.strftime('%Y-%m-%dT%H:%M:%S.%6N')} ##{p}]: #{m}\n"
}
::Opee::Env.logger.severity = $verbose

dir_wq = ::Opee::WorkQueue.new(:method => :read, :name => 'DirWorkQueue')
calc_wq = ::Opee::WorkQueue.new(:method => :calc, :name => 'CalcWorkQueue')
summary = Density::Summary.new(:name => 'Summary')
readers = []
2.times { |i|
  readers << Density::Reader.new(:dir_queue => dir_wq,
                                 :calc_queue => calc_wq,
                                 :name => 'Reader-' + i.to_s)
}
calculators = []
4.times { |i|
  calculators << Density::Calculator.new(:calc_queue => calc_wq,
                                         :summary => summary,
                                         :name => 'Calculator-' + i.to_s)
}

dir_wq.ask(:add, File.expand_path(dirs[0]))

::Opee::Env.wait_close()

if Logger::INFO >= $verbose
  puts
  summary.details()
end
puts "Average density: #{(summary.average * 100).to_i}%"
