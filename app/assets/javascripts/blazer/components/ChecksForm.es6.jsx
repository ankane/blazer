class ChecksForm extends React.Component {
  constructor(props) {
    super(props)

    // TODO move for performance
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
      scheduleOptions
    }
  }

  handleSubmit(e) {
    e.preventDefault()

    console.log(this.state.check)
  }

  render() {
    const { invert, errors } = this.props
    const { check, queryIdOptions, checkTypeOptions } = this.state

    return (
      <div>
        {this.renderErrors()}
        <form onSubmit={this.handleSubmit.bind(this)}>
          <div className="form-group">
            <label htmlFor="query_id">Query</label>
            <Select
              name="query_id"
              value={check.query_id}
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
            <input type="submit" value="Save" className="btn btn-success" />
          </p>
        </form>
      </div>
    )
  }

  renderErrors() {
    if (this.props.errors.length > 0) {
      return <div className="alert alert-danger">{this.props.errors[0]}</div>
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
