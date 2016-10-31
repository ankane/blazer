//= require ./jquery
//= require ./jquery_ujs
//= require ./stupidtable
//= require ./jquery.stickytableheaders
//= require ./selectize
//= require ./highlight.pack
//= require ./moment
//= require ./moment-timezone
//= require ./daterangepicker
//= require ./Chart.js
//= require ./chartkick
//= require ./ace
//= require ./Sortable
//= require ./bootstrap
//= require ./vue
//= require ./routes
//= require ./queries

Vue.config.devtools = false

$(document).on('mouseenter', '.dropdown-toggle', function () {
  $(this).parent().addClass('open')
})

$(document).on("change", "#bind input, #bind select", function () {
  submitIfCompleted($(this).closest("form"))
})

$(document).on("click", "#code", function () {
  $(this).addClass("expanded")
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

var editor

// http://stackoverflow.com/questions/11584061/
function adjustHeight() {
  var lines = editor.getSession().getScreenLength()
  if (lines < 9) {
    lines = 9
  }

  var newHeight = (lines + 1) * 16
  $("#editor").height(newHeight.toString() + "px")
  editor.resize()
}

function getSQL() {
  var selectedText = editor.getSelectedText()
  var text = selectedText.length < 10 ? editor.getValue() : selectedText
  return text.replace(/\n/g, "\r\n")
}

function getErrorLine() {
  var error_line = /LINE (\d+)/g.exec($("#results").find('.alert-danger').text())

  if (error_line) {
    error_line = parseInt(error_line[1], 10)
    if (editor.getSelectedText().length >= 10) {
      error_line += editor.getSelectionRange().start.row
    }
    return error_line
  }
}

var error_line = null

function showEditor() {
  editor = ace.edit("editor")
  editor.setTheme("ace/theme/twilight")
  editor.getSession().setMode("ace/mode/sql")
  editor.setOptions({
    enableBasicAutocompletion: false,
    enableSnippets: false,
    enableLiveAutocompletion: false,
    highlightActiveLine: false,
    fontSize: 12,
    minLines: 10
  })
  editor.renderer.setShowGutter(true)
  editor.renderer.setPrintMarginColumn(false)
  editor.renderer.setPadding(10)
  editor.getSession().setUseWrapMode(true)
  editor.commands.addCommand({
    name: 'run',
    bindKey: {win: 'Ctrl-Enter',  mac: 'Command-Enter'},
    exec: function(editor) {
      $("#run").click()
    },
    readOnly: false // false if this command should not apply in readOnly mode
  })
  // fix command+L
  editor.commands.removeCommands(["gotoline", "find"])

  editor.getSession().on("change", function () {
    $("#query_statement").val(editor.getValue())
    adjustHeight()
  })
  adjustHeight()
  $("#editor").show()
  editor.focus()
}

preventBackspaceNav()

