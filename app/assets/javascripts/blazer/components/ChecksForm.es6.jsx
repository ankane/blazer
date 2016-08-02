class ChecksForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      check: {
        id: props.checkId
      }
    };
  }

  componentDidMount() {
    const checkId = this.state.check.id;
    if (checkId) {
      $.getJSON(Routes.blazer_check_path(checkId), (d) => {
        this.setState({check: d});
      })
    }
  }

  render() {
    const logChange = (val) => {
      // fix for possible bug with react-select
      if (val instanceof Array) {
        val = null;
      }

      this.setState({
        check: {
          ...this.state.check,
          query_id: val.value
        }
      });
    }

    const handleSubmit = (e) => {
      e.preventDefault();
      let check = this.state.check;
      console.log(check);

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
          console.log(data);
          browserHistory.push("/checks");
        }.bind(this)
      });
    }

    const handleEmailChange = (e) => {
      this.setState({
        check: {
          ...this.state.check,
          emails: e.target.value
        }
      });
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
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="check_query_id">Query</label>
            <div>
              <Select.Async
                name="check[query_id]"
                value={this.state.check.query_id}
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
            <input value={this.state.check.emails} onChange={handleEmailChange} placeholder="Optional, comma separated" className="form-control" type="text" name="check[emails]" id="check_emails" />
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
