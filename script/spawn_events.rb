#!/usr/bin/env ruby

require 'redis'
require 'json'

redis = Redis.new

def spawn_events(redis)
  loop do
    sleep 0.2

    ip = 4.times.to_enum.map {|_| rand(256).to_s }.join('.')
    redis.publish('errors', JSON.dump(ip: ip))
  end
end

spawn_events(redis)
