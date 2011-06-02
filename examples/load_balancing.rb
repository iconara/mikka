# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'mikka'


worker1 = Mikka.actor { |msg| puts "Worker 1 working on #{msg}" }
worker1.id = 'worker1'
worker2 = Mikka.actor { |msg| puts "Worker 2 working on #{msg}" }
worker2.id = 'worker2'
balancer = Mikka.actor_of { Mikka::LoadBalancer.new(worker1, worker2) }.start
balancer.id = 'balancer'

10.times do |i|
  balancer << "item #{i}"
end

balancer << Mikka::Messages.broadcast("a message to everyone")
balancer << Mikka::Messages.poison_pill

Mikka.registry.shutdown_all