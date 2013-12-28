
require 'date'
require File.join(File.dirname(__FILE__), 'lib/opee/version')

Gem::Specification.new do |s|
  s.name = "opee"
  s.version = ::Opee::VERSION
  s.authors = "Peter Ohler"
  s.date = Date.today.to_s
  s.email = "peter@ohler.com"
  s.homepage = "http://www.ohler.com/opee"
  s.summary = "An experimental Object-base Parallel Evaluation Environment."
  s.description = %{An experimental Object-base Parallel Evaluation Environment. }

  s.files = Dir["{lib,test}/**/*.rb"] + ['LICENSE', 'README.md']

  s.require_paths = ["lib"]

  s.has_rdoc = true
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options = ['--main', 'README.md']
  
  s.rubyforge_project = 'opee'

  s.add_runtime_dependency 'oterm'

end
