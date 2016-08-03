class QueriesResult extends React.Component {
  constructor(props) {
    super(props)
    this.urlRegex = /^https?:\/\/[\S]+$/
  }

  componentDidMount() {
    const { stickyHeaders, chart_type, columns, rows, boom } = this.props

    $(this._table).stupidtable()
    if (this.props.stickyHeaders) {
      $(this._table).stickyTableHeaders({fixedOffset: 60});
    }

    if (this._chartDiv) {
      let chartOptions = {min: null}
      let seriesLibrary = {}
      let targetIndex = columns.map((c) => c.toLowerCase()).indexOf("target")
      if (targetIndex !== -1) {
        seriesLibrary[targetIndex - 1] = {
          pointStyle: "line",
          hitRadius: 5,
          borderColor: "#109618",
          pointBackgroundColor: "#109618",
          backgroundColor: "#109618"
        }
      }

      if (chart_type === "line") {
        let data = columns.slice(1).map((k, i) => {
          return (
            {
              name: k,
              data: rows.map((r) => [r[0], r[i + 1]]),
              library: seriesLibrary[i]
            }
          )
        })
        new Chartkick.LineChart(this._chartDiv, data, chartOptions)
      } else if (chart_type === "line2") {
//       <%= line_chart @rows.group_by { |r| v = r[1]; (@boom[@columns[1]] || {})[v.to_s] || v }.each_with_index.map { |(name, v), i| {name: name, data: v.map { |v2| [v2[0], v2[2]] }, library: series_library[i]} }, chart_options %>
        // new Chartkick.LineChart(this._chartDiv, data, chartOptions)

      } else if (chart_type === "bar") {
        let data = []
        for (let i = 0; i < (columns.length - 1); i++) {
          let name = columns[i + 1]
          data.push({
            name: name,
            data: rows.slice(0, 20).map((r) => {
              return [(boom[columns[0]] || {})["" + r[0]] || r[0], r[i + 1]]
            })
          })
        }
        new Chartkick.ColumnChart(this._chartDiv, data, chartOptions)
      } else if (chart_type === "bar2") {

//       <% first_20 = @rows.group_by { |r| r[0] }.values.first(20).flatten(1) %>
//       <% labels = first_20.map { |r| r[0] }.uniq %>
//       <% series = first_20.map { |r| r[1] }.uniq %>
//       <% labels.each do |l| %>
//         <% series.each do |s| %>
//           <% first_20 << [l, s, 0] unless first_20.find { |r| r[0] == l && r[1] == s } %>
//         <% end %>
//       <% end %>
//       <%= column_chart first_20.group_by { |r| v = r[1]; (@boom[@columns[1]] || {})[v.to_s] || v }.each_with_index.map { |(name, v), i| {name: name, data: v.sort_by { |r2| labels.index(r2[0]) }.map { |v2| v3 = v2[0]; [(@boom[@columns[0]] || {})[v3.to_s] || v3, v2[2]] }} }, id: chart_id %>

      }
    }
  }

  formatValue(key, value) {
    // BLAZER_IMAGE_EXT = %w[png jpg jpeg gif]


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


    // TODO better integer check
    if (Number.isInteger(value) && key.slice(0, 2) != "id" && key.slice(-2) != "id") {
      return this.numberWithDelimiter(value)
    }

    if (typeof value === "string" && value.match(this.urlRegex)) {
      // TODO add referrerPolicy="no-referrer" when React supports it
      // https://github.com/facebook/react/pull/7274
      return <a href={value} target="_blank">{value}</a>
    }

    return value
  }

  // https://gist.github.com/scottwb/821904
  numberWithDelimiter(number) {
    let delimiter = delimiter || ','
    let split = (number + '').split('.')
    split[0] = split[0].replace(
        /(\d)(?=(\d\d\d)+(?!\d))/g,
        '$1' + delimiter
    )
    return split.join('.')
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
        {this.renderHeaderRight()}
        {this.renderHeaderLeft()}
        {this.renderChart()}
        {this.renderTable()}
      </div>
    )
  }

  renderCell(row, v, i) {
    const { columns, linked_columns, boom } = this.props
    const k = columns[i]
    let ele, smartColumn

    if (v !== null) {
      // <% if v.is_a?(Time) %>
      //   <% v = blazer_time_value(@data_source, k, v) %>
      // <% end %>

      if (typeof v === "string" && v === "") {
        ele = <div class="text-muted">empty string</div>
      } else if (linked_columns[k]) {
        ele = <a href={linked_columns[k].replace("{value}", v)} target="_blank">{this.formatValue(k, v)}</a>
      } else {
        ele = this.formatValue(k, v)
      }

      let v2 = (boom[k] || {})["" + v]
      if (v2) {
        smartColumn = <div className="text-muted">{v2}</div>
      }
    }

    return <td key={i}>{ele}{smartColumn}</td>
  }

  renderChart() {
    const { rows, chart_type, only_chart, markers } = this.props
    let maps = false

    if (rows.length > 0) {
      if (maps && markers.length > 0) {

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

      } else if (chart_type) {
        return <div className="chart-div" ref={(n) => this._chartDiv = n}></div>
      } else if (only_chart) {
        if (rows.length === 1 && columns.length === 1) {
          v = rows[0][0]
          if (typeof v === "string" && v === "") {
            return <div className="text-muted">empty string</div>
          } else {
            return <p style={{fontSize: "160px"}}>{this.formatValue(columns[0], v)}</p>
          }
        } else {
          this.noChart = true
        }
      }
    }
  }

  renderHeaderRight() {
    const { only_chart, cached_at, just_cached } = this.props

    if (!only_chart) {
      if (cached_at || just_cached) {
        return (
          <p className="text-muted" style={{float: "right"}}>
            Cached just now
          </p>
        )
      }
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
    }
  }

  renderHeaderLeft() {
    const { only_chart, rows } = this.props

    if (!only_chart) {
      return (
        <p className="text-muted">
          {rows.length} rows
        </p>
      )
    }

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

  renderTable() {
    const { columns, rows, only_chart, column_types, min_width_types, chart_type } = this.props
    let ele

    if (rows.length > 0) {
      if (!only_chart || this.noChart) {
        // TODO better equals
        if (JSON.stringify(columns) === JSON.stringify(["QUERY PLAN"])) {
          ele = <pre><code>{rows.map((r) => r[0]).join("\n")}</code></pre>
        } else {
          const headerWidth = 100.0 / columns.length
          ele = (
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
                        return this.renderCell(row, v, i)
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
      ele = <p className="text-muted">No rows</p>
    }

    if (ele) {
      return <div className="results-container">{ele}</div>
    }
  }
}
