module Fluent
  class TextParser
    class JSONTransformParser
      DEFAULTS = [ 'nothing', 'flatten' ]

      include Configurable
      config_param :transform_script, :string
      config_param :flattening_separator, :string, :default => '.'
      config_param :script_path, :string
      config_param :time_key, :string, :default => 'time'
      config_param :time_format, :string, :default => nil

      def configure(conf)
	@time_format = conf['time_format']
	@time_key = conf['time_key']
        @transform_script = conf['transform_script']
        @script_path = conf['script_path']
	@flattening_separator = conf['flattening_separator']

	
        unless @time_format.nil?
          @time_parser = TimeParser.new(@time_format)
          @mutex = Mutex.new
        end

        if DEFAULTS.include?(@transform_script)
          @transform_script = File.dirname(__FILE__)+"../../transform/#{@transform_script}.rb"
        elsif @transform_script == 'custom'
          @transform_script = @script_path
        end

        require @transform_script
        @transformer = JSONTransformer.new
      end

      def parse(text)
	raw_json = JSON.parse(text)
	record = @transformer.transform(raw_json, @flattening_separator)
        if value = record.delete(@time_key)
          if @time_format
            time = @mutex.synchronize { @time_parser.parse(value) }
          else
            time = value.to_i
          end
        else
          time = Engine.now
        end

        return time, record
      end

      def parse(text)
        raw_json = JSON.parse(text)
        return nil, @transformer.transform(raw_json)
      end
    end
  register_template("json_transform", Proc.new { JSONTransformParser.new })
  end
end

