module Blazer
  module Adapters
    class SparkAdapter < HiveAdapter
      def tables
        client.execute("SHOW TABLES").map { |r| r["tableName"] }
      end
    end
  end
end
