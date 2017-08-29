class Query::HtmlAdapter < RenderAdapter

  def render_params
    [
      { layout: false }
    ]
  end

  class << self

    def format
      :html
    end

  end

end
