class Nav extends React.Component {
  render() {
    return <div className="btn-group" style={{verticalAlign: "top", marginRight: "5px"}}>
      <a href={Routes.blazer_path()} className="btn btn-primary">Home</a>
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
        <li><a href={Routes.blazer_new_check_path()}>New Check</a></li>
      </ul>
    </div>;
  }
}
