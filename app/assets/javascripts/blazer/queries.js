var pendingQueries = []
var runningQueries = []
var maxQueries = 3

function runQuery(data, success, error) {
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

function runQueryHelper(query) {
  var xhr = $.ajax({
    url: Routes.run_queries_path(),
    method: "POST",
    data: query.data,
    dataType: "html"
  }).done( function (d) {
    if (d[0] == "{") {
      var response = $.parseJSON(d)
      query.data.blazer = response
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
    if (!query.canceled) {
      var message = (typeof errorThrown === "string") ? errorThrown : errorThrown.message
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

$(window).unload(cancelAllQueries)

function cancelQuery(query) {
  query.canceled = true
  if (query.xhr) {
    query.xhr.abort()
  }

  // tell server
  var path = Routes.cancel_queries_path()
  var data = {run_id: query.run_id, data_source: query.data_source}
  if (navigator.sendBeacon) {
    navigator.sendBeacon(path, csrfProtect(data))
  } else {
    // TODO make sync
    $.post(path, data)
  }
}

function csrfProtect(payload) {
  var param = $("meta[name=csrf-param]").attr("content")
  var token = $("meta[name=csrf-token]").attr("content")
  if (param && token) payload[param] = token
  return new Blob([JSON.stringify(payload)], {type : "application/json; charset=utf-8"})
}
