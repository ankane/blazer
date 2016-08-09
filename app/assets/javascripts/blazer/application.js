//= require ./jquery
//= require ./jquery_ujs
//= require ./stupidtable
//= require ./jquery.stickytableheaders
//= require ./highlight.pack
//= require ./moment
//= require ./moment-timezone
//= require ./daterangepicker
//= require ./Chart.js
//= require ./chartkick
//= require ./ace
//= require ./bootstrap
//= require ./routes
//= require react
//= require react_ujs
//= require ./classnames-index
//= require ./react-input-autosize
//= require ./react-select
//= require_tree ./components

$(document).on("mouseenter", ".dropdown-toggle", function () {
  $(this).parent().addClass("open")
})

function runQuery(data, success, error) {
  return $.ajax({
    url: Routes.blazer_run_queries_path(),
    method: "POST",
    data: data,
    dataType: "json"
  }).done( function (d) {
    if (d[0] == "{") {
      var response = $.parseJSON(d);
      data.blazer = response;
      setTimeout( function () {
        runQuery(data, success, error);
      }, 1000);
    } else {
      success(d);
    }
  }).fail( function(jqXHR, textStatus, errorThrown) {
    var message = (typeof errorThrown === "string") ? errorThrown : errorThrown.message;
    error(message);
  });
}

function submitIfCompleted($form) {
  var completed = true;
  $form.find("input[name], select").each( function () {
    if ($(this).val() == "") {
      completed = false;
    }
  });
  if (completed) {
    $form.submit();
  }
}

// Prevent backspace from navigating backwards.
// Adapted from Biff MaGriff: http://stackoverflow.com/a/7895814/1196499
function preventBackspaceNav() {
  $(document).keydown(function (e) {
    var preventKeyPress;
    if (e.keyCode == 8) {
      var d = e.srcElement || e.target;
      switch (d.tagName.toUpperCase()) {
        case 'TEXTAREA':
          preventKeyPress = d.readOnly || d.disabled;
          break;
        case 'INPUT':
          preventKeyPress = d.readOnly || d.disabled || (d.attributes["type"] && $.inArray(d.attributes["type"].value.toLowerCase(), ["radio", "reset", "checkbox", "submit", "button"]) >= 0);
          break;
        case 'DIV':
          preventKeyPress = d.readOnly || d.disabled || !(d.attributes["contentEditable"] && d.attributes["contentEditable"].value == "true");
          break;
        default:
          preventKeyPress = true;
          break;
      }
    }
    else {
      preventKeyPress = false;
    }

    if (preventKeyPress) {
      e.preventDefault();
    }
  });
}
