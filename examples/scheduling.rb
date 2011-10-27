# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'bundler/setup'
require 'mikka'

echo = Mikka.actor do |message|
  puts message
end
echo.start
echo << 'The echo actor just writes the messages it receives to STDOUT'

Mikka.schedule(echo, 'This message will be repeated every second', 1, 1, Mikka::TimeUnit::SECOND)

Mikka.schedule_once(echo, 'This message should only appear once after five seconds', 5, Mikka::TimeUnit::SECONDS)

Mikka.schedule_once(echo, 'Getting bored yet? Quit by pressing CTRL+C', 1, Mikka::TimeUnit::MINUTES)