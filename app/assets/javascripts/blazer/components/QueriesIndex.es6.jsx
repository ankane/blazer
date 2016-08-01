class QueriesIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      queries: []
    }
  }

  componentDidMount() {
    $.getJSON(Routes.blazer_queries_path(), function(data) {
      this.setState({queries: data});
    }.bind(this));

    // const options = {
    //   valueNames: ["name", "vars", "hide", "creator"],
    //   item: "search-item",
    //   page: 200,
    //   indexAsync: true
    // };
    // let queryList = new List("queries", options, dashboardValues);
    // queryList.add(queryValues);

    // let queryIds = {};
    // for (var i = 0; i < queryValues.length; i++) {
    //   queryIds[queryValues[i].id] = true;
    // }
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
        <input type="text" placeholder="Start typing a query or person" style={{width: "300px", display: "inline-block"}} autoFocus="true" className="search form-control" />
      </div>
      <table className="table">
        <thead>
          <tr>
            <th>Name</th>
            <th style={{width: "20%", textAlign: "right"}}>Mastermind</th>
          </tr>
        </thead>
        <tbody className="list">
          {this.state.queries.map((query, i) => {
            return (
              <tr key={i}>
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
