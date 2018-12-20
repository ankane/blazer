require 'open3'
require 'irb'

module Blazer
  module Adapters
    class DockerAdapter < BashAdapter
      attr_reader :data_source

      def initialize(data_source)
        @data_source = data_source
        env_hash     = settings.fetch("env", {})
        command      = settings.fetch(
          "command",
          "python /usr/local/bin/python --"
        )
        docker_env = env_hash.map { |k, v| "-e #{k}=\"#{v}\"" }.join(" ")

        @command = "docker run --rm -i #{docker_env} #{command}"
        @env = {}
      end
    end
  end
end
