var pendingQueries = []
var runningQueries = []
var maxQueries = 3

function runQuery(data, success, error) {
  if (!data.data_source) {
    throw new Error("Data source is required to cancel queries")
  }
  data.run_id = uuid()
  var query = {
    data: data,
    success: success,
    error: error,
    run_id: data.run_id,
    data_source: data.data_source,
    canceled: false
  }
  pendingQueries.push(query)
  runNext()
  return query
}

function runNext() {
  if (runningQueries.length < maxQueries) {
    var query = pendingQueries.shift()
    if (query) {
      runningQueries.push(query)
      runQueryHelper(query)
      runNext()
    }
  }
}

function arrayEquals(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

function chartDiv() {
  const div = document.createElement("div");
  div.style.height = "300px";
  div.style.lineHeight = "300px";
  div.style.textAlign = "center";
  return div;
}

function getChartType(columnTypes, columns) {
  let compactTypes = columnTypes.filter(v => v);
  if (compactTypes.length >= 2 && compactTypes[0] === "time" && compactTypes.slice(1).every(v => v === "numeric")) {
    return "line";
  } else if (arrayEquals(columnTypes, ["time", "string", "numeric"])) {
    return "line2";
  } else if (arrayEquals(columnTypes, ["string", "numeric"]) && columns[1] === "pie") {
    return "pie";
  } else if (compactTypes.length >= 2 && compactTypes[0] === "string" && compactTypes.slice(1).every(v => v === "numeric")) {
    return "bar";
  } else if (arrayEquals(columnTypes, ["string", "string", "numeric"])) {
    return "bar2";
  } else if (arrayEquals(columnTypes, ["numeric", "numeric"])) {
    return "scatter";
  }
}

function createElement(tag, text, classList) {
  const el = document.createElement(tag);
  if (classList) {
    for (let i = 0; i < classList.length; i++) {
      el.classList.add(classList[i]);
    }
  }
  el.appendChild(document.createTextNode(text));
  return el;
}

function explainElement(text) {
  const pre = document.createElement("pre");
  const code = createElement("code", text);
  pre.appendChild(code);
  return pre;
}

const urlRegex = /^https?:\/\/\S+$/

// TODO improve performance
function formatValue(key, value) {
  if (typeof value === "number" && !key.startsWith("id") && !key.endsWith("id")) {
    return document.createTextNode(value.toLocaleString("en-US"));
  }

  // TODO support images
  if (typeof value === "string" && urlRegex.test(value)) {
    const a = document.createElement("a");
    a.setAttribute("href", value);
    a.setAttribute("target", "_blank");
    a.appendChild(document.createTextNode(value));
    return a;
  }

  return document.createTextNode(value);
}

function seriesName(k) {
  return k === null ? "null" : k.toString();
}

function createResults(data, results, onlyChart) {
  const columns = data["columns"];
  const columnTypes = data["column_types"];
  const sortTypes = data["sort_types"];
  const rows = data["rows"];
  const linkedColumns = data["linked_columns"];
  const error = data["error"];
  const success = data["success"];
  const cohortAnalysis = data["cohort_analysis"];
  const cohortError = data["cohort_error"];
  const forecastError = data["forecastError"];
  const markers = data["markers"];
  const geojson = data["geojson"];
  const minWidthTypes = data["min_width_types"];
  const smartValues = data["smart_values"];
  const timeZone = data["time_zone"];

  if (error) {
    const div = createElement("div", error.slice(0, 200), ["alert", "alert-danger"]);
    results.appendChild(div);
    return;
  }

  if (!success) {
    if (onlyChart) {
      const p = createElement("p", "Select variables", ["text-muted"])
      results.append(p);
    } else {
      const div = createElement("div", "Can’t preview queries with variables...yet!", ["alert", "alert-info"]);
      results.appendChild(div);
    }
    return;
  }

  if (cohortAnalysis) {
    if (cohortError) {
      const div = createElement("div", cohortError, ["alert", "alert-info"])
      results.appendChild(div);
    } else {
      // TODO
    }
    return;
  }

  if (!onlyChart) {
    const text = rows.length == 1 ? "1 row" : (rows.length + " rows");
    const p = createElement("p", text, ["text-muted"]);
    p.style.marginBottom = "10px";
    results.appendChild(p);
  }

  if (forecastError) {
    const div = createElement("div", forecastError, ["alert", "alert-danger"])
    results.appendChild(div);
  }

  if (cohortError) {
    const div = createElement("div", cohortError, ["alert", "alert-danger"])
    results.appendChild(div);
  }

  if (rows.length > 0) {
    let chartType = getChartType(columnTypes, columns);

    const chartOptions = {};
    if (chartType === "line" || chartType === "line2") {
      chartOptions.min = null;
    }
    // TODO more chartOptions

    const seriesLibrary = {}
    const targetIndex = columns.findIndex(k => k.toLowerCase() === "target")
    if (targetIndex !== -1) {
      const color = "#109618";
      seriesLibrary[targetIndex] = {
        pointStyle: "line",
        hitRadius: 5,
        borderColor: color,
        pointBackgroundColor: color,
        backgroundColor: color,
        pointHoverBackgroundColor: color
      }
    }

    let noChart = false;

    if (markers.length > 0) {
      let div = document.createElement("div");
      div.style.height = onlyChart ? "300px" : "500px";
      results.appendChild(div);
      new Mapkick.Map(div, markers, {accessToken: mapboxAccessToken, tooltips: {hover: false, html: true}});
    } else if (geojson.length > 0) {
      let div = document.createElement("div");
      div.style.height = onlyChart ? "300px" : "500px";
      results.appendChild(div);
      new Mapkick.AreaMap(div, geojson, {accessToken: mapboxAccessToken, tooltips: {hover: false, html: true}});
    } else if (chartType === "line") {
      let div = chartDiv();
      results.appendChild(div);
      const chartData = [];
      for (let i = 1; i < columns.length; i++) {
        const name = columns[i];
        const seriesData = [];
        for (let j = 0; j < rows.length; j++) {
          const row = rows[j];
          seriesData.push([row[0], row[i]]);
        }
        chartData.push({name: seriesName(name), data: seriesData, library: seriesLibrary[i]})
      }
      new Chartkick.LineChart(div, chartData);
    } else if (chartType === "line2") {
      let div = chartDiv();
      results.appendChild(div);
      const groups = new Map()
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const v = row[1];
        const group = (smartValues[columns[1]] || {})["" + v] || v;
        if (!groups.has(group)) {
          groups.set(group, [])
        }
        groups.get(group).push([row[0], row[2]])
      }
      const chartData = [];
      groups.forEach((value, key) => {
        chartData.push({name: seriesName(key), data: value});
      });
      new Chartkick.LineChart(div, chartData);
    } else if (chartType === "pie") {
      let div = chartDiv();
      results.appendChild(div);
      new Chartkick.PieChart(div, rows);
    } else if (chartType === "bar") {
      let div = chartDiv();
      results.appendChild(div);
      const chartData = [];
      const firstN = Math.min(rows.length, 20);
      for (let i = 1; i < columns.length; i++) {
        const name = columns[i];
        const seriesData = [];
        for (let j = 0; j < firstN; j++) {
          const row = rows[j];
          seriesData.push([row[0], row[i]]);
        }
        chartData.push({name: seriesName(name), data: seriesData})
      }
      new Chartkick.ColumnChart(div, chartData);
    } else if (chartType === "bar2") {
      let div = chartDiv();
      results.appendChild(div);
      const groups = new Map()
      // for (let i = 0; i < rows.length; i++) {
      //   const row = rows[i];
      //   const v = row[1];
      //   const group = (smartValues[columns[1]] || {})["" + v] || v;
      //   if (!groups.has(group)) {
      //     groups.set(group, [])
      //   }
      //   groups.get(group).push([row[0], row[2]])
      // }
      const chartData = [];
      groups.forEach((value, key) => {
        chartData.push({name: seriesName(key), data: value});
      });
      new Chartkick.ColumnChart(div, chartData);
    } else if (chartType === "scatter") {
      let div = chartDiv();
      results.appendChild(div);
      new Chartkick.ScatterChart(div, rows, {xtitle: columns[0], ytitle: columns[1]});
    } else if (onlyChart) {
      if (rows.length === 1 && columns.length === 1) {
        const v = rows[0][0];
        if (typeof v === "string" && v === "") {
          const div = createElement("div", "empty string", ["text-muted"]);
          results.appendChild(div)
        } else {
          const p = document.createElement("p");
          p.appendChild(formatValue(columns[0], v));
          p.style.fontSize = "160px";
          results.appendChild(p);
        }
      } else {
        noChart = true;
      }
    }

    if (!(onlyChart && !noChart)) {
      const div = document.createElement("div");
      div.classList.add("results-container");

      if (arrayEquals(columns, ["QUERY PLAN"])) {
        div.appendChild(explainElement(rows.map(v => v[0]).join("\n")));
      } else if (arrayEquals(columns, ["PLAN"]) && data["druid"]) {
        div.appendChild(explainElement(rows[0][0]));
      } else {
        // table
        const table = document.createElement("table");
        table.classList.add("table");
        table.classList.add("results-table");

        // head
        const thead = document.createElement("thead");
        const tr = document.createElement("tr");
        const headerWidth = 100.0 / columns.length;
        for (let i = 0; i < columns.length; i++) {
          const th = document.createElement("th");
          th.style.width = headerWidth + "%";
          th.dataset.sort = sortTypes[i];
          const d = createElement("div", columns[i]);
          d.style.minWidth = minWidthTypes.includes(i) ? "180px" : "60px";
          th.appendChild(d);
          tr.appendChild(th);
        }
        thead.appendChild(tr);
        table.appendChild(thead);

        // body
        const tbody = document.createElement("tbody");
        for (let i = 0; i < rows.length; i++) {
          const row = rows[i];
          const tr = document.createElement("tr");
          for (let j = 0; j < columns.length; j++) {
            const k = columns[j];
            let v = row[j];
            const td = document.createElement("td");

            if (v !== null) {
              if (columnTypes[j] === "time" && v.length > 10) {
                v = moment(v).tz(timeZone).format("YYYY-MM-DD HH:mm:ss z")
              }

              let node
              if (typeof v === "string" && v === "") {
                 node = createElement("div", "empty string", ["text-muted"])
              } else {
                // TODO use index
                const linkedColumn = linkedColumns[k];
                if (linkedColumn) {
                  node = document.createElement("a");
                  node.href = linkedColumn.replaceAll("{value}", encodeURIComponent(v));
                  node.appendChild(formatValue(k, v));
                } else {
                  node = formatValue(k, v);
                }
              }
              td.appendChild(node);
            }

            const v2 = (smartValues[k] || {})[v === null ? v : "" + v];
            if (v2) {
              td.appendChild(createElement("div", v2, ["text-muted"]))
            }

            tr.appendChild(td);
          }
          tbody.appendChild(tr);
        }
        table.appendChild(tbody);

        div.appendChild(table);
      }

      results.appendChild(div);
    }
  } else if (onlyChart) {
    const p = createElement("p", "No rows", ["text-muted"]);
    results.appendChild(p);
  }
}

function runQueryHelper(query) {
  var xhr = $.ajax({
    url: Routes.run_queries_path(),
    method: "POST",
    data: query.data,
    dataType: "json"
  }).done( function (d) {
    if (d.run_id) {
      query.data.blazer = d
      setTimeout( function () {
        if (!query.canceled) {
          runQueryHelper(query)
        }
      }, 1000)
    } else {
      if (!query.canceled) {
        query.success(d)
      }
      queryComplete(query)
    }
  }).fail( function(jqXHR, textStatus, errorThrown) {
    // check jqXHR.status instead of query.canceled
    // so it works for page navigation with Firefox and Safari
    if (jqXHR.status === 0) {
      cancelServerQuery(query)
    } else {
      var message = (typeof errorThrown === "string") ? errorThrown : errorThrown.message
      if (!message) {
        message = "An error occurred"
      }
      query.error(message)
    }
    queryComplete(query)
  })
  query.xhr = xhr
  return xhr
}

function queryComplete(query) {
  var index = runningQueries.indexOf(query)
  runningQueries.splice(index, 1)
  runNext()
}

function uuid() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8)
    return v.toString(16)
  })
}

function cancelAllQueries() {
  pendingQueries = []
  for (var i = 0; i < runningQueries.length; i++) {
    cancelQuery(runningQueries[i])
  }
}

// needed for Chrome
// queries are canceled before unload with Firefox and Safari
$(window).on("unload", cancelAllQueries)

function cancelQuery(query) {
  query.canceled = true
  if (query.xhr) {
    query.xhr.abort()
  }
}

function cancelServerQuery(query) {
  // tell server
  var path = Routes.cancel_queries_path()
  var data = {run_id: query.run_id, data_source: query.data_source}
  if (navigator.sendBeacon) {
    // use FormData over Blob and URLSearchParams for maximum compatibility
    // Blob works with Chrome 81+ and URLSearchParams works with Chrome 88+
    var formdata = new FormData()
    var params = csrfProtect(data)
    for (var key in params) {
      if (Object.prototype.hasOwnProperty.call(params, key)) {
        formdata.append(key, params[key])
      }
    }
    navigator.sendBeacon(path, formdata)
  } else {
    // TODO make sync
    $.post(path, data)
  }
}

function csrfProtect(payload) {
  var param = $("meta[name=csrf-param]").attr("content")
  var token = $("meta[name=csrf-token]").attr("content")
  if (param && token) payload[param] = token
  return payload
}
