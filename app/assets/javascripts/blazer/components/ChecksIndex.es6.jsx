class ChecksIndex extends React.Component {
  render() {
    const { checks } = this.props

    return (
      <div>
        <p style={{float: "right"}}>
          <a href={Routes.blazer_new_check_path()} className="btn btn-info">New Check</a>
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
            {checks.map((check, i) => {
              return (
                <tr key={i}>
                  <td>
                    <a href={Routes.blazer_query_path(check.query)}>{check.query.name}</a>
                    {" "}
                    <span className="text-muted">{(check.check_type || "").replace("_", " ")}</span>
                  </td>
                  <td>
                    <small className={`check-state ${(check.state || "").replace("_", " ")}`}>{(check.state || "").toUpperCase()}</small>
                  </td>
                  <td>
                    {check.schedule}
                  </td>
                  <td>
                    <ul className="list-unstyled" style={{marginBottom: 0}}>
                      {check.split_emails.map((email, i) => {
                        return <li key={i}>{email}</li>
                      })}
                    </ul>
                  </td>
                  <td style={{textAlign: "right", padding: "1px"}}>
                    <a href={Routes.blazer_edit_check_path(check.id)} className="btn btn-info">Edit</a>
                    {" "}
                    <a href={Routes.blazer_query_path(check.query.id)} className="btn btn-primary" target="_blank">Run Now</a>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    )
  }
}
