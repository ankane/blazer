class DashboardsShow extends React.Component {
  constructor(props) {
    super(props)
    this.handleSubmit = this.handleSubmit.bind(this)
  }

  render() {
    const { dashboard, queries, variable_params } = this.props

    return (
      <div>
        <div className="topbar">
          <div className="container">
            <div className="row" style={{paddingTop: "13px"}}>
              <div className="col-sm-9">
                <Nav />
                <h3>{dashboard.name}</h3>
              </div>
              <div className="col-sm-3 text-right">
                <a href={Routes.blazer_edit_dashboard_path(dashboard, variable_params)} className="btn btn-info">Edit</a>
              </div>
            </div>
          </div>
        </div>
        <div style={{marginBottom: "60px"}}></div>
        {this.renderRefresh()}
        <QueriesVariables onSubmit={this.handleSubmit} {...this.props} />
        {queries.map((query, i) => {
          return <DashboardQuery key={i} query={query} variable_params={variable_params} />
        })}
      </div>
    )
  }

  renderRefresh() {
    const { dashboard, variable_params, cached } = this.props

    if (cached) {
      return (
        <p className="text-muted" style={{float: "right"}}>
          Some queries may be cached
          {" "}
          <a href={Routes.blazer_refresh_dashboard_path(dashboard, variable_params)} data-method="post">Refresh</a>
        </p>
      )
    }
  }

  handleSubmit(variables) {
    window.location.href = Routes.blazer_dashboard_path(this.props.dashboard, variables)
  }
}
