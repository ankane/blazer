//= require ./jquery
//= require ./tablesort
//= require ./selectize
//= require ./highlight.min
//= require ./moment
//= require ./moment-timezone-with-data
//= require ./daterangepicker
//= require ./chart.umd
//= require ./chartjs-adapter-date-fns.bundle
//= require ./chartkick
//= require ./mapkick.bundle
//= require ./ace
//= require ./Sortable
//= require ./routes
//= require ./queries
//= require ./fuzzysearch

document.addEventListener("mouseover", function (e) {
  const target = e.target.closest(".dropdown-toggle")
  if (target) {
    target.parentElement.classList.add("open")
  }
})

document.addEventListener("change", function (e) {
  const target = e.target.closest("#bind input, #bind select")
  if (target) {
    submitIfCompleted(target.closest("form"))
  }
})

document.addEventListener("click", function (e) {
  const target = e.target.closest("#code")
  if (target) {
    target.classList.add("expanded")
  }
})

document.addEventListener("click", function (e) {
  const target = e.target.closest("a[disabled]")
  if (target) {
    e.preventDefault()
  }
})

document.addEventListener("click", function (e) {
  const target = e.target.closest("a[data-confirm]")
  if (target) {
    if (!window.confirm(target.getAttribute("data-confirm"))) {
      e.preventDefault()
    }
  }
})

function submitIfCompleted(form) {
  let completed = true
  for (const input of form.querySelectorAll("input[name], select")) {
    if (input.value == "") {
      completed = false
      break
    }
  }
  if (completed) {
    form.submit()
  }
}

// Prevent backspace from navigating backwards.
// Adapted from Biff MaGriff: http://stackoverflow.com/a/7895814/1196499
function preventBackspaceNav() {
  $(document).keydown(function (e) {
    var preventKeyPress
    if (e.keyCode == 8) {
      var d = e.srcElement || e.target
      switch (d.tagName.toUpperCase()) {
        case 'TEXTAREA':
          preventKeyPress = d.readOnly || d.disabled
          break
        case 'INPUT':
          preventKeyPress = d.readOnly || d.disabled || (d.attributes["type"] && $.inArray(d.attributes["type"].value.toLowerCase(), ["radio", "reset", "checkbox", "submit", "button"]) >= 0)
          break
        case 'DIV':
          preventKeyPress = d.readOnly || d.disabled || !(d.attributes["contentEditable"] && d.attributes["contentEditable"].value == "true")
          break
        default:
          preventKeyPress = true
          break
      }
    }
    else {
      preventKeyPress = false
    }

    if (preventKeyPress) {
      e.preventDefault()
    }
  })
}

preventBackspaceNav()

function show(element) {
  element.classList.remove("hide")
}

function hide(element) {
  element.classList.add("hide")
}

function toggle(element, found) {
  if (found) {
    show(element)
  } else {
    hide(element)
  }
}

function pathParams(params) {
  return (new URLSearchParams(params)).toString()
}

function getJSON(url, success, controller) {
  const options = {headers: {"Accept": "application/json"}}
  if (controller) {
    options.signal = controller.signal
  }
  fetch(url, options)
    .then(function (response) {
      if (!response.ok) {
        throw new Error(response.statusText)
      }
      return response.json()
    })
    .then(success)
}

function renderResults(element, data) {
  $(element).html(data)
}
