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
  const target = e.target.closest("a[data-confirm], a[data-method]")
  if (!target) return

  const confirmMessage = target.getAttribute("data-confirm")

  if (confirmMessage && !window.confirm(confirmMessage)) {
    e.preventDefault()
    e.stopImmediatePropagation()
    return
  }

  const method = target.getAttribute("data-method")
  if (!method) return

  e.preventDefault()
  e.stopImmediatePropagation()

  const form = document.createElement("form")
  form.method = "post"
  form.action = target.href
  form.hidden = true

  if (target.target) {
    form.target = target.target
  }

  const methodInput = document.createElement("input")
  methodInput.type = "hidden"
  methodInput.name = "_method"
  methodInput.value = method
  form.appendChild(methodInput)

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
  const csrfParam = document.querySelector('meta[name="csrf-param"]')?.getAttribute("content")
  const url = new URL(target.href, window.location.href)

  if (csrfToken && csrfParam && url.origin === window.location.origin) {
    const csrfInput = document.createElement("input")
    csrfInput.type = "hidden"
    csrfInput.name = csrfParam
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)
  }

  document.body.appendChild(form)
  form.submit()
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
