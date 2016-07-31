class QueriesShow extends React.Component {
  renderDownloadButton() {
    if (!this.props.error && this.props.success) {
      return (
        false
      );
    } else {
      return (
        false
      );
    }
  }

  showStatement(e) {
    e.target.style.maxHeight = 'none';
  }

  renderResults() {
    if (this.props.success) {
      return (
        <div id="results">
          <p className="text-muted">Loading...</p>
        </div>
      );
    }
    return false;
  }

  render() {
    let forkParams = $.extend({}, this.props.variable_params, {fork_query_id: this.props.query.id, data_source: this.props.query.data_source, name: this.props.query.name});
    return (
      <div>
        <div style={{position: "fixed", top: 0, left: 0, right: 0, backgroundColor: "whitesmoke", height: "60px", zIndex: 1001}}>
          <div className="container">
            <div className="row" style={{paddingTop: "13px"}}>
              <div className="col-sm-9">
                <Nav />
                <h3 style={{margin: 0, lineHeight: "34px", display: "inline"}}>
                  {this.props.query.name}
                </h3>
              </div>
              <div className="col-sm-3 text-right">
                <a href={Routes.blazer_edit_query_path(this.props.query, this.props.variable_params)} className="btn btn-default" disabled={!this.props.editable}>Edit</a>
                {" "}
                <a href={Routes.blazer_new_query_path(forkParams)} className="btn btn-info">Fork</a>
                {this.renderDownloadButton()}
              </div>
            </div>
          </div>
        </div>
        <div style={{marginBottom: "60px"}}></div>
        <pre style={{maxHeight: "236px", overflow: "hidden"}} onClick={this.showStatement}>
          <code>{this.props.statement}</code>
        </pre>
        {this.renderResults()}
      </div>
    );
  }

  componentDidMount() {
    if (this.props.adapter === "sql" || this.props.adapter === "presto") {
      if ($("code").text().length < 10000) {
        hljs.initHighlightingOnLoad();
      }
    }

    function showRun(data) {
      $("#results").html(data);
      $("#results table").stupidtable().stickyTableHeaders({fixedOffset: 60});
    }

    function showError(message) {
      $("#results").css("color", "red").html(message);
    }

    var data = $.extend(
      {},
      this.props.variable_params,
      {
        statement: this.props.statement,
        query_id: this.props.query.id
      }
    );

    runQuery(data, showRun, showError);
  }
}
