class QueriesShow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      statementHeight: "100px"
    }
    this.expandStatement = this.expandStatement.bind(this)
  }

  render() {
    const id = parseInt(this.props.params.id);
    return (
      <div>
        <Nav />
        <h1>Query {id}</h1>
        <Link to="/">Home</Link>
        {this.renderDetails()}
      </div>
    );
  }

  renderDetails() {
    let query = this.state.query;
    if (query) {
      return (
        <div>
          <pre style={{maxHeight: this.state.statementHeight, overflow: "hidden"}} onClick={this.expandStatement}>
            <code>{query.statement}</code>
          </pre>
          <div dangerouslySetInnerHTML={{__html: this.state.resultsHtml}}></div>
        </div>
      );
    }
    return false;
  }

  expandStatement() {
    if (this.state.statementHeight === "100px") {
      this.setState({statementHeight: "none"})
    } else {
      this.setState({statementHeight: "100px"})
    }
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
    // const statement = this.state.query.statement
    // // console.log(statement)
    // if (statement && statement.length < 10000) {
    //   hljs.initHighlightingOnLoad();
    // }
  }

  componentWillUnmount() {
    this.serverRequest.abort();
  }
}
