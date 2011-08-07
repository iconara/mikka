# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

require 'mikka/version'


Gem::Specification.new do |s|
  s.name        = 'mikka'
  s.version     = Mikka::VERSION
  s.platform    = Gem::Platform::CURRENT
  s.authors     = ['Theo Hultberg']
  s.email       = ['theo@iconara.net']
  s.homepage    = 'http://github.com/iconara/mikka'
  s.summary     = %q{Mikka is a JRuby wrapper for Akka}
  s.description = %q{Mikka adapts Akka's Java API to fit better with Ruby}

  s.rubyforge_project = 'mikka'
  
  s.add_dependency 'akka-actor-jars', '~> 1.1.0'

  s.files         = `git ls-files`.split("\n")
  # s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  # s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
end
