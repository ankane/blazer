class Nav extends React.Component {
  render() {
    return <div className="btn-group" style={{verticalAlign: "top", marginRight: "10px"}}>
      <Link to="/" className="btn btn-primary">Home</Link>
      <button type="button" className="btn btn-primary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
        <span className="caret"></span>
        <span className="sr-only">Toggle Dropdown</span>
      </button>
      <ul className="dropdown-menu">
        <li><Link to="/dashboards">Dashboards</Link></li>
        <li><Link to="/checks">Checks</Link></li>
        <li role="separator" className="divider"></li>
        <li><Link to="/queries/new">New Query</Link></li>
        <li><Link to="/dashboards/new">New Dashboard</Link></li>
        <li><Link to="/checks/new">New Check</Link></li>
      </ul>
    </div>;
  }
}
