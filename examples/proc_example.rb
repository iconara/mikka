# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'mikka'


actor = Mikka.actor_of do |message|
  case message
  when 'hi'
    puts "hello yourself"
  when 'goodbye'
    puts "adieu"
    context.exit
  else
    puts "sorry, come again?"
  end
end

actor.start
actor << 'hi'
actor << 'hello'
actor << 'goodbye'