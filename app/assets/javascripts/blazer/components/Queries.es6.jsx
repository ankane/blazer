class Queries extends React.Component {
  render() {
    return <div id="queries">
      <div id="header" style={{marginBottom: "20px"}}>
        <div className="btn-group pull-right">
          <a href="<%= new_query_path %>" className="btn btn-info">New Query</a>
          <button type="button" className="btn btn-info dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
            <span className="caret"></span>
            <span className="sr-only">Toggle Dropdown</span>
          </button>
          <ul className="dropdown-menu">
            <li><a href="">Dashboards</a></li>
            <li><a href="">Checks</a></li>
            <li role="separator" className="divider"></li>
            <li><a href="">New Dashboard</a></li>
            <li><a href="">New Check</a></li>
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
          <tr id="search-item">
            <td>
              <span className="name"></span>
              {" "}
              <span className="vars"></span>
              <span className="hide"></span>
            </td>
            <td className="creator"></td>
          </tr>
        </tbody>
      </table>
    </div>;
  }
  componentDidMount() {
    const options = {
      valueNames: ["name", "vars", "hide", "creator"],
      item: "search-item",
      page: 200,
      indexAsync: true
    };
    let queryList = new List("queries", options, dashboardValues);
    queryList.add(queryValues);

    let queryIds = {};
    for (var i = 0; i < queryValues.length; i++) {
      queryIds[queryValues[i].id] = true;
    }
  }
}
