# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'mikka'


class Stallone < Mikka::Actor
  def receive(message)
    context.exit if message == 'punch!'
  end
end

stallone = Mikka.actor_of(Stallone).start
stallone << 'punch!'