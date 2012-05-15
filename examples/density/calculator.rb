
module Density
  class Calculator < ::Opee::Actor

    def initialize(options={})
      super(options)
      @calc_queue.ask(:ready, self)
    end
    
    def set_options(options)
      super(options)
      @calc_queue = options[:calc_queue]
      @summary = options[:summary]
    end

    private

    def calc(path)
      ::Opee::Env.debug("Calculator.calc(#{path})")
      raise "#{path} is not a file" unless File.file?(path)
      white = 0
      meat = 0
      bin = false
      File.open(path) do |f|
        f.each_byte do |b|
          if 32 >= b
            if [9, 10, 11, 12, 13, 32].include?(b) # white space
              white += 1
            else # binary
              bin = true
              break
            end
          else
            meat += 1
          end
        end
      end
      # Let method_missing() handle this one.
      @summary.summarize(path, meat.to_f / (meat + white)) unless bin
      # read for the next path if there is one
      @calc_queue.ask(:ready, self)
    end

  end # Calculator
end # Density
