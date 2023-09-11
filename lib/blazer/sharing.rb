module Blazer
  class Sharing
    attr_accessor :path, :enabled

    def initialize(enabled: false, path: '/blazer_share')
      @path = path.sub(/\/$/, '') # Strip trailing /
      @enabled = enabled
    end

    def route_path
      @route_path ||= "#{path}/:token/:query_id"
    end

    def to_controller
      'blazer/queries#share'
    end

    def enabled?
      enabled
    end

    def share_path(query_id, format: nil, token: nil)
      query = Query.find(query_id)
      "#{path}/#{token}/#{query_id}#{".#{format}" if format}"
    end

    def url_for(query_id, current_url, format: 'csv')
      url = URI.parse(current_url)
      url.path = share_path(query_id, format: format)
      url.to_s
    end
  end
end
