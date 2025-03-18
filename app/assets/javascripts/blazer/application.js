//= require ./jquery
//= require ./rails-ujs
//= require ./stupidtable
//= require ./stupidtable-custom-settings
//= require ./jquery.stickytableheaders
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
//= require ./bootstrap
//= require ./vue.global.prod
//= require ./routes
//= require ./queries
//= require ./fuzzysearch

$(document).on('mouseenter', '.dropdown-toggle', function () {
  $(this).parent().addClass('open')
})

$(document).on("change", "#bind input, #bind select", function () {
  submitIfCompleted($(this).closest("form"))
})

$(document).on("click", "#code", function () {
  $(this).addClass("expanded")
})

$(document).on("click", "a[disabled]", function (e) {
  e.preventDefault()
})

function submitIfCompleted($form) {
  var completed = true
  $form.find("input[name], select").each( function () {
    if ($(this).val() == "") {
      completed = false
    }
  })
  if (completed) {
    $form.submit()
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

