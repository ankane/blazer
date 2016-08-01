class ChecksIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      checks: []
    }
  }

  render() {
    return (
      <div>
        <p style={{float: "right"}}>
          <Link to="/checks/new" className="btn btn-info">New Check</Link>
        </p>
        <Nav />
        <table className="table">
          <thead>
            <tr>
              <th>Query</th>
              <th style={{width: "10%"}}>State</th>
              <th style={{width: "10%"}}>Run</th>
              <th style={{width: "20%"}}>Emails</th>
              <th style={{width: "15%"}}></th>
            </tr>
          </thead>
          <tbody>
            {this.state.checks.map(function(check, i){
              return (
                <tr key={i}>
                  <td>
                    <Link to={"/queries/" + check.query.id}>{check.query.name}</Link>
                    {" "}
                    <span className="text-muted">
                      {check.check_type ? check.check_type.replace("_", " ") : null}
                    </span>
                  </td>
                  <td>
                    <small className={"check-state " + check.state.toLowerCase().replace(" ", "_")}>{check.state.toUpperCase()}</small>
                  </td>
                  <td>
                    {check.schedule}
                  </td>
                  <td>
                    <ul className="list-unstyled" style={{marginBottom: 0}}>
                      {check.split_emails.map((email, i) => {
                        return (
                          <li key={i}>{email}</li>
                        );
                      })}
                    </ul>
                  </td>
                  <td style={{textAlign: "right", padding: "1px"}}>
                    <Link to={"/checks/" + check.id + "/edit"} className="btn btn-info">Edit</Link>
                    {" "}
                    <Link to={"/queries/" + check.query.id} className="btn btn-primary">Run Now</Link>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    );
  }

  componentDidMount() {
    document.title = "Checks";
    $.getJSON(Routes.blazer_checks_path(), function(data) {
      this.setState({checks: data});
    }.bind(this));
  }
}
