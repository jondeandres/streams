require 'sinatra/base'
require 'json'
require 'redis'
require 'active_support'
require 'active_support/all'
require 'securerandom'
require 'geokit'

require 'streams_app/sse'

class App < Sinatra::Base
  configure do
    mime_type :stream, 'text/event-stream'
  end

  helpers do
    def redis_options
      {
        host: ENV['REDIS_PORT_6379_TCP_ADDR'],
        port: ENV['REDIS_PORT_6379_TCP_PORT'],
        password: ENV['REDIS_PASSWORD']
      }
    end

    def redis
      @redis ||= Redis.new(redis_options)
    end
  end

  set :public_folder, -> { File.join(root, 'public') }

  get '/' do
    erb :index
  end

  post '/_streams' do
    path = SecureRandom.hex(40)
    channels = Array(params[:channels])

    redis.sadd("path:#{path}", channels)

    { path: path }.to_json
  end

  get '/_streams/:path' do
    content_type :stream
    channels = redis.smembers("path:#{params[:path]}")

    stream do |out|
      begin
        sse = StreamsApp::SSE.new(out, event: 'event')

        redis.subscribe(channels) do |on|
          on.message do |_, msg|
            begin
              parsed_msg = JSON.parse(msg)
              geo_data = Geokit::Geocoders::MultiGeocoder.geocode(parsed_msg['ip'])
              data = {
                point: {
                  lat: geo_data.lng,
                  lng: geo_data.lat
                }
              }

              sse << data
            rescue => e
              $stdout.write("#{e}\n")
            end
          end
        end
      ensure
        sse.close
      end
    end
  end
end
