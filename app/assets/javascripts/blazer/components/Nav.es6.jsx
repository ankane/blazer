class Nav extends React.Component {
  render() {
    return <div className="btn-group" style={{verticalAlign: "top", marginRight: "5px"}}>
      <a href={Routes.blazer_path()} className="btn btn-primary">Home</a>
      <button type="button" className="btn btn-primary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
        <span className="caret"></span>
        <span className="sr-only">Toggle Dropdown</span>
      </button>
      <ul className="dropdown-menu">
        <li><Link to={Routes.blazer_dashboards_path()}>Dashboards</Link></li>
        <li><Link to={Routes.blazer_checks_path()}>Checks</Link></li>
        <li role="separator" className="divider"></li>
        <li><Link to={Routes.blazer_new_query_path()}>New Query</Link></li>
        <li><Link to={Routes.blazer_new_dashboard_path()}>New Dashboard</Link></li>
        <li><Link to={Routes.blazer_new_check_path()}>New Check</Link></li>
      </ul>
    </div>;
  }
}
