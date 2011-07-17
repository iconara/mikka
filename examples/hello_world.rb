# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'mikka'


class Introduction < Struct.new(:actor); end
class Greeting < Struct.new(:body); end


phil = Mikka.actor do |msg|
  case msg
  when Introduction
    msg.actor << Greeting.new('Hello, dear sir.')
    context.exit
  end
end

sam = Mikka.actor do |msg| 
  case msg
  when Greeting
    puts "Received greeting: #{msg.body}"
    context.exit
  end
end

phil.start
sam.start

phil << Introduction.new(sam)
