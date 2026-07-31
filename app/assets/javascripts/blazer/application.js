//= require ./tablesort
//= require ./tom-select.base
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

document.addEventListener("click", function (e) {
  const dropdown = document.querySelector(".dropdown-toggle")
  if (dropdown) {
    if (dropdown.contains(e.target)) {
      dropdown.parentElement.classList.toggle("open")
    } else {
      dropdown.parentElement.classList.remove("open")
    }
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
      e.stopImmediatePropagation()
    }
  }
})

function isSameOrigin(href) {
  return new URL(href, window.location.href).origin === window.location.origin
}

document.addEventListener("click", function (e) {
  const target = e.target.closest("a[data-method]")
  if (target) {
    e.preventDefault()

    const form = document.createElement("form")
    form.method = "post"
    form.action = target.href
    form.hidden = true

    let params = {"_method": target.getAttribute("data-method")}
    if (isSameOrigin(target.href)) {
      params = csrfProtect(params)
    }

    for (const [k, v] of Object.entries(params)) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = k
      input.value = v
      form.append(input)
    }

    document.body.append(form)
    form.submit()
  }
})

// make autofocus work with back button
window.addEventListener("pageshow", function (e) {
  if (e.persisted) {
    const element = document.querySelector("input[autofocus]")
    if (element) {
      element.focus()
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
  const range = document.createRange()
  element.replaceChildren(range.createContextualFragment(data))
}
