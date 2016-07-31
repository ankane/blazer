class DashboardsIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      dashboards: []
    }
  }

  render() {
    return (
      <div>
        <p style={{float: "right"}}>
          <Link to="/dashboards/new" className="btn btn-info">New Dashboard</Link>
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
                    <td><Link to={"/dashboards/" + dashboard.id}>{dashboard.name}</Link></td>
                  </tr>
                );
            })}
          </tbody>
        </table>
      </div>
    );
  }

  componentDidMount() {
    document.title = "Dashboards";
    $.getJSON(Routes.blazer_dashboards_path(), function(data) {
      this.setState({dashboards: data});
    }.bind(this));
  }
}
