class QueriesShow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      statementHeight: "236px"
    }
    this.expandStatement = this.expandStatement.bind(this)
  }

  render() {
    // const id = parseInt(this.props.params.id);
    const query = this.state.query
    if (!query) return null

    return (
      <div>
        <div style={{position: "fixed", top: 0, left: 0, right: 0, backgroundColor: "whitesmoke", height: "60px", zIndex: 1001}}>
          <div className="container">
            <div className="row" style={{paddingTop: "13px"}}>
              <div className="col-sm-9">
                <Nav />
                <h3 style={{margin: 0, lineHeight: "34px", display: "inline"}}>
                  {query.name}
                </h3>
              </div>
              <div className="col-sm-3 text-right">
                <Link to={`/queries/${query.id}/edit`} className="btn btn-default" disabled={false}>Edit</Link>
                {" "}
                <Link to="/queries/new" className="btn btn-info">Fork</Link>
              </div>
            </div>
          </div>
        </div>
        <div style={{marginBottom: "60px"}}></div>
        <pre style={{maxHeight: this.state.statementHeight, overflow: "hidden"}} onClick={this.expandStatement}>
          <code ref={(c) => this._block = c}>{query.statement}</code>
        </pre>
        <div dangerouslySetInnerHTML={{__html: this.state.resultsHtml}}></div>
      </div>
    );
  }

  expandStatement() {
    this.setState({statementHeight: "none"})
  }

  run(query) {
    let data = $.extend(
      {},
      {
        statement: query.statement,
        query_id: query.id
      }
    );

    runQuery(data, (d) => {
      this.setState({resultsHtml: d});
    }, (error) => {
      console.log("Error", error)
    });
  }

  componentDidMount() {
    this.serverRequest = $.getJSON(Routes.blazer_query_path(this.props.params.id), (query) => {
      this.setState({query: query});
      this.run(query);
    })
  }

  componentDidUpdate() {
    const statement = this.state.query.statement
    if (statement && statement.length < 10000) {
      hljs.highlightBlock(this._block);
    }
  }

  componentWillUnmount() {
    this.serverRequest.abort();
  }
}
