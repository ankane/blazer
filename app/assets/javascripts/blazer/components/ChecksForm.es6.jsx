class ChecksForm extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      check: props.check
    }
  }

  render() {
    const { check, invert, errors } = this.props

    // TODO move for performance
    const queryIdOptions = this.props.queries.map((query) => {
      return {value: query.id, label: query.name}
    })

    const checkTypeOptions = [
      {value: "bad_data", label: "Any results (bad data)"},
      {value: "missing_data", label: "No results (missing data)"}
    ]
    if (this.props.anomaly_checks) {
      checkTypeOptions.push({value: "anomaly", label: "Anomaly (most recent data point)"})
    }

    return (
      <div>
        {this.renderErrors()}
        <form>
          <div className="form-group">
            <label htmlFor="query_id">Query</label>
            <Select
              name="query_id"
              value={this.state.check.query_id}
              options={queryIdOptions}
              onChange={(val) => this.updateCheck({query_id: val.value})}
              clearable={false}
            />
          </div>
          <div className="form-group">
            <label htmlFor="check_type">Alert if</label>
            <Select
              name="check_type"
              value={this.state.check.check_type || checkTypeOptions[0].value}
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
            <input type="text" name="emails" placeholder="Optional, comma separated" className="form-control" />
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
      const scheduleOptions = this.props.check_schedules.map((schedule) => {
        return {value: schedule, label: schedule}
      })

      return (
        <div className="form-group">
          <label htmlFor="schedule">Run every</label>
          <Select
            name="check_type"
            value={this.state.check.schedule || scheduleOptions[0].value}
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
