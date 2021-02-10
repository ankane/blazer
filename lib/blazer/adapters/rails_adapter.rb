module Blazer
  module Adapters
    class RailsAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          node = parser.parse(statement)

          parents = []
          while node && node.type == :send
            parents << node
            node = node.children[0]
          end

          if node && node.type == :const
            class_name = find_class_name(node)
            cls = models.find { |c| c.name == class_name }
            unless cls
              raise "Unknown model: #{class_name}"
            end

            relation = cls.all
            parents.reverse.each do |parent|
              method = parent.children[1]

              # check against known methods and scopes
              unless method.in?([:all, :group, :joins, :limit, :offset, :order, :rewhere, :reorder, :select, :where]) || has_scope?(cls, method)
                raise "Unpermitted method: #{method}"
              end

              args = parent.children[2..-1].map { |n| parse_arg(n) }
              relation = relation.send(method, *args)

              # TODO support aggregate methods like count and pluck for last node
              raise "Safety check failed" unless relation.is_a?(ActiveRecord::Relation)
            end

            result = relation.connection.select_all("#{relation.to_sql} /*#{comment}*/")
            columns = result.columns
            result.rows.each do |untyped_row|
              rows << (result.column_types.empty? ? untyped_row : columns.each_with_index.map { |c, i| untyped_row[i] && result.column_types[c] ? result.column_types[c].send(:cast_value, untyped_row[i]) : untyped_row[i] })
            end
          else
            raise "Invalid query"
          end
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def preview_statement
        "{table}.limit(10)"
      end

      def tables
        models.map(&:name).sort
      end

      # def schema
      #   TODO
      # end

      def highlight_mode
        "ruby"
      end

      private

      def parser
        @parser ||= begin
          require "parser/current"
          Parser::CurrentRuby
        end
      end

      def models
        eager_load
        ActiveRecord::Base.descendants.reject(&:abstract_class?)
      end

      # eager load models to populate models
      def eager_load
        unless defined?(@eager_load)
          if Rails.respond_to?(:autoloaders) && Rails.autoloaders.zeitwerk_enabled?
            # fix for https://github.com/rails/rails/issues/37006
            Zeitwerk::Loader.eager_load_all
          else
            Rails.application.eager_load!
          end
          @eager_load = true
        end
      end

      def find_class_name(node)
        parts = []
        while node
          raise "Unknown node type" unless node.type == :const
          parts << node.children[1]
          node = node.children[0]
        end
        parts.reverse.join("::")
      end

      def parse_arg(node)
        case node.type
        when :false, :float, :int, :nil, :str, :sym, :true
          node.children[0]
        when :array
          node.children.map { |n| parse_arg(n) }
        when :hash
          res = {}
          node.children.each do |n|
            raise "Expected pair, not #{n.type}" unless n.type == :pair
            res[parse_arg(n.children[0])] = parse_arg(n.children[1])
          end
          res
        when :irange
          Range.new(parse_arg(node.children[0]), parse_arg(node.children[1]))
        when :erange
          Range.new(parse_arg(node.children[0]), parse_arg(node.children[1]), true)
        else
          raise "Argument type not supported: #{node.type}"
        end
      end

      # not ideal, but Active Record doesn't keep track of scopes
      def has_scope?(cls, method)
        cls.singleton_method(method).source_location[0].end_with?("lib/active_record/scoping/named.rb")
      rescue NameError
        false
      end
    end
  end
end
