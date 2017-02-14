class Query::CsvAdapter < SendDataAdapter

  class << self

    def format
      :csv
    end

  end

  protected

  def mime_type
    'text/csv'
  end

  def file_content
    csv_data(@columns, @rows, @data_source)
  end

  def csv_data(columns, rows, data_source)
    CSV.generate do |csv|
      csv << columns
      rows.each do |row|
        csv << row.each_with_index.map { |v, i| v.is_a?(Time) ? blazer_time_value(data_source, columns[i], v) : v }
      end
    end
  end

  def blazer_time_value(data_source, k, v)
    data_source.local_time_suffix.any? { |s| k.ends_with?(s) } ? v.to_s.sub(" UTC", "") : v.in_time_zone(Blazer.time_zone)
  end

end
