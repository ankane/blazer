class ChecksForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  render() {
    const logChange = (val) => {
      console.log(val);

      // fix for possible bug with react-select
      if (val instanceof Array) {
        val = null;
      }

      this.setState({queryId: val});
    }

    const getOptions = (input) => {
      return fetch(Routes.blazer_queries_path())
        .then((response) => {
          return response.json();
        }).then((json) => {
          return {
            options: json.map((query, i) => {
              return {
                value: query.id,
                label: query.name
              };
            }),
            complete: true
          };
        });
    }
    return (
      <div>
        <form onSubmit={this.handleSubmit}>
          <div className="form-group">
            <label htmlFor="check_query_id">Query</label>
            <div>
              <Select.Async
                name="check[query_id]"
                value={this.state.queryId}
                loadOptions={getOptions}
                onChange={logChange}
                placeholder=""
                searchingText=""
                clearable={false}
              />
            </div>
          </div>
          <div className="form-group">
            <label htmlFor="check_emails">Emails</label>
            <input placeholder="Optional, comma separated" className="form-control" type="text" name="check[emails]" id="check_emails" />
          </div>
          <p className="text-muted">Emails are sent when a check starts failing, and when it starts passing again.</p>
          <p>
            <input type="submit" name="commit" value="Save" className="btn btn-success" />
          </p>
        </form>
      </div>
    );
  }

  handleSubmit(e) {
    e.preventDefault();
    var data = $(e.target).serialize();
    console.log(data);
    $.post(Routes.blazer_checks_path(), data, function (data) {
      console.log(data);
      browserHistory.push("/checks");
    }.bind(this));
  }
}
