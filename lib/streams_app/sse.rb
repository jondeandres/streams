module StreamsApp
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
end
