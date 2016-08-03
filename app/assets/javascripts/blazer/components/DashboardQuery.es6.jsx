class DashboardQuery extends React.Component {
  constructor(props) {
    super(props)
    this.state = {}
  }

  componentDidMount() {
    const { query } = this.props

    const data = {statement: query.statement, query_id: query.id, only_chart: true}

    runQuery(data, (results) => {
      this.setState({results: results})
    });
  }

  render() {
    const { query, variable_params } = this.props

    return (
      <div className="dashboard-query">
        <h4>
          <a href={Routes.blazer_query_path(query.id, variable_params)} target="_blank">{query.name}</a>
        </h4>
        <div className="chart">
          {this.renderResults()}
        </div>
      </div>
    )
  }

  renderResults() {
    if (this.state.results) {
      return <QueriesResult stickyHeaders={false} {...this.state.results} />
    } else {
      return <p className="text-muted">Loading...</p>
    }
  }
}
