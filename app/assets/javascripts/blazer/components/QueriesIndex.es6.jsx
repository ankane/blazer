class QueriesIndex extends React.Component {
  render() {
    let renderQueries = this.state.queries.map( function (query) {
      return (
        <li key={query.id}>
          <Link to={"/queries/" + query.slug}>{query.name}</Link>
        </li>
      );
    });

    return (
      <div>
        <h1>Queries</h1>
        <Link to="/queries/new">New Query</Link>
        <Link to="/dashboards">Dashboards</Link>
        <Link to="/checks">Checks</Link>
        <Link to="/dashboards/new">New Dashboard</Link>
        <Link to="/checks/new">New Check</Link>
        <ul>
          {renderQueries}
        </ul>
      </div>
    );
  }

  constructor(props) {
    super(props);
    this.state = {
      queries: []
    }
  }

  componentDidMount() {
    $.getJSON("/queries", function(data) {
      this.setState({queries: data});
    }.bind(this));
  }
}
