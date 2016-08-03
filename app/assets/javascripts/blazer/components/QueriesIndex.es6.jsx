class QueriesIndex extends React.Component {
  constructor(props) {
    super(props)

    this.addSearchStr(props.queries)
    this.addSearchStr(props.dashboards)

    this.state = {
      queries: props.queries,
      filteredQueries: props.queries,
      dashboards: props.dashboards,
      filteredDashboards: props.dashboards
    }
    this.onChange = this.onChange.bind(this)
  }

  addSearchStr(arr) {
    arr.forEach(function (q) {
      q.searchStr = `${q.name.replace(/\s+/g, "")} ${(q.creator || "").replace(/\s+/g, "")}`
    })
  }

  onChange(e) {
    const regexp = new RegExp(e.target.value, "i")
    this.setState({
      filteredQueries: this.state.queries.filter((q) => q.searchStr.match(regexp)).slice(0, 100),
      filteredDashboards: this.state.dashboards.filter((q) => q.searchStr.match(regexp)).slice(0, 100)
    })
  }

  render() {
    return (
      <div id="queries">
        <div id="header" style={{marginBottom: "20px"}}>
          <div className="btn-group pull-right">
            <a href={Routes.blazer_new_query_path()} className="btn btn-info">New Query</a>
            <button type="button" className="btn btn-info dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
              <span className="caret"></span>
              <span className="sr-only">Toggle Dropdown</span>
            </button>
            <ul className="dropdown-menu">
              <li><a href={Routes.blazer_dashboards_path()}>Dashboards</a></li>
              <li><a href={Routes.blazer_checks_path()}>Checks</a></li>
              <li role="separator" className="divider"></li>
              <li><a href={Routes.blazer_new_dashboard_path()}>New Dashboard</a></li>
              <li><a href={Routes.blazer_new_check_path()}>New Check</a></li>
            </ul>
          </div>
          <input onChange={this.onChange} type="text" placeholder="Start typing a query or person" style={{width: "300px", display: "inline-block"}} autoFocus="true" className="search form-control" />
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th style={{width: "20%", textAlign: "right"}}>Mastermind</th>
            </tr>
          </thead>
          <tbody className="list">
            {this.state.filteredDashboards.map((query, i) => {
              return (
                <tr key={"d" + i}>
                  <td>
                    <span className="name">
                      <strong>
                        <a href={Routes.blazer_dashboard_path(query.slug)}>{query.name}</a>
                      </strong>
                    </span>
                    {" "}
                    <span className="vars">{query.vars}</span>
                  </td>
                  <td className="creator">{query.creator}</td>
                </tr>
              )
            })}
            {this.state.filteredQueries.map((query, i) => {
              return (
                <tr key={"q" + i}>
                  <td>
                    <span className="name">
                      <a href={Routes.blazer_query_path(query.slug)}>{query.name}</a>
                    </span>
                    {" "}
                    <span className="vars">{query.vars}</span>
                  </td>
                  <td className="creator">{query.creator}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    )
  }
}
