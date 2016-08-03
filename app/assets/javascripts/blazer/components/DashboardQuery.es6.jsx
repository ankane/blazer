class DashboardQuery extends React.Component {
  componentDidMount() {
//     var data = <%= blazer_json_escape({statement: query.statement, query_id: query.id, only_chart: true}.to_json).html_safe %>;

//     runQuery(data, function (data) {
//       $("#chart-<%= i %>").html(data);
//       $("#chart-<%= i %> table").stupidtable();
//     }, function (message) {
//       $("#chart-<%= i %>").css("color", "red").html(message);
//     });
  }

  render() {
    const { query, variable_params } = this.props

    return (
      <div className="dashboard-query">
        <h4>
          <a href={Routes.blazer_query_path(query.id, variable_params)} target="_blank">{query.name}</a>
        </h4>
        <div className="chart">
          <p className="text-muted">Loading...</p>
        </div>
      </div>
    )
  }
}
