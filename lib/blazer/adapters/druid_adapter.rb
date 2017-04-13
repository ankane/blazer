require 'net/http'
require 'json'
require 'set'

module Blazer
  module Adapters
    class DruidAdapter < BaseAdapter
      EXTENDED_OPERATORS = [:select, :order, :raw].freeze

      def initialize(data_source)
        @url = data_source.settings['url']
      end

      def run_statement(statement, _comment)
        parsed_statement = JSON.parse(statement).symbolize_keys
        postprocess_result(query_druid(preprocess_statement(parsed_statement)), parsed_statement)
      rescue => e
        [[], [], e.message]
      end

      def quote(x)
        x
      end

      private

      def query_druid(query)
        uri = URI("#{@url}/druid/v2/?pretty")
        req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
        req.body = query.except(*EXTENDED_OPERATORS).to_json
        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(req)
        end
        body = JSON.parse(res.body)
        raise "#{body['error']}: #{body['errorMessage']}" || 'Query failed' unless res.response.is_a?(Net::HTTPOK)
        body
      end

      def preprocess_statement(statement)
        if statement[:intervals]
          statement[:intervals] = statement[:intervals].map do |interval_string|
            date_interval(interval_string).map(&:iso8601).join('/')
          end
        end
        statement
      end

      def match_extended_date(str)
        /\s*(now|'(\d+\.?\d*)\s+(\w+)'|'(\d+\.?\d*)\s+(\w+)\s+(ago|from now|hence|later|away|out)')\s*/i.match(str)
      end

      def match_iso_date(str)
        str.is_a?(String) && /[0-9]+-[0-9]{1,2}-[0-9]{1,2}(T[0-9]{2}:[0-9]{2}:[0-9]{2}.*)?/.match(str)
      end

      def parse_extended_date(str)
        m = match_extended_date(str)
        raise "Not a valid date: #{str}" unless m
        if m[1] == 'now'
          Time.now
        elsif m[2]
          m[2].to_f.send(m[3].to_sym)
        elsif m[6] == 'ago'
          Time.now - m[4].to_f.send(m[5].to_sym)
        elsif /(from now|hence|later|away|out)/i.match(m[6])
          Time.now + m[4].to_f.send(m[5].to_sym)
        else
          raise "Not a valid date: #{str}"
        end
      end

      def parse_date(str)
        if match_iso_date(str)
          str.to_date
        else
          begin
            parse_extended_date("'" + str + "'")
          rescue RuntimeError
            parse_extended_date(str)
          end
        end
      end

      def combine_dates(dates, operators)
        operators = operators.reverse
        dates.reduce { |sum, date| sum.send(operators.pop, date) }
      end

      def parse_date_expr(str)
        if match_extended_date(str)
          dates = str.split(/[\+-]/)
          operators = str.scan(/[\+-]/)
          combine_dates(dates.map { |d| parse_date(d) }, operators.map(&:first).map(&:to_sym))
        else
          parse_date(str)
        end
      end

      def date_interval(str)
        from, to = str.split('/')
        raise 'Need two dates separated by `/`' unless from && to
        [parse_date_expr(from), parse_date_expr(to)].map { |d| d.in_time_zone('Zulu') }
      end

      def postprocess_result(raw_result, statement)
        if raw_result.length.zero?
          generic_result(nil)
        elsif statement[:raw]
          generic_result(raw_result)
        else
          result = flatten_result(raw_result, statement)
          result = select(result, statement[:select]) if statement[:select]
          result = order(result, statement[:order]) if statement[:order]
          result
        end
      end

      # Turn the Druid results into something Blazer likes (rows of values!)
      def flatten_result(result, statement)
        case statement[:queryType].to_sym
        when :topN, :timeseries, :timeBoundary, :search, :dataSourceMetadata
          fast_columnize(timestamp_data(result, 'result'))
        when :groupBy
          fast_columnize(timestamp_data(result, 'event'))
        when :select
          columnize(raw_data(result))
        else
          generic_result(result)
        end
      end

      # Separate column headers from rows, when all rows share the same keys
      def fast_columnize(result)
        [result.first.keys, result.map(&:values), nil]
      end

      # Separate column headers from rows, when rows may not share the same keys
      def columnize(result)
        columns = Set.new
        result.each { |r| columns += r.keys }
        columns = columns.to_a
        rows = result.map { |r| columns.map { |c| r[c] } }
        [columns, rows, nil]
      end

      def timestamp_data(result, key)
        result.flat_map do |r|
          r[key].map { |x| x['timestamp'] = r['timestamp'].to_datetime; x }
        end
      end

      def raw_data(result)
        result.flat_map do |r|
          r['result']['events'].map do |e|
            event = e['event']
            event['timestamp'] = event['timestamp'].to_datetime
            event
          end
        end
      end

      def wrap_if_not_array(x)
        x.is_a?(Array) ? x : [x]
      end

      def generic_result(result)
        [['result'], [wrap_if_not_array(result)], nil]
      end

      def select(result, select_stmt)
        columns, rows = result
        columnar_values = rows.transpose

        ordered_columns = select_stmt.map do |col|
          i = columns.index(col)
          raise "#{col} is not a valid column name. Valid options are: #{columns}" unless i
          columnar_values[i]
        end

        rows = ordered_columns.first.zip(*ordered_columns[1..-1])
        [select_stmt, rows, nil]
      end

      def order(result, order_stmt)
        columns, rows = result
        col = order_stmt.is_a?(String) ? order_stmt : order_stmt[0]
        dir = order_stmt.is_a?(String) ? 'asc' : order_stmt[1].downcase

        i = columns.index(col)
        raise "#{col} is not a valid column name. Valid options are: #{columns}" unless i

        rows = rows.sort_by { |r| r[i] }
        rows = rows.reverse unless dir == 'asc'

        [columns, rows, nil]
      end
    end
  end
end
