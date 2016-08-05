class ChecksForm extends React.Component {
  constructor(props) {
    super(props)

    const queryIdOptions = props.queries.map((query) => {
      return {value: query.id, label: query.name}
    })

    const checkTypeOptions = [
      {value: "bad_data", label: "Any results (bad data)"},
      {value: "missing_data", label: "No results (missing data)"}
    ]
    if (props.anomaly_checks) {
      checkTypeOptions.push({value: "anomaly", label: "Anomaly (most recent data point)"})
    }

    check = {...props.check}
    check.check_type = check.check_type || checkTypeOptions[0].value

    let scheduleOptions
    if (props.check_schedules) {
      scheduleOptions = props.check_schedules.map((schedule) => {
        return {value: schedule, label: schedule}
      })
      check.schedule = check.schedule || scheduleOptions[0].value
    }

    this.state = {
      check,
      queryIdOptions,
      checkTypeOptions,
      scheduleOptions,
      loading: false,
      errors: []
    }
  }

  handleSubmit(e) {
    e.preventDefault()

    this.setState({loading: true})
    let {id, ...data} = this.state.check;

    let method, url
    if (id) {
      method = "PUT"
      url = Routes.blazer_check_path(id)
    } else {
      method = "POST"
      url = Routes.blazer_checks_path()
    }

    var jqxhr = $.ajax({
      method: method,
      url: url,
      data: {check: data},
      dataType: "json"
    }).done((data) => {
      window.location.href = Routes.blazer_query_path(data.query_id)
    }).fail((xhr) => {
      let json
      try {
        json =  $.parseJSON(xhr.responseText)
      } catch (err) {
        json = {errors: [xhr.statusText]}
      }
      this.setState({errors: json.errors, loading: false})
    })
  }

  render() {
    const { invert, errors } = this.props
    const { check, queryIdOptions, checkTypeOptions, loading } = this.state

    return (
      <div>
        {this.renderErrors()}
        <form onSubmit={this.handleSubmit.bind(this)}>
          <div className="form-group">
            <label htmlFor="query_id">Query</label>
            <Select
              name="query_id"
              value={check.query_id}
              placeholder="Select query"
              options={queryIdOptions}
              onChange={(val) => this.updateCheck({query_id: val.value})}
              clearable={false}
            />
          </div>
          <div className="form-group">
            <label htmlFor="check_type">Alert if</label>
            <Select
              name="check_type"
              value={check.check_type}
              options={checkTypeOptions}
              onChange={(val) => this.updateCheck({check_type: val.value})}
              clearable={false}
              searchable={false}
              backspaceRemoves={false}
            />
          </div>
          {this.renderSchedule()}
          <div className="form-group">
            <label htmlFor="emails">Emails</label>
            <input type="text" value={check.emails || ""} onChange={(e) => this.updateCheck({emails: e.target.value})} name="emails" placeholder="Optional, comma separated" className="form-control" />
          </div>
          <p className="text-muted">Emails are sent when a check starts failing, and when it starts passing again.</p>
          <p>
            <input type="submit" value="Save" className="btn btn-success" disabled={loading} />
          </p>
        </form>
      </div>
    )
  }

  renderErrors() {
    if (this.state.errors.length > 0) {
      return <div className="alert alert-danger">{this.state.errors[0]}</div>
    }
  }

  renderSchedule() {
    if (this.props.check_schedules) {
      const { scheduleOptions } = this.state

      return (
        <div className="form-group">
          <label htmlFor="schedule">Run every</label>
          <Select
            name="check_type"
            value={this.state.check.schedule}
            options={scheduleOptions}
            onChange={(val) => this.updateCheck({schedule: val.value})}
            clearable={false}
            searchable={false}
            backspaceRemoves={false}
          />
        </div>
      )
    }
  }

  updateCheck(attributes) {
    this.setState({
      check: {
        ...this.state.check,
        ...attributes
      }
    })
  }
}
