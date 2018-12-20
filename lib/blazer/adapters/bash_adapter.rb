require 'open3'

module Blazer
  module Adapters
    class BashAdapter
      attr_reader :data_source

      def initialize(data_source)
        @data_source = data_source
        @env         = settings.fetch("env", {})
        @command     = settings.fetch("command", "python --")
      end

      def run_statement(statement, comment)
        out, err, status = ::Open3.capture3(@env, @command, stdin_data: statement)
        if status.success?
          results = JSON.parse(out)
          columns = results.first.keys.map(&:to_s) if results && results.size > 0
          rows = results.map(&:values) if results
        else
          columns = []
          rows = []
          errors = err
        end
        [columns, rows, errors]
      rescue JSON::ParserError => error
        [[], [], "Response error #{error.class}: #{error}"]
      end

      def tables
        [] # optional, but nice to have
      end

      def schema
        [] # optional, but nice to have
      end

      def preview_statement
        "print('[{\"hello\": \"goodbye\"}]')"
      end

      def reconnect
        # optional
      end

      def cost(statement)
        # optional
      end

      def explain(statement)
        # optional
      end

      def cancel(run_id)
        # optional
      end

      def cachable?(statement)
        true # optional
      end

      protected

      def settings
        @data_source.settings
      end
    end
  end
end
