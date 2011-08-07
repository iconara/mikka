# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'bundler/setup'
require 'mikka'


class Worker < Mikka::Actor
  def receive(message)
    puts "#{context.uuid} Work on #{message}"
  end
end

balancer = Mikka.load_balancer(:type => Worker, :count => 4)

10.times do |i|
  balancer << "item #{i}"
end

balancer << Mikka::Messages.broadcast("a message to everyone")

Mikka.registry.shutdown_all