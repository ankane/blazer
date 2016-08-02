class QueriesIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      queries: [],
      filteredQueries: [],
      dashboards: [],
      filteredDashboards: []
    }
    this.onChange = this.onChange.bind(this);
  }

  componentDidMount() {
    $.getJSON(Routes.blazer_queries_path(), function(data) {
      this.setState({queries: data, filteredQueries: data});
    }.bind(this));
    $.getJSON(Routes.blazer_dashboards_path(), function(data) {
      this.setState({dashboards: data, filteredDashboards: data});
    }.bind(this));
  }

  onChange(e) {
    const regexp = new RegExp(e.target.value, "i")
    this.setState({
      filteredQueries: this.state.queries.filter((q) => q.hide.match(regexp) || (q.creator || "").match(regexp)).slice(0, 100),
      filteredDashboards: this.state.dashboards.filter((q) => q.hide.match(regexp) || (q.creator || "").match(regexp)).slice(0, 100)
    })
  }

  render() {
    return <div id="queries">
      <div id="header" style={{marginBottom: "20px"}}>
        <div className="btn-group pull-right">
          <Link to="/queries/new" className="btn btn-info">New Query</Link>
          <button type="button" className="btn btn-info dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
            <span className="caret"></span>
            <span className="sr-only">Toggle Dropdown</span>
          </button>
          <ul className="dropdown-menu">
            <li><Link to="/dashboards">Dashboards</Link></li>
            <li><Link to="/checks">Checks</Link></li>
            <li role="separator" className="divider"></li>
            <li><Link to="/dashboards/new">New Dashboard</Link></li>
            <li><Link to="/checks/new">New Check</Link></li>
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
                      <Link to={"/dashboards/" + query.slug}>{query.name}</Link>
                    </strong>
                  </span>
                  {" "}
                  <span className="vars">{query.vars}</span>
                  <span className="hide">{query.hide}</span>
                </td>
                <td className="creator">{query.creator}</td>
              </tr>
            );
          })}
          {this.state.filteredQueries.map((query, i) => {
            return (
              <tr key={"q" + i}>
                <td>
                  <span className="name">
                    <Link to={"/queries/" + query.slug}>{query.name}</Link>
                  </span>
                  {" "}
                  <span className="vars">{query.vars}</span>
                  <span className="hide">{query.hide}</span>
                </td>
                <td className="creator">{query.creator}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>;
  }
}
