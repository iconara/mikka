# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

require 'mikka/version'

Gem::Specification.new do |s|
  s.name        = 'mikka'
  s.version     = Mikka::VERSION
  s.platform    = 'java'
  s.authors     = ['Theo Hultberg', 'Daniel Gaiottino']
  s.email       = ['theo@iconara.net', 'daniel.gaiottino@gmail.com']
  s.homepage    = 'http://github.com/iconara/mikka'
  s.summary     = %q{Mikka is a JRuby wrapper for Akka}
  s.description = %q{Mikka adapts Akka's Java API to fit better with Ruby}

  s.rubyforge_project = 'mikka'
  
  s.add_dependency 'typesafe-config-jars', '~> 1.0.2'
  s.add_dependency 'akka-actor-jars', '~> 2.2.1'

  s.files         = `git ls-files`.split("\n")
  s.require_paths = %w(lib)
end
