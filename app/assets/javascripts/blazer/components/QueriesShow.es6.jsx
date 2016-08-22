class QueriesShow extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      statementHeight: "236px",
      variables: props.variable_params
    }
    this.expandStatement = this.expandStatement.bind(this)
    this.handleSubmit = this.handleSubmit.bind(this)
  }

  componentDidMount() {
    const { query, variable_params, success, statement } = this.props

    if (success) {
      const showRun = (data) => {
        this.setState({results: data})
      }

      const showError = (message) => {
        this.setState({errorMessage: message})
      }

      let data = $.extend({}, variable_params, {statement: statement, query_id: query.id})
      runQuery(data, showRun, showError);
    }

    const sqlAdapter = this.props.adapter === "sql" || this.props.adapter === "presto"
    if (this.props.statement.length < 10000 && sqlAdapter) {
      hljs.highlightBlock(this._code);
    }
  }

  expandStatement() {
    this.setState({statementHeight: "none"})
  }

  render() {
    const { query, variable_params, editable, error, success, statement } = this.props
    const authenticityToken = $("meta[name=csrf-token]").attr("content")

    return (
      <div>
        <div className="topbar">
          <div className="container">
            <div className="row" style={{paddingTop: "13px"}}>
              <div className="col-sm-9">
                <Nav queryId={query.id} />
                <h3>
                  {query.name}
                </h3>
              </div>
              <div className="col-sm-3 text-right">
                <a href={Routes.blazer_edit_query_path(query, variable_params)} className="btn btn-default" disabled={!editable}>Edit</a>
                {" "}
                <a href={Routes.blazer_new_query_path($.extend({}, variable_params, {fork_query_id: query.id, data_source: query.data_source, name: query.name}))} className="btn btn-info">Fork</a>
                {" "}
                {() => {
                  if (!error && success) {
                    return <form method="post" action={Routes.blazer_run_queries_path({query_id: query.id, format: "csv"})} style={{display: "inline"}}>
                      <input type="hidden" name="authenticity_token" value={authenticityToken} />
                      <input type="hidden" name="statement" value={statement} />
                      <input className="btn btn-primary" type="submit" value="Download" />
                    </form>
                  }
                }()}
              </div>
            </div>
          </div>
        </div>
        <div style={{marginBottom: "60px"}}></div>
        {this.renderSqlErrors()}
        {this.renderDescription()}
        <QueriesVariables onSubmit={this.handleSubmit} runButton={true} {...this.props} />
        <pre style={{maxHeight: this.state.statementHeight, overflow: "hidden"}} onClick={this.expandStatement}>
          <code ref={(n) => this._code = n}>{statement}</code>
        </pre>
        <div id="results">
          {this.renderResults()}
        </div>
      </div>
    )
  }

  renderDescription() {
    const query = this.props.query
    if ((query.description || "").length > 0) {
      return <p>{query.description}</p>
    }
  }

  renderResults() {
    if (this.state.results) {
      return <QueriesResult query={this.props.query} variable_params={this.props.variable_params} stickyHeaders={true} {...this.state.results} />
    } else if (this.state.errorMessage) {
      return <p style={{color: "red"}}>{this.state.errorMessage}</p>
    } else if (this.props.success) {
      return <p className="text-muted">Loading...</p>
    }
  }

  renderSqlErrors() {
    if (this.props.sql_errors.length > 0) {
      return (
        <div className="alert alert-danger">
          <ul>
            {this.props.sql_errors.map((message, i) => {
              return <li key={i}>{message}</li>
            })}
          </ul>
        </div>
      )
    }
  }

  handleSubmit(variables) {
    window.location.href = Routes.blazer_query_path(this.props.query, variables)
  }
}
