class QueriesResult extends React.Component {
  constructor(props) {
    super(props)
    this.urlRegex = /^https?:\/\/[\S]+$/
    this.timeRegex = /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?Z$/
  }

  componentDidMount() {
    const { stickyHeaders, chart_type, columns, rows, boom, markers } = this.props

    $(this._table).stupidtable()
    if (this.props.stickyHeaders) {
      $(this._table).stickyTableHeaders({fixedOffset: 60});
    }

    if (gon.mapbox_access_token && markers && markers.length > 0) {
      L.mapbox.accessToken = gon.mapbox_access_token
      var m = L.mapbox.map('map', 'ankane.ioo8nki0')
      var featureLayer = L.mapbox.featureLayer().addTo(m)
      var geojson = []
      for (var i = 0; i < markers.length; i++) {
        var marker = markers[i];
        geojson.push({
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [
              marker.longitude,
              marker.latitude
            ]
          },
          properties: {
            description: marker.title,
            'marker-color': '#f86767',
            'marker-size': 'medium'
          }
        });
      }
      featureLayer.setGeoJSON(geojson);
      m.fitBounds(featureLayer.getBounds());
    } else if (this._chartDiv) {
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
        let groupedData = _.groupBy(rows, (r) => {
          let v = r[1]
          return (boom[columns[1]] || {})["" + v] || v
        })
        let data = Object.keys(groupedData).map((name, i) => {
          let v = groupedData[name]
          return (
            {
              name: name,
              data: v.map((v2) => [v2[0], v2[2]]),
              library: seriesLibrary[i]
            }
          )
        })
        new Chartkick.LineChart(this._chartDiv, data, chartOptions)
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
        let first20 = _.flatten(_.values(_.groupBy(rows, (r) => r[0])).slice(0, 20))
        let labels = _.uniq(first20.map((r) => r[0]))
        let series = _.uniq(first20.map((r) => r[1]))
        labels.forEach((l) => {
          series.forEach((s) => {
            if (!_.find(first20, (r) => r[0] === l && r[1] === s)) {
              first20.push([l, s, 0])
            }
          })
        })
        let groupedData = _.groupBy(rows, (r) => {
          let v = r[1]
          return (boom[columns[1]] || {})["" + v] || v
        })
        let data = Object.keys(groupedData).map((name, i) => {
          let v = groupedData[name]
          return (
            {
              name: name,
              data: _.sortBy(v, (r2) => labels.indexOf(r2[0])).map((v2) => {
                let v3 = v2[0]
                return [(boom[columns[0]] || {})["" + v3] || v3, v2[2]]
              }),
              library: seriesLibrary[i]
            }
          )
        })
        new Chartkick.ColumnChart(this._chartDiv, data, chartOptions)
      }
    }
  }

  formatValue(key, value) {
    // TODO better integer check
    if (Number.isInteger(value) && key.slice(0, 2) != "id" && key.slice(-2) != "id") {
      return this.numberWithDelimiter(value)
    }

    if (typeof value === "string" && value.match(this.timeRegex)) {
      return moment(value).tz(gon.time_zone).format()
    }

    if (typeof value === "string" && value.match(this.urlRegex)) {
      // TODO check for image extension
      if (gon.images && key.indexOf("image") !== -1) {
        // TODO add referrerPolicy="no-referrer" when React supports it
        // https://github.com/facebook/react/pull/7274
        return <a href={value} target="_blank"><img src={value} /></a>
      } else {
        return <a href={value} target="_blank">{value}</a>
      }
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
        ele = <div className="text-muted">empty string</div>
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
    const { columns, rows, chart_type, only_chart, markers } = this.props

    if (rows.length > 0) {
      if (gon.mapbox_access_token && markers.length > 0) {
        return <div id="map" style={{height: only_chart ? "300px" : "500px"}}></div>
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
    const { only_chart, cached_at, just_cached, cache_mode, cache_slow_threshold } = this.props

    if (!only_chart) {
      if (cached_at || just_cached) {
        let cachedText, refreshLink

        if (cached_at) {
          cachedText = `Cached ${moment(cached_at).fromNow()}`
        } else {
          cachedText = "Cached just now"
          if (cache_mode === "slow") {
            cachedText += ` (over ${cache_slow_threshold}s)`
          }
        }

        refreshLink = <a href="#">Refresh</a>

//         <% if @query && !params[:data_source] %>
//           <%= link_to "Refresh", refresh_query_path(@query, variable_params), method: :post %>
//         <% end %>


        return (
          <p className="text-muted" style={{float: "right"}}>
            {cachedText}
            {" "}
            {refreshLink}
          </p>
        )
      }
    }
  }

  pluralize(count, singular) {
    let word = count === 1 ? singular : `${singular}s`
    return `${count} ${word}`
  }

  renderHeaderLeft() {
    const { only_chart, rows, checks } = this.props

    if (!only_chart) {
      return (
        <p className="text-muted">
          {this.pluralize(rows.length, "row")}

          {checks.filter((c) => c.state).map((check, i) => {
            return (
              <span key={i}>
                {" "}
                &middot;
                {" "}
                <small className={`check-state ${check.state.replace(" ", "_")}`}>
                  <a href={Routes.blazer_edit_check_path(check.id)}>{check.state.toUpperCase()}</a>
                  {" "}
                </small>
                {() => {
                  if (check.message) {
                    return <span>&middot; {check.message}</span>
                  }
                }()}
              </span>
            )
          })}
        </p>
      )
    }
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
