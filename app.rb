require 'sinatra/base'
require 'json'
require 'redis'
require 'active_support'
require 'active_support/all'


class StreamsApp < Sinatra::Base
  class SSE
    WHITELISTED_OPTIONS = %w( retry event id )

    def initialize(stream, options = {})
      @stream = stream
      @options = options
    end

    def close
      @stream.close
    end

    def <<(object, options = {})
      case object
      when String
        perform_write(object, options)
      else
        perform_write(JSON.dump(object), options)
      end
    end

    private

    def perform_write(json, options)
      current_options = @options.merge(options).stringify_keys

      WHITELISTED_OPTIONS.each do |option_name|
        if (option_value = current_options[option_name])
          @stream << "#{option_name}: #{option_value}\n"
        end
      end

      @stream << "data: #{json}\n\n"
    end
  end

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
        sse = SSE.new(out, event: 'event')

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
