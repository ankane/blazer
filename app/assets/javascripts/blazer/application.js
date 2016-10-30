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
//= require ./bootstrap
//= require ./vue
//= require ./vue.drag-and-drop
//= require ./routes

Vue.config.devtools = false

$(document).on('mouseenter', '.dropdown-toggle', function () {
  $(this).parent().addClass('open');
});

$(document).on("change", "#bind input, #bind select", function () {
  submitIfCompleted($(this).closest("form"));
});

$(document).on("click", "#code", function () {
  $(this).addClass("expanded");
});

function uuid() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
    return v.toString(16);
  });
}

function cancelQuery(runningQuery) {
  runningQuery.canceled = true;
  var xhr = runningQuery.xhr;
  if (xhr) {
    xhr.abort();
  }
  remoteCancelQuery(runningQuery);
  queryComplete();
}

function csrfProtect(payload) {
  var param = $("meta[name=csrf-param]").attr("content");
  var token = $("meta[name=csrf-token]").attr("content");
  if (param && token) payload[param] = token;
  return new Blob([JSON.stringify(payload)], {type : "application/json; charset=utf-8"});
}

function remoteCancelQuery(runningQuery) {
  var path = Routes.blazer_cancel_queries_path();
  var data = {run_id: runningQuery.run_id, data_source: runningQuery.data_source};
  if (navigator.sendBeacon) {
    navigator.sendBeacon(path, csrfProtect(data));
  } else {
    // TODO make sync
    $.post(path, data);
  }
}

var queriesQueue = [];
var runningQueries = 0;
var maxQueries = 3;

function queueQuery(callback) {
  queriesQueue.push(callback);
  runNext();
}

function runNext() {
  if (runningQueries < maxQueries) {
    var callback = queriesQueue.shift();
    if (callback) {
      runningQueries++;
      callback();
      runNext();
    }
  }
}

function queryComplete() {
  runningQueries--;
  runNext();
}

function runQuery(data, success, error, runningQuery) {
  queueQuery( function () {
    runningQuery = runningQuery || {};
    runningQuery.run_id = data.run_id = uuid();
    runningQuery.data_source = data.data_source;
    return runQueryHelper(data, success, error, runningQuery);
  });
}

function runQueryHelper(data, success, error, runningQuery) {
  var xhr = $.ajax({
    url: Routes.blazer_run_queries_path(),
    method: "POST",
    data: data,
    dataType: "html"
  }).done( function (d) {
    if (d[0] == "{") {
      var response = $.parseJSON(d);
      data.blazer = response;
      setTimeout( function () {
        if (!(runningQuery && runningQuery.canceled)) {
          runQueryHelper(data, success, error, runningQuery);
        }
      }, 1000);
    } else {
      if (!(runningQuery && runningQuery.canceled)) {
        success(d);
      }
      queryComplete();
    }
  }).fail( function(jqXHR, textStatus, errorThrown) {
    if (!(runningQuery && runningQuery.canceled)) {
      var message = (typeof errorThrown === "string") ? errorThrown : errorThrown.message;
      error(message);
    }
    queryComplete();
  });
  if (runningQuery) {
    runningQuery.xhr = xhr;
  }
  return xhr;
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

var editor;

// http://stackoverflow.com/questions/11584061/
function adjustHeight() {
  var lines = editor.getSession().getScreenLength();
  if (lines < 9) {
    lines = 9;
  }

  var newHeight = (lines + 1) * 16;
  $("#editor").height(newHeight.toString() + "px");
  editor.resize();
};

function getSQL() {
  var selectedText = editor.getSelectedText();
  var text = selectedText.length < 10 ? editor.getValue() : selectedText;
  return text.replace(/\n/g, "\r\n");
}

function getErrorLine() {
  var error_line = /LINE (\d+)/g.exec($("#results").find('.alert-danger').text());

  if (error_line) {
    error_line = parseInt(error_line[1], 10);
    if (editor.getSelectedText().length >= 10) {
      error_line += editor.getSelectionRange().start.row;
    }
    return error_line;
  }
}

var error_line = null;
var runningQuery;

function queryDone() {
  runningQuery = null
  $("#run").removeClass("hide")
  $("#cancel").addClass("hide")
}

$(document).on("click", "#cancel", function (e) {
  e.preventDefault()

  cancelQuery(runningQuery)
  queryDone()

  $("#results").html("")
})

function cancelQuery2() {
  if (runningQuery) {
    remoteCancelQuery(runningQuery)
  }
}

$(window).unload(cancelQuery2)

$(document).on("click", "#run", function (e) {
  e.preventDefault();

  $(this).addClass("hide")
  $("#cancel").removeClass("hide")

  if (error_line) {
    editor.getSession().removeGutterDecoration(error_line - 1, "error");
    error_line = null;
  }

  $("#results").html('<p class="text-muted">Loading...</p>');

  var data = $.extend({}, params, {statement: getSQL(), data_source: $("#query_data_source").val()});

  runningQuery = {};

  runQuery(data, function (data) {
    queryDone()

    $("#results").html(data);

    error_line = getErrorLine();
    if (error_line) {
      editor.getSession().addGutterDecoration(error_line - 1, "error");
      editor.scrollToLine(error_line, true, true, function () {});
      editor.gotoLine(error_line, 0, true);
      editor.focus();
    }
  }, function (data) {
    // TODO show error
    queryDone()
  }, runningQuery);
});

$(document).on("change", "#table_names", function () {
  var val = $(this).val();
  if (val.length > 0) {
    var dataSource = $("#query_data_source").val();
    editor.setValue(previewStatement[dataSource].replace("{table}", val), 1);
    $("#run").click();
  }
});

function showEditor() {
  editor = ace.edit("editor");
  editor.setTheme("ace/theme/twilight");
  editor.getSession().setMode("ace/mode/sql");
  editor.setOptions({
    enableBasicAutocompletion: false,
    enableSnippets: false,
    enableLiveAutocompletion: false,
    highlightActiveLine: false,
    fontSize: 12,
    minLines: 10
  });
  editor.renderer.setShowGutter(true);
  editor.renderer.setPrintMarginColumn(false);
  editor.renderer.setPadding(10);
  editor.getSession().setUseWrapMode(true);
  editor.commands.addCommand({
    name: 'run',
    bindKey: {win: 'Ctrl-Enter',  mac: 'Command-Enter'},
    exec: function(editor) {
      $("#run").click();
    },
    readOnly: false // false if this command should not apply in readOnly mode
  });
  // fix command+L
  editor.commands.removeCommands(["gotoline", "find"]);

  editor.getSession().on("change", function () {
    $("#query_statement").val(editor.getValue());
    adjustHeight();
  });
  adjustHeight();
  $("#editor").show();
  editor.focus();
}

preventBackspaceNav();

function updatePreviewSelect() {
  var dataSource = $("#query_data_source").val()
  $("#tables").load(Routes.blazer_tables_queries_path({data_source: dataSource}))
  $("#view-schema").attr("href", Routes.blazer_schema_queries_path({data_source: dataSource}))
}
