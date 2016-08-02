class QueriesForm extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      editorHeight: "160px",
      loading: false,
      query: null
    }
    this.runQuery = this.runQuery.bind(this)
    this.handleSubmit = this.handleSubmit.bind(this)
    this.updateQuery = this.updateQuery.bind(this)
  }

  componentDidMount() {
    var editor = ace.edit(this._input);
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
    this.editor = editor;

    // http://stackoverflow.com/questions/11584061/
    const adjustHeight = () => {
      let lines = editor.getSession().getScreenLength();
      if (lines < 9) {
        lines = 9;
      }

      const newHeight = (lines + 1) * 16;
      this.setState({editorHeight: newHeight.toString() + "px"})
      editor.resize();
    };

   //  function getErrorLine() {
   //    var error_line = /LINE (\d+)/g.exec($("#results").find('.alert-danger').text());

   //    if (error_line) {
   //      error_line = parseInt(error_line[1], 10);
   //      if (editor.getSelectedText().length >= 10) {
   //        error_line += editor.getSelectionRange().start.row;
   //      }
   //      return error_line;
   //    }
   //  }

    editor.getSession().on("change", adjustHeight);
    adjustHeight();
   //  $("#editor").show();
   //  editor.focus();
  }

  render() {
    return (
      <div>
        <form onSubmit={this.handleSubmit}>
          <div className="row">
            <div className="col-xs-8">
              <div className="form-group">
                <input type="hidden" name="statement" />
                <div id="editor-container">
                  <div id="editor" style={{height: this.state.editorHeight}} ref={(c) => this._input = c}></div>
                </div>
              </div>
              <div className="form-group text-right">
                <div className="pull-left" style={{marginTop: "6px"}}>
                  <a href="" onClick={browserHistory.goBack}>Back</a>
                </div>
                <button onClick={this.runQuery} className="btn btn-info" style={{verticalAlign: "top"}}>Run</button>
              </div>
            </div>
            <div className="col-xs-4">
              <div className="form-group">
                <label htmlFor="name">Name</label>
                <input onChange={(e) => this.updateQuery({name: e.target.value})} id="name" type="text" className="form-control" />
              </div>
              <div className="form-group">
                <label htmlFor="description">Description</label>
                <textarea onChange={(e) => this.updateQuery({description: e.target.value})} id="description" placeholder="Optional" style={{height: "80px"}} className="form-control"></textarea>
              </div>
              <div className="text-right">
                <input type="submit" className="btn btn-success" value="Create" />
              </div>
            </div>
          </div>
        </form>
        <div id="results">
          {() => {
            if (this.state.loading) return <p className="text-muted">Loading...</p>
            if (this.state.result) return <div dangerouslySetInnerHTML={{__html: this.state.result}}></div>
            return null
          }()}
        </div>
      </div>
    )
  }

  getStatement() {
    const editor = this.editor;
    const selectedText = editor.getSelectedText();
    const text = selectedText.length < 10 ? editor.getValue() : selectedText;
    return text.replace(/\n/g, "\r\n");
  }

  runQuery(e) {
    e.preventDefault()
    console.log("run")

    this.setState({loading: true})

    // if (xhr) {
    //   xhr.abort();
    // }
    // var data = $.extend({}, params, {statement: getSQL(), data_source: $("#query_data_source").val()});

    let xhr = runQuery({statement: this.getStatement(), data_source: "main"}, (data) => {
      this.setState({loading: false, result: data});

      // error_line = getErrorLine();
      // if (error_line) {
      //   editor.getSession().addGutterDecoration(error_line - 1, "error");
      //   editor.scrollToLine(error_line, true, true, function () {});
      //   editor.gotoLine(error_line, 0, true);
      //   editor.focus();
      // }
    });
  }

  updateQuery(attributes) {
    this.setState({
      query: Object.assign({}, this.state.query, attributes)
    })
  }

  handleSubmit(e) {
    e.preventDefault()
    console.log("submit")
    let query = this.state.query
    query.statement = this.editor.getValue()
    console.log(query)

    $.post(Routes.blazer_queries_path(), {query: query}, function (data) {
      console.log(data);
      browserHistory.push(`/queries/${data.id}`);
    }.bind(this));
  }
}
