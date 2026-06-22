let pendingQueries = []
const runningQueries = []
const maxQueries = 3

function runQuery(data, success, error) {
  if (!data.data_source) {
    throw new Error("Data source is required to cancel queries")
  }
  data.run_id = uuid()
  const query = {
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
    const query = pendingQueries.shift()
    if (query) {
      runningQueries.push(query)
      runQueryHelper(query)
      runNext()
    }
  }
}

function runQueryHelper(query) {
  const formdata = createFormData(csrfProtect(query.data))
  const controller = new AbortController()
  fetch(Routes.run_queries_path(), {method: "POST", body: formdata, signal: controller.signal})
    .then(function (response) {
      if (!response.ok) {
        throw new Error(response.statusText)
      }
      return response.text()
    })
    .then( function (text) {
      if (text[0] == "{") {
        query.data.blazer = JSON.parse(text)
        setTimeout( function () {
          if (!query.canceled) {
            runQueryHelper(query)
          }
        }, 1000)
      } else {
        if (!query.canceled) {
          query.success(text)
        }
        queryComplete(query)
      }
    }).catch( function (error) {
      if (error.name == "AbortError") {
        cancelServerQuery(query)
      } else {
        query.error(error.message)
      }
      queryComplete(query)
    })
  query.controller = controller
}

function queryComplete(query) {
  const index = runningQueries.indexOf(query)
  runningQueries.splice(index, 1)
  runNext()
}

function uuid() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    const r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8)
    return v.toString(16)
  })
}

function cancelAllQueries() {
  pendingQueries = []
  for (const query of runningQueries) {
    cancelQuery(query)
  }
}

// needed for Chrome
// queries are canceled before unload with Firefox and Safari
window.addEventListener("beforeunload", cancelAllQueries)

function cancelQuery(query) {
  query.canceled = true
  if (query.controller) {
    query.controller.abort()
  }
}

function createFormData(params) {
  const formdata = new FormData()
  for (const [key, value] of Object.entries(params)) {
    if (typeof value === "object") {
      // handle single level of nesting
      for (const [k, v] of Object.entries(value)) {
        formdata.append(`${key}[${k}]`, v)
      }
    } else {
      formdata.append(key, value)
    }
  }
  return formdata
}

function cancelServerQuery(query) {
  // tell server
  const path = Routes.cancel_queries_path()
  const data = {run_id: query.run_id, data_source: query.data_source}
  const formdata = createFormData(csrfProtect(data))
  if (navigator.sendBeacon) {
    // use FormData over Blob and URLSearchParams for maximum compatibility
    // Blob works with Chrome 81+ and URLSearchParams works with Chrome 88+
    navigator.sendBeacon(path, formdata)
  } else {
    // TODO make sync
    fetch(path, {method: "POST", body: formdata})
  }
}

function csrfProtect(payload) {
  const param = document.querySelector("meta[name=csrf-param]")?.getAttribute("content")
  const token = document.querySelector("meta[name=csrf-token]")?.getAttribute("content")
  if (param && token) payload[param] = token
  return payload
}
