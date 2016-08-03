class QueriesShow extends React.Component {
  render() {
    const { query, variable_params, editable, error, success } = this.props

    return (
      <div>
        <div className="topbar">
          <div className="container">
            <div className="row" style={{paddingTop: "13px"}}>
              <div className="col-sm-9">
                <Nav queryId={query.id} />
                <h3>
                  {query.name}
                </h3>
              </div>
              <div className="col-sm-3 text-right">
                <a href={Routes.blazer_edit_query_path(query.id, variable_params)} className="btn btn-default" disabled={!editable}>Edit</a>
                {" "}
                <a href={Routes.blazer_new_query_path($.extend({}, variable_params, {fork_query_id: query.id, data_source: query.data_source, name: query.name}))} className="btn btn-info">Fork</a>
                {" "}
                {() => {
                  if (!error && success) {
                    // return <%= button_to "Download", run_queries_path(query_id: @query.id, format: "csv"), params: {statement: @statement}, class: "btn btn-primary" %>
                    return <input className="btn btn-primary" type="submit" value="Download" />
                  }
                }()}
              </div>
            </div>
          </div>
        </div>
        <div style={{marginBottom: "60px"}}></div>
      </div>
    )
  }
}
