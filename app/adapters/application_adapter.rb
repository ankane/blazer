class ApplicationAdapter

  attr_reader :format, :render_method

  def initialize(query, columns, rows, data_source)
    @query = query
    @columns = columns
    @rows = rows
    @data_source = data_source
    @format = self.class.format
  end

  class << self
    def format
      'undefined'
    end
  end

end
