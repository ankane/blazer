class DashboardsIndex extends React.Component {
  render() {
    return (
      <div>
        <p style={{float: "right"}}>
          <Link to={Routes.blazer_new_dashboard_path()} className="btn btn-info">New Dashboard</Link>
        </p>
        <Nav />
        <table className="table">
          <thead>
            <tr>
              <th>Dashboard</th>
            </tr>
          </thead>
          <tbody>
            {this.state.dashboards.map(function(dashboard, i){
                return (
                  <tr key={i}>
                    <td><Link to={Routes.blazer_dashboard_path(dashboard.id)}>{dashboard.name}</Link></td>
                  </tr>
                );
            })}
          </tbody>
        </table>
      </div>
    );
  }

  constructor(props) {
    super(props);
    this.state = {
      dashboards: []
    }
  }

  componentDidMount() {
    document.title = "Dashboards";
    $.getJSON(Routes.blazer_dashboards_path(), function(data) {
      this.setState({dashboards: data});
    }.bind(this));
  }
}
