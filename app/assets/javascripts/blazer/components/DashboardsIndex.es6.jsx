class DashboardsIndex extends React.Component {
  render() {
    const { dashboards } = this.props

    return (
      <div>
        <p style={{float: "right"}}>
          <a href={Routes.blazer_new_dashboard_path()} className="btn btn-info">New Dashboard</a>
        </p>
        <Nav />

        <table className="table">
          <thead>
            <tr>
              <th>Dashboard</th>
            </tr>
          </thead>
          <tbody>
            {dashboards.map((dashboard, i) => {
              return <tr key={i}><td><a href={Routes.blazer_dashboard_path(dashboard.id)}>{dashboard.name}</a></td></tr>
            })}
          </tbody>
        </table>
      </div>
    )
  }
}
