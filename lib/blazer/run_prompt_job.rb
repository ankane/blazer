module Blazer
  class RunPromptJob < ActiveJob::Base
    self.queue_adapter = :async

    def perform(data_source_id, prompt)
      @prompt = prompt
      @schema = Blazer.data_sources[data_source_id].schema.to_json
      @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"), log_errors: true)
      puts "doing gpt stuff. #{prompt}. #{@schema}"
      generate_sql
    end

    RETRIES = 3
    MAX_EXECUTION_TIME = 10.seconds

    def generate_sql
      sql = nil
      messages = [
        { role: "system", content: system_prompt },
        { role: "system", content: @schema },
        { role: "user", content: @prompt }
      ]

      RETRIES.times do |try_count|
        sql = @client.chat(parameters: { model: "gpt-4o", messages: }).dig("choices", 0, "message", "content")
        sql = sql.gsub(/```sql\n/, "").gsub(/\n```$/, "")

        messages << { role: "assistant", content: "Attempt ##{try_count.next}: `#{sql}`" }

        Timeout.timeout(MAX_EXECUTION_TIME) do
          ActiveRecord::Base.connection_pool.with_connection do
            ActiveRecord::Base.connection.execute(sql)
          end
        end

        return sql
      rescue Faraday::UnauthorizedError => e
        return e.response[:body]["error"]["message"]
      rescue Timeout::Error => e
        return sql
      rescue StandardError => e
        Rails.logger.error("Execution of SQL query failed: #{e.message}")
        messages << { role: "user", content: try_again_prompt(e) }
      end

      return sql
    end

    private

    def system_prompt
      <<~PROMPT
      You are an SQL generator for postgres. Make use of the schema json representing the database structure of a
      Ruby on Rails application. Given a prompt you always return an SQL query.
      Make sure that the query performs a SELECT and it is valid.
      Unless specified otherwise, returns all columns (*).
      Never generate a DROP, DELETE, or UPDATE statement.
      Format the query on multiple lines for readability.
      Do not include any comments.
      Do not add a semicolon at the end.
      Always respond with a raw SQL without markdown code block so that it can be directly executed.
      No markdown code blocks, really! Never start with ```.
    PROMPT
    end

    def try_again_prompt(error)
      <<~PROMPT
      This didn't work. The SQL query returned the following error: `#{error.message}`.
      Please try again and provide a corrected query.
    PROMPT
    end
  end
end
