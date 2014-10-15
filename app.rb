require 'sinatra/base'
require 'json'
require 'redis'
require 'active_support'
require 'active_support/all'

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

  get '/_streams/:channel' do
    content_type :stream

    stream do |out|
      begin
        sse = StreamsApp::SSE.new(out, event: 'event')

        redis.subscribe(params[:channel]) do |on|
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
