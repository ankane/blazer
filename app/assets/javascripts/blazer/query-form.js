const extractTableNameFromEditor = function(content, pos) {
  const lines = content.split('\n');
  const currentRow = lines[pos.row];
  const previousTokens = currentRow.slice(pos.column - 2, pos.column);
  const columnSeparatorPosition = previousTokens.indexOf('.');
  if (columnSeparatorPosition === -1) {
    return null;
  }
  const absolutTableNamePosition = ((pos.column) - previousTokens.length) + columnSeparatorPosition;

  let tableName = "";
  for (index = absolutTableNamePosition - 1; index > 0; index--) {
    if (currentRow[index] === ' ') {
      break;
    } else {
      tableName += currentRow[index];
    }
  }
  return tableName.split('').reverse().join('');
}

function initializeQueryForm(variableParams, previewStatement, tableNames) {

  let editor;

  var app = Vue.createApp({
    data: function() {
      return {
        running: false,
        results: "",
        error: false,
        dataSource: "",
        selectize: null,
        editorHeight: "180px"
      }
    },
    computed: {
      schemaPath: function() {
        return Routes.schema_queries_path({data_source: this.dataSource})
      },
      docsPath: function() {
        return Routes.docs_queries_path({data_source: this.dataSource})
      }
    },
    methods: {
      run: function(e) {
        this.running = true
        this.results = ""
        this.error = false
        cancelAllQueries()

        var data = {statement: this.getSQL(), data_source: $("#query_data_source").val(), variables: variableParams}

        var _this = this

        runQuery(data, function (data) {
          _this.running = false
          _this.showResults(data)

          errorLine = _this.getErrorLine()
          if (errorLine) {
            editor.getSession().addGutterDecoration(errorLine - 1, "error")
            editor.scrollToLine(errorLine, true, true, function () {})
            editor.gotoLine(errorLine, 0, true)
            editor.focus()
          }
        }, function (data) {
          _this.running = false
          _this.error = true
          _this.showResults(data)
        })
      },
      cancel: function(e) {
        this.running = false
        cancelAllQueries()
      },
      runPrompt: function(e) {
        this.running = true

        var data = {prompt: this.getPrompt(), data_source: $("#query_data_source").val()}
        var _this = this

        runPrompt(data, function (data) {
          _this.running = false
          _this.showPromptResults(data)
        }, function (data) {
          _this.running = false
          _this.error = true
          _this.showPromptResults(data)
        })
      },
      cancelPrompt: function(e) {
        this.running = false
      },
      updateDataSource: function(dataSource) {
        this.dataSource = dataSource
        var selectize = this.selectize
        selectize.clearOptions()

        if (this.tablesXhr) {
          this.tablesXhr.abort()
        }

        this.tablesXhr = $.getJSON(Routes.tables_queries_path({data_source: this.dataSource}), function(data) {
          var newOptions = []
          for (var i = 0; i < data.length; i++) {
            var table = data[i]
            if (typeof table === "object") {
              newOptions.push({text: table.table, value: table.value})
            } else {
              newOptions.push({text: table, value: table})
            }
          }
          selectize.clearOptions()
          selectize.addOption(newOptions)
          selectize.refreshOptions(false)
        })
      },
      showEditor: function() {
        var _this = this

        editor = ace.edit("editor")
        editor.setTheme("ace/theme/twilight")
        editor.getSession().setMode("ace/mode/sql")
        editor.setOptions({
          enableBasicAutocompletion: true,
          enableSnippets: false,
          enableLiveAutocompletion: true,
          highlightActiveLine: false,
          fontSize: 12,
          minLines: 10
        });

        editor.completers.push({
          getCompletions: function(editor, session, pos, prefix, callback) {
            callback(null, tableNames);
          }
        });

        editor.completers.push({
          getCompletions: function(editor, session, pos, prefix, callback) {
            const tableName = extractTableNameFromEditor(editor.getValue(), pos);
            if (tableName !== null) {
              for (index = 0; index < tableNames.length; index++) {
                const entry = tableNames[index];
                if (entry.value === tableName) {
                  callback(null, entry.columns);
                  break;
                }
              }
            }
          }
        });

        editor.renderer.setShowGutter(true)
        editor.renderer.setPrintMarginColumn(false)
        editor.renderer.setPadding(10)
        editor.getSession().setUseWrapMode(true)
        editor.commands.addCommand({
          name: "run",
          bindKey: {win: "Ctrl-Enter",  mac: "Command-Enter"},
          exec: function(editor) {
            _this.run()
          },
          readOnly: false // false if this command should not apply in readOnly mode
        })
        // fix command+L
        editor.commands.removeCommands(["gotoline", "find"])

        this.editor = editor

        editor.getSession().on("change", function () {
          $("#query_statement").val(editor.getValue())
          _this.adjustHeight()
        })
        this.adjustHeight()
        editor.focus()
      },
      adjustHeight: function() {
        // https://stackoverflow.com/questions/11584061/
        var editor = this.editor
        var lines = editor.getSession().getScreenLength()
        if (lines < 9) {
          lines = 9
        }

        this.editorHeight = ((lines + 1) * 16).toString() + "px"

        Vue.nextTick(function () {
          editor.resize()
        })
      },
      getPrompt: function() {
        return document.getElementById("prompt-editor").value;
      },
      getSQL: function() {
        var selectedText = editor.getSelectedText()
        var text = selectedText.length < 10 ? editor.getValue() : selectedText
        return text.replace(/\n/g, "\r\n")
      },
      getErrorLine: function() {
        var editor = this.editor
        var errorLine = this.results.substring(0, 100).includes("alert-danger") && /LINE (\d+)/g.exec(this.results)

        if (errorLine) {
          errorLine = parseInt(errorLine[1], 10)
          if (editor.getSelectedText().length >= 10) {
            errorLine += editor.getSelectionRange().start.row
          }
          return errorLine
        }
      },
      showResults(data) {
        // can't do it the Vue way due to script tags in results
        // this.results = data

        Vue.nextTick(function () {
          $("#results-html").html(data)
        })
      },
      showPromptResults(data) {
        // can't do it the Vue way due to script tags in results
        // this.results = data

        Vue.nextTick(function () {
          editor.setValue(data)
        })
      }
    },
    mounted: function() {
      var _this = this

      var $select = $("#table_names").selectize({})
      var selectize = $select[0].selectize
      selectize.on("change", function(val) {
        editor.setValue(previewStatement[_this.dataSource].replace("{table}", val), 1)
        _this.run()
        selectize.clear(true)
        selectize.blur()
      })
      this.selectize = selectize

      this.updateDataSource($("#query_data_source").val())

      var $dsSelect = $("#query_data_source").selectize({})
      var dsSelectize = $dsSelect[0].selectize
      dsSelectize.on("change", function(val) {
        _this.updateDataSource(val)
        dsSelectize.blur()
      })

      this.showEditor()
    }
  })
  app.config.compilerOptions.whitespace = "preserve"
  app.mount("#app")
}
