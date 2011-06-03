# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'mikka'


worker1 = Mikka.actor { |msg| puts "Worker 1 working on #{msg}" }
worker2 = Mikka.actor { |msg| puts "Worker 2 working on #{msg}" }
balancer = Mikka.load_balancer(:actors => [worker1, worker2])

10.times do |i|
  balancer << "item #{i}"
end

balancer << Mikka::Messages.broadcast("a message to everyone")
balancer << Mikka::Messages.poison_pill

Mikka.registry.shutdown_all