class QueriesShow extends React.Component {
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
          <pre>{query.statement}</pre>
          <div dangerouslySetInnerHTML={{__html: this.state.resultsHtml}}></div>
        </div>
      );
    }
    return false;
  }

  constructor(props) {
    super(props);
    this.state = {}
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

  componentWillUnmount() {
    this.serverRequest.abort();
  }
}
