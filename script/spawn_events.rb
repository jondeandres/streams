#!/usr/bin/env ruby

require 'redis'
require 'json'

redis = Redis.new

def spawn_events(redis)
  base_lat = 40.2085
  base_lng = -1.713

  100.times do
    sleep 1
    lat = base_lat + rand(-30..30).to_f / 10
    lng = base_lng + rand(-30..30).to_f / 10
    redis.publish('payments', JSON.dump({point: { lat: lat, lng: lng }}))
  end
end

spawn_events(redis)
