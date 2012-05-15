
module Density
  class Reader < ::Opee::Actor

    def initialize(options={})
      super(options)
      @dir_queue.ask(:ready, self)
    end
    
    def set_options(options)
      super(options)
      @dir_queue = options[:dir_queue]
      @calc_queue = options[:calc_queue]
    end

    private

    def read(path)
      ::Opee::Env.debug("Reader.read(#{path})")
      raise "#{path} is not a directory" unless File.directory?(path)
      Dir.foreach(path) do |filename|
        next if filename.start_with?('.')
        child_path = File.join(path, filename)
        if File.directory?(child_path)
          @dir_queue.ask(:add, child_path)
        else
          @calc_queue.ask(:add, child_path)
        end
      end
      @dir_queue.ask(:ready, self)
    end
    
  end # Reader
end # Density
