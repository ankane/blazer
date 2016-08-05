class DashboardsForm extends React.Component {
  constructor(props) {
    super(props)

    const queryIdOptions = props.queries.map((query) => {
      return {value: query.id, label: query.name}
    })

    this.state = {
      dashboard: {...this.props.dashboard},
      queryIdOptions,
      loading: false,
      errors: [],
      queries: []
    }
  }

  handleSubmit(e) {
    e.preventDefault()

    this.setState({loading: true})
  }

  render() {
    const { dashboard, queryIdOptions, loading } = this.state

    return (
      <div>
        <form onSubmit={this.handleSubmit.bind(this)}>
          <div className="form-group">
            <label htmlFor="name">Name</label>
            <input id="name" type="text" value={dashboard.name || ""} onChange={(e) => this.updateDashboard({name: e.target.value})} className="form-control" />
          </div>
          {this.renderCharts()}
          <div className="form-group">
            <label htmlFor="query_id">Add Chart</label>
            <Select
              name="query_id"
              value={null}
              placeholder="Select chart"
              options={queryIdOptions}
              onChange={(val) => this.addChart(val.value)}
              clearable={false}
            />
          </div>
          <p>
            <input type="submit" value="Save" className="btn btn-success" disabled={loading} />
          </p>
        </form>
      </div>
    )
  }

  renderCharts() {
    const { queries } = this.state

    if (queries.length > 0) {
      return (
        <div className="form-group">
          <label htmlFor="charts">Charts</label>
          <ul className="list-group">
            {queries.map((query, i) => {
              return <li key={i} className="list-group-item">{query}</li>
            })}
          </ul>
        </div>
      )
    }
  }

  addChart(val) {
    this.setState({
      queries: [...this.state.queries, val]
    })
  }

  updateDashboard(attributes) {
    this.setState({
      dashboard: {...this.state.dashboard, ...attributes}
    })
  }
}
