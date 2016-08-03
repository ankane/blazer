class QueriesForm extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      loading: false
    }
    this.runStatement = this.runStatement.bind(this)
  }

  componentDidMount() {
    let editor = ace.edit(this._editor)
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
        // $("#run").click()
      },
      readOnly: false // false if this command should not apply in readOnly mode
    })

    this.editor = editor
  }

  render() {
    const { query } = this.props

    return (
      <div>
        <form>
          <div className="row">
            <div className="col-xs-8">
              <div className= "form-group">
                <div id="editor-container">
                  <div id="editor" ref={(n) => this._editor = n}>{query.statement}</div>
                </div>
              </div>
              <div className="form-group text-right">
                <div className="pull-left" style={{marginTop: "6px"}}>
                </div>
                <button onClick={this.runStatement} className="btn btn-info" style={{verticalAlign: "top"}}>Run</button>
              </div>
            </div>
            <div className="col-xs-4">
              <div className="form-group">
                <label htmlFor="name">Name</label>
                <input type="text" className="form-control" />
              </div>
              <div className="form-group">
                <label htmlFor="description">Description</label>
                <textarea style={{height: "80px"}} placeholder="Optional" className="form-control"></textarea>
              </div>
              <div className="text-right">
                <input type="submit" value="Create" className="btn btn-success" />
              </div>
            </div>
          </div>
        </form>
        <div id="results">
          {this.renderResults()}
        </div>
      </div>
    )
  }

  renderResults() {
    if (this.state.loading) {
      return <p className="text-muted">Loading...</p>
    } else if (this.state.results) {
      return <QueriesResult stickyHeaders={false} {...this.state.results} />
    }
  }

  runStatement(e) {
    e.preventDefault()

    var data = $.extend({}, this.props.variableParams, {statement: this.editor.getValue(), data_source: "main"})

    this.setState({loading: true})

    runQuery(data, (data) => {
      this.setState({results: data, loading: false})
    })
  }
}


// <script>


//  // http://stackoverflow.com/questions/11584061/
//  function adjustHeight() {
//     var lines = editor.getSession().getScreenLength();
//     if (lines < 9) {
//       lines = 9;
//     }

//     var newHeight = (lines + 1) * 16;
//     $("#editor").height(newHeight.toString() + "px");
//     editor.resize();
//   };

//   function getSQL() {
//     var selectedText = editor.getSelectedText();
//     var text = selectedText.length < 10 ? editor.getValue() : selectedText;
//     return text.replace(/\n/g, "\r\n");
//   }

//   function getErrorLine() {
//     var error_line = /LINE (\d+)/g.exec($("#results").find('.alert-danger').text());

//     if (error_line) {
//       error_line = parseInt(error_line[1], 10);
//       if (editor.getSelectedText().length >= 10) {
//         error_line += editor.getSelectionRange().start.row;
//       }
//       return error_line;
//     }
//   }

//   editor.getSession().on("change", adjustHeight);
//   adjustHeight();
//   $("#editor").show();
//   editor.focus();

//   var error_line = null;
//   var xhr;
//   var params = <%= raw blazer_json_escape(variable_params.to_json) %>;
//   var previewStatement = <%= raw blazer_json_escape(Hash[Blazer.data_sources.map { |k, v| [k, v.preview_statement] }].to_json) %>;

//   $("#run").click(function (e) {
//     e.preventDefault();

//     if (error_line) {
//       editor.getSession().removeGutterDecoration(error_line - 1, "error");
//       error_line = null;
//     }

//     $("#results").html('<p className="text-muted">Loading...</p>');
//     if (xhr) {
//       xhr.abort();
//     }

//     var data = $.extend({}, params, {statement: getSQL(), data_source: $("#query_data_source").val()});

//     xhr = runQuery(data, function (data) {
//       $("#results").html(data);

//       error_line = getErrorLine();
//       if (error_line) {
//         editor.getSession().addGutterDecoration(error_line - 1, "error");
//         editor.scrollToLine(error_line, true, true, function () {});
//         editor.gotoLine(error_line, 0, true);
//         editor.focus();
//       }
//     });
//   });

//   if ($("#query_statement").val() != "") {
//     $("#run").click();
//   }

//   $(document).on("change", "#table_names", function () {
//     var val = $(this).val();
//     if (val.length > 0) {
//       var dataSource = $("#query_data_source").val();
//       editor.setValue(previewStatement[dataSource].replace("{table}", val));
//       $("#run").click();
//     }
//   });

//   $("form.the_form").on("submit", function() {
//     $("#query_statement").val(editor.getValue());
//     return true;
//   });

//   preventBackspaceNav();
// </script>
