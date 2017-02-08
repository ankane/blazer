module Blazer
  module Adapters
    class DrillAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        header = {"Content-Type" => "application/json", "Accept" => "application/json"}
        data = {
          queryType: "sql",
          query: statement
        }

        uri = URI.parse("#{settings["url"]}/query.json")
        http = Net::HTTP.new(uri.host, uri.port)

        begin
          response = JSON.parse(http.post(uri.request_uri, data.to_json, header).body)
          if response["errorMessage"]
            error = response["errorMessage"]
          else
            columns = response["columns"]
            rows = response["rows"].map { |r| r.values }
          end
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end
    end
  end
end
