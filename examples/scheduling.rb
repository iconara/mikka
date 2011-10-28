# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'bundler/setup'
require 'mikka'

echo = Mikka.actor do |message|
  puts message
end
echo.start
echo << 'The echo actor just writes the messages it receives to STDOUT'

# Mikka::Scheduling.schedule(receiver_actor, message_to_be_sent, initial_delay_before_sending, delay_between_messages, time_unit)
# Note: time_unit defaults to Mikka::TimeUnit::SECONDS and can be ommitted. It's also possible to pass symbol values
# of :seconds, :minutes etc.
Mikka::Scheduling.schedule(echo, 'This message will be repeated every second after an initial delay of 2 seconds', 2, 1, :second)

# Mikka::Scheduling.schedule_once(receiver_actor, message_to_be_sent, delay_until_send, time_unit)
Mikka::Scheduling.schedule_once(echo, 'This message should only appear once after five seconds', 5, Mikka::TimeUnit::SECONDS)

Mikka::Scheduling.schedule_once(echo, 'Getting bored yet? Quit by pressing CTRL+C', 1, :minute)