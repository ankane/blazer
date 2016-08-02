class ChecksForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      check: {
        id: props.checkId
      },
      loaded: !props.checkId
    };
  }

  componentDidMount() {
    const checkId = this.state.check.id;
    if (checkId) {
      $.getJSON(Routes.blazer_check_path(checkId), (d) => {
        this.setState({check: d, loaded: true});
      })
    }
  }

  render() {
    if (!this.state.loaded) return null;

    const handleSubmit = (e) => {
      e.preventDefault();
      let check = this.state.check;

      let action, method;
      if (check.id) {
        action = Routes.blazer_check_path(check.id)
        method = "PUT"
      } else {
        action = Routes.blazer_checks_path()
        method = "POST"
      }

      $.ajax({
        url: action,
        method: method,
        data: {check: check},
        success: function (data) {
          browserHistory.push("/queries/" + check.query_id);
        }.bind(this)
      });
    }

    const updateCheck = (attributes) => {
      // fix for possible bug with react-select
      // if (val instanceof Array) val = null;

      this.setState({
        check: Object.assign({}, this.state.check, attributes)
      });
    }

    const getScheduleOptions = [
      {value: "1 day", label: "1 day"},
      {value: "1 hour", label: "1 hour"},
      {value: "5 minutes", label: "5 minutes"}
    ];

    const getCheckTypeOptions = [
      {label: "Any results (bad data)", value: "bad_data"},
      {label: "No results (missing data)", value: "missing_data"},
      {label: "Anomaly (most recent data point)", value: "anomaly"}
    ];

    const getOptions = (input) => {
      return fetch(Routes.blazer_queries_path())
        .then((response) => {
          return response.json();
        }).then((json) => {
          if (!this.state.check.query_id && json[0]) {
            this.setState({
              check: Object.assign({}, this.state.check, {query_id: json[0].id})
            });
          }
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
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="check_query_id">Query</label>
            <div>
              <Select.Async
                name="check[query_id]"
                value={this.state.check.query_id}
                loadOptions={getOptions}
                onChange={(val) => updateCheck({query_id: val.value})}
                placeholder=""
                searchingText=""
                searchable={false}
                clearable={false}
              />
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="check_check_type">Alert if</label>
            <Select
              name="check[check_type]"
              value={this.state.check.check_type || getCheckTypeOptions[0]}
              options={getCheckTypeOptions}
              onChange={(val) => updateCheck({check_type: val.value})}
              placeholder=""
              searchingText=""
              searchable={false}
              clearable={false}
            />
          </div>

          <div className="form-group">
            <label htmlFor="check_schedule">Run every</label>
            <Select
              name="check[schedule]"
              value={this.state.check.schedule || getScheduleOptions[0]}
              options={getScheduleOptions}
              onChange={(val) => updateCheck({schedule: val.value})}
              placeholder=""
              searchingText=""
              clearable={false}
            />
          </div>
          <div className="form-group">
            <label htmlFor="check_emails">Emails</label>
            <input value={this.state.check.emails || ""} onChange={(e) => updateCheck({emails: e.target.value})} placeholder="Optional, comma separated" className="form-control" type="text" name="check[emails]" id="check_emails" />
          </div>
          <p className="text-muted">Emails are sent when a check starts failing, and when it starts passing again.</p>
          <p>
            <input type="submit" name="commit" value="Save" className="btn btn-success" />
          </p>
        </form>
      </div>
    );
  }
}
