class RenderAdapter < ApplicationAdapter

  def initialize(*args)
    @render_method = :render
    super(*args)
  end

end
