require 'sinatra/base'
require 'json'
require 'redis'
require 'active_support'
require 'active_support/all'
require 'securerandom'
require 'maxminddb'

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

    def ip_db
      @ip_db ||= MaxMindDB.new('./GeoLite2-City.mmdb')
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
              ip = JSON.parse(msg)['ip']
              location = ip_db.lookup(ip).location

              if location
                data = {
                  point: {
                    lat: location.latitude,
                    lng: location.longitude
                  }
                }

                sse << data
              end
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
