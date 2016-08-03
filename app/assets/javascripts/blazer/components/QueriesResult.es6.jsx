class QueriesResult extends React.Component {
  componentDidMount() {
    if (this.props.stickyHeaders) {
      $(this._table).stupidtable().stickyTableHeaders({fixedOffset: 60});
    }
  }

  formatValue(k, v) {
      // if value.is_a?(Integer) && !key.to_s.end_with?("id") && !key.to_s.start_with?("id")
      //   number_with_delimiter(value)
      // elsif value =~ BLAZER_URL_REGEX
      //   # see if image or link
      //   if Blazer.images && (key.include?("image") || BLAZER_IMAGE_EXT.include?(value.split(".").last.split("?").first.try(:downcase)))
      //     link_to value, target: "_blank" do
      //       image_tag value, referrerpolicy: "no-referrer"
      //     end
      //   else
      //     link_to value, value, target: "_blank"
      //   end
      // else
      //   value
      // end

    return v
  }

  render() {
    const { columns, rows, error, success, only_chart } = this.props

    if (error) {
      return <div className="alert alert-danger">{error}</div>
    }

    if (!success) {
      if (only_chart) {
        return <p className="text-muted">Select variables</p>
      } else {
        return <div className="alert alert-info">Can’t preview queries with variables...yet!</div>
      }
    }

    return (
      <div>
        {this.renderHeader()}
        {this.renderChart()}
        <div className="results-container">
          {this.renderTable()}
        </div>
      </div>
    )
  }

  renderCell(row, v, i) {
    const { columns } = this.props

    let k = columns[i]

    if (v !== null) {
    // <% if v.is_a?(Time) %>
    //   <% v = blazer_time_value(@data_source, k, v) %>
    // <% end %>

    //   <% if v.is_a?(String) && v == "" %>
    //     <div class="text-muted">empty string</div>
    //   <% elsif @linked_columns[k] %>
    //     <%= link_to blazer_format_value(k, v), @linked_columns[k].gsub("{value}", u(v.to_s)), target: "_blank" %>
    //   <% else %>
    //     <%= blazer_format_value(k, v) %>
    //   <% end %>

    //   <% if v2 = (@boom[k] || {})[v.to_s] %>
    //     <div class="text-muted"><%= v2 %></div>
    //   <% end %>

      return this.formatValue(k, v)
    }
  }

  renderChart() {
    const { rows } = this.props

    if (rows.length > 0) {


//     <% values = @rows.first %>
//     <% chart_id = SecureRandom.hex %>
//     <% column_types = @result.column_types %>
//     <% chart_type = @result.chart_type %>
//     <% chart_options = {id: chart_id, min: nil} %>
//     <% series_library = {} %>
//     <% target_index = @columns.index { |k| k.downcase == "target" } %>
//     <% if target_index %>
//       <% series_library[target_index - 1] = {pointStyle: "line", hitRadius: 5, borderColor: "#109618", pointBackgroundColor: "#109618", backgroundColor: "#109618"} %>
//     <% end %>
//     <% if blazer_maps? && @markers.any? %>
//       <div id="map" style="height: <%= @only_chart ? 300 : 500 %>px;"></div>
//       <script>
//         L.mapbox.accessToken = '<%= ENV["MAPBOX_ACCESS_TOKEN"] %>';
//         var map = L.mapbox.map('map', 'ankane.ioo8nki0');
//         var markers = <%= blazer_json_escape(@markers.to_json).html_safe %>;
//         var featureLayer = L.mapbox.featureLayer().addTo(map);
//         var geojson = [];
//         for (var i = 0; i < markers.length; i++) {
//           var marker = markers[i];
//           geojson.push({
//             type: 'Feature',
//             geometry: {
//               type: 'Point',
//               coordinates: [
//                 marker.longitude,
//                 marker.latitude
//               ]
//             },
//             properties: {
//               description: marker.title,
//               'marker-color': '#f86767',
//               'marker-size': 'medium'
//             }
//           });
//         }
//         featureLayer.setGeoJSON(geojson);
//         map.fitBounds(featureLayer.getBounds());
//       </script>
//     <% elsif chart_type == "line" %>
//       <%= line_chart @columns[1..-1].each_with_index.map{ |k, i| {name: k, data: @rows.map{ |r| [r[0], r[i + 1]] }, library: series_library[i]} }, chart_options %>
//     <% elsif chart_type == "line2" %>
//       <%= line_chart @rows.group_by { |r| v = r[1]; (@boom[@columns[1]] || {})[v.to_s] || v }.each_with_index.map { |(name, v), i| {name: name, data: v.map { |v2| [v2[0], v2[2]] }, library: series_library[i]} }, chart_options %>
//     <% elsif chart_type == "bar" %>
//       <%= column_chart (values.size - 1).times.map { |i| name = @columns[i + 1]; {name: name, data: @rows.first(20).map { |r| [(@boom[@columns[0]] || {})[r[0].to_s] || r[0], r[i + 1]] } } }, id: chart_id %>
//     <% elsif chart_type == "bar2" %>
//       <% first_20 = @rows.group_by { |r| r[0] }.values.first(20).flatten(1) %>
//       <% labels = first_20.map { |r| r[0] }.uniq %>
//       <% series = first_20.map { |r| r[1] }.uniq %>
//       <% labels.each do |l| %>
//         <% series.each do |s| %>
//           <% first_20 << [l, s, 0] unless first_20.find { |r| r[0] == l && r[1] == s } %>
//         <% end %>
//       <% end %>
//       <%= column_chart first_20.group_by { |r| v = r[1]; (@boom[@columns[1]] || {})[v.to_s] || v }.each_with_index.map { |(name, v), i| {name: name, data: v.sort_by { |r2| labels.index(r2[0]) }.map { |v2| v3 = v2[0]; [(@boom[@columns[0]] || {})[v3.to_s] || v3, v2[2]] }} }, id: chart_id %>
//     <% elsif @only_chart %>
//       <% if @rows.size == 1 && @rows.first.size == 1 %>
//         <% v = @rows.first.first %>
//         <% if v.is_a?(String) && v == "" %>
//           <div class="text-muted">empty string</div>
//         <% else %>
//           <p style="font-size: 160px;"><%= blazer_format_value(@columns.first, v) %></p>
//         <% end %>
//       <% else %>
//         <% @no_chart = true %>
//       <% end %>
//     <% end %>

    }
  }

  renderHeader() {
    const { only_chart } = this.props

    if (!only_chart) {
//     <% if @cached_at || @just_cached %>
//       <p class="text-muted" style="float: right;">
//         <% if @cached_at %>
//           Cached <%= time_ago_in_words(@cached_at, include_seconds: true) %> ago
//         <% elsif !params[:data_source] %>
//           Cached just now
//           <% if @data_source.cache_mode == "slow" %>
//             (over <%= "%g" % @data_source.cache_slow_threshold %>s)
//           <% end %>
//         <% end %>

//         <% if @query && !params[:data_source] %>
//           <%= link_to "Refresh", refresh_query_path(@query, variable_params), method: :post %>
//         <% end %>
//       </p>
//     <% end %>
//     <p class="text-muted">
//       <%= pluralize(@rows.size, "row") %>

//       <% @checks.select(&:state).each do |check| %>
//         &middot; <small class="check-state <%= check.state.parameterize("_") %>"><%= link_to check.state.upcase, edit_check_path(check) %></small>
//         <% if check.try(:message) %>
//           &middot; <%= check.message %>
//         <% end %>
//       <% end %>
//     </p>
    }
  }

  renderTable() {
    const { columns, rows, only_chart, column_types, min_width_types } = this.props
    let noChart = false

    if (rows.length > 0) {
      if (!only_chart || noChart) {
        // TODO better equals
        if (JSON.stringify(columns) === JSON.stringify(["QUERY PLAN"])) {
          return <pre><code>{rows.map((r) => r[0]).join("\n")}</code></pre>
        } else {
          const headerWidth = 100.0 / columns.length
          return (
            <table ref={(n) => this._table = n} className="table results-table" style={{marginBottom: 0}}>
              <thead>
                <tr>
                  {columns.map((key, i) => {
                    return (
                      <th key={i} style={{width: `${headerWidth}%`}} data-sort={column_types[i]}>
                        <div style={{minWidth: `${min_width_types.indexOf(i) !== -1 ? 180 : 60}px`}}>
                          {key}
                        </div>
                     </th>
                    )
                  })}
                </tr>
              </thead>
              <tbody>
                {rows.map((row, j) => {
                  return (
                    <tr key={j}>
                      {row.map((v, i) => {
                        return <td key={i}>{this.renderCell(row, v, i)}</td>
                      })}
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )
        }
      }
    } else if (only_chart) {
      return <p className="text-muted">No rows</p>
    }
  }
}
