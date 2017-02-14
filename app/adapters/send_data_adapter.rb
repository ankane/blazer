class SendDataAdapter < ApplicationAdapter

  def initialize(*args)
    @render_method = :send_data
    super(*args)
  end

  def render_params
    [
      file_content,
      {
        type: file_type,
        disposition: disposition
      }
    ]
  end


  protected

  def file_content
    'not implemented'
  end

  def file_type
    "#{mime_type}; charset=#{charset}; header=present"
  end

  def disposition
    "attachment; filename=\"#{filename}\""
  end

  def mime_type
    'text/plain'
  end

  def charset
    'utf-8'
  end

  def filename
    "#{@query.try(:name).try(:parameterize).presence || 'query'}.#{@format}"
  end

end
