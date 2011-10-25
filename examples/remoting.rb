$: << File.expand_path('../../lib', __FILE__)

require 'mikka'


if ARGV.first == '1'
  ping_actor = Mikka.actor do |message|
    puts message
  end

  server = Mikka::Remote.start(:port => 1337)
  server.register('ping', ping_actor)
else
  ping_actor = Mikka::Remote.actor_for('ping', :port => 1337)
  ping_actor << 'hello'
end