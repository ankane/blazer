class Nav extends React.Component {
  render() {
    let checkParams = {}
    if (this.props.queryId) checkParams.query_id = this.props.queryId

    return (
      <div className="btn-group" style={{verticalAlign: "top", marginRight: "10px"}}>
      <a href={Routes.blazer_root_path()} className="btn btn-primary">Home</a>
        <button type="button" className="btn btn-primary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
          <span className="caret"></span>
          <span className="sr-only">Toggle Dropdown</span>
        </button>
        <ul className="dropdown-menu">
          <li><a href={Routes.blazer_dashboards_path()}>Dashboards</a></li>
          <li><a href={Routes.blazer_checks_path()}>Checks</a></li>
          <li role="separator" className="divider"></li>
          <li><a href={Routes.blazer_new_query_path()}>New Query</a></li>
          <li><a href={Routes.blazer_new_dashboard_path()}>New Dashboard</a></li>
          <li><a href={Routes.blazer_new_check_path(checkParams)}>New Check</a></li>
        </ul>
      </div>
    )
  }
}
