module Blazer
  class Sharing
    attr_accessor :api_key, :path

    def initialize(api_key: ENV.fetch('BLAZER_DOWNLOAD_API_KEY', nil), path: '/blazer_share')
      @api_key = api_key
      @path = path.sub(/\/$/, '') # Strip trailing /
    end

    def route_path
      @route_path ||= "#{path}/:token/:query_id"
    end

    def to_controller
      'blazer/queries#share'
    end

    def query_token(query_id)
      Digest::SHA1.hexdigest("#{query_id}-#{ENV.fetch('BLAZER_DOWNLOAD_API_KEY')}")
    end

    def enabled?
      api_key.present?
    end

    def share_path(query_id, format: nil)
      "#{path}/#{query_token(query_id)}/#{query_id}#{".#{format}" if format}"
    end

    def url_for(query_id, current_url, format: 'csv')
      url = URI.parse(current_url)
      url.path = share_path(query_id, format: format)
      url.to_s
    end
  end
end
