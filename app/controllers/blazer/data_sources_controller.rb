module Blazer
  class DataSourcesController < BaseController
    def tables
      @tables = Blazer.data_sources[params[:id]].tables
      render partial: "tables", layout: false
    end

    def schema
      @schema = Blazer.data_sources[params[:id]].schema
    end
  end
end
