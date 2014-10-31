require 'sinatra/base'
require 'json'
require 'redis'
require 'active_support'
require 'active_support/all'
require 'securerandom'

require 'streams_app/sse'

class App < Sinatra::Base
  configure do
    mime_type :stream, 'text/event-stream'
  end

  helpers do
    def redis
      @redis ||= Redis.new
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
            data = JSON.parse(msg)
            sse << data
          end
        end
      ensure
        sse.close
      end
    end
  end
end
