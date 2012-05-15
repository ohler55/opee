
module Density
  class Summary < ::Opee::Actor

    def initialize(options={})
      super(options)
      @data = {}
    end
    
    def set_options(options)
      super(options)
    end

    def average()
      sum = 0.0
      cnt = 0
      @data.each { |path,density|
        cnt += 1
        sum += density
      }
      sum / cnt
    end

    def details()
      puts " density  file"
      @data.each { |path,density|
        puts "    %2d%%   %s" % [(density * 100).to_i, path]
      }
    end

    private

    def summarize(path, density)
      ::Opee::Env.debug("Summary.summarize(#{path}, #{(density * 100).to_f})")
      @data[path] = density
    end

  end # Summary
end # Density
