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

            final_method = nil
            final_args = nil
            final_relation = nil

            parents.reverse.each_with_index do |parent, i|
              method = parent.children[1]

              # check against known methods and scopes
              permitted =
                if relation.is_a?(ActiveRecord::QueryMethods::WhereChain)
                  method.in?([:not])
                else
                  method.in?([:all, :distinct, :group, :having, :joins, :left_outer_joins, :limit, :offset, :only, :order, :reselect, :reorder, :reverse_order, :rewhere, :select, :unscope, :unscoped, :where]) || has_scope?(cls, method)
                end

              # TODO add rest of methods
              if !permitted && defined?(Groupdate)
                permitted = method.in?([:group_by_day, :group_by_week, :group_by_hour_of_day]) && cls.respond_to?(method)
              end

              unless permitted
                permitted = method.in?([:any?, :average, :count, :exists?, :explain, :find, :find_by, :first, :ids, :last, :many?, :maximum, :minimum, :pluck, :sum, :take])
                if permitted
                  if i != parents.size - 1
                    raise "Method only permitted at end: #{method}"
                  end
                  final_method = method
                end
              end

              raise "Unpermitted method: #{method}" unless permitted

              args = parent.children[2..-1].map { |n| parse_arg(n) }
              if final_method
                final_args = args
                final_relation = relation
              end

              unless final_method == :explain
                # TODO check arity/parameters
                if args.last.is_a?(Hash)
                  relation = relation.send(method, *args[0..-2], **args[-1])
                else
                  relation = relation.send(method, *args)
                end
              end

              raise "Expected relation, not #{relation.class.name}" unless relation.is_a?(ActiveRecord::Relation) || relation.is_a?(ActiveRecord::QueryMethods::WhereChain) || final_method
            end

            case final_method
            when :find, :find_by, :first, :last, :take
              result = relation
              result = [result] unless result.is_a?(Array)
              if result.any?
                columns = result[0].attributes.keys
                result.each do |record|
                  rows << columns.map { |c| record.read_attribute(c) }
                end
              end
            when :pluck
              columns = final_args.map(&:to_s)
              rows = relation
            when :ids
              columns = ["id"]
              rows = relation.map { |r| [r] }
            when :any?, :exists?, :many?
              columns = [final_method.to_s[0..-2]]
              rows = [[relation]]
            when :average, :count, :maximum, :minimum, :sum
              result = relation
              if result.is_a?(Integer)
                columns = ["count"]
                rows << [result]
              elsif result.any?
                result.each do |k, v|
                  # TODO make more efficient
                  rows << ((k.is_a?(Array) ? k : [k]) + [v])
                end
                columns = final_relation.group_values.map(&:to_s)

                if final_relation.respond_to?(:groupdate_values)
                  final_relation.groupdate_values.each do |v|
                    columns[v.group_index] = v.period
                  end
                end

                columns[rows.first.size - 1] = final_method
              end
            else
              prefix = final_method == :explain ? "EXPLAIN " : ""
              result = relation.connection.select_all("#{prefix}#{relation.to_sql} /*#{comment}*/")
              columns = result.columns
              result.rows.each do |untyped_row|
                rows << (result.column_types.empty? ? untyped_row : columns.each_with_index.map { |c, i| untyped_row[i] && result.column_types[c] ? result.column_types[c].send(:cast_value, untyped_row[i]) : untyped_row[i] })
              end
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
