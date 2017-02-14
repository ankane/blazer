class ApplicationAdapter

  attr_accessor :format, :render_method

  def initialize(query, columns, rows, data_source)
    @query = query
    @columns = columns
    @rows = rows
    @data_source = data_source
    @format = self.class.format
  end

end
