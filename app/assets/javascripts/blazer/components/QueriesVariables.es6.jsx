class QueriesVariables extends React.Component {
  constructor(props) {
    super(props)

    let dateVars, bindVars
    if (props.bind_vars.indexOf("start_time") !== -1 && props.bind_vars.indexOf("end_time") !== -1) {
      dateVars = true
      bindVars = _.difference(props.bind_vars, ["start_time", "end_time"])
    } else {
      dateVars = false
      bindVars = props.bind_vars
    }

    this.state = {
      variables: props.variable_params,
      dateVars: dateVars,
      bindVars: bindVars
    }
  }

  componentDidMount() {
    if (this._dateRangePicker) {
      const timeZone = gon.time_zone
      const format = "YYYY-MM-DD"
      const now = moment.tz(timeZone)

      const dateStr = (daysAgo) => {
        return now.clone().subtract(daysAgo || 0, "days").format(format)
      }

      const toDate = (time) => {
        return moment.tz(time.format(format), timeZone)
      }

      const updateStartTime = (time) => {
        this.updateVariables({start_time: toDate(time).utc().format()})
      }

      const updateEndTime = (time) => {
        this.updateVariables({end_time: toDate(time).endOf("day").utc().format()})
      }

      const onSubmit = (startTime, endTime) => {
        this.updateVariables({
          start_time: toDate(startTime).utc().format(),
          end_time: toDate(endTime).endOf("day").utc().format()
        })
      }

      let { start_time, end_time } = this.state.variables
      let submit = false

      if (start_time) {
        start_time = moment(start_time).tz(timeZone).format(format)
      } else {
        start_time = dateStr(29)
        submit = true
      }

      if (end_time) {
        end_time = moment(end_time).tz(timeZone).format(format)
      } else {
        end_time = dateStr()
        submit = true
      }

      if (submit) {
        onSubmit(moment(start_time), moment(end_time))
      }

      $(this._dateRangePicker).daterangepicker(
        {
          ranges: {
           "Today": [dateStr(), dateStr()],
           "Last 7 Days": [dateStr(6), dateStr()],
           "Last 30 Days": [dateStr(29), dateStr()]
          },
          locale: {
            format: format
          },
          startDate: start_time,
          endDate: end_time,
          opens: "right"
        },
        onSubmit
      )

      let picker = $(this._dateRangePicker).data('daterangepicker');
      $(this._dateRangePicker).trigger('apply.daterangepicker', picker);
    }
  }

  updateVariables(attributes) {
    this.setState({
      variables: {
        ...this.state.variables,
        ...attributes
      }
    }, () => {
      let submit = true
      this.props.bind_vars.forEach((v) => {
        if (!this.state.variables[v]) {
          submit = false
        }
      })

      if (submit) {
        this.handleSubmit()
      }
    })
  }

  renderVariableInput(v) {
    const { smart_vars } = this.props
    const { variables } = this.state

    if (smart_vars[v]) {
      return <div className="boom">
        <Select
        value={"" + variables[v]}
        options={smart_vars[v].map((sv) => {
          return {
            label: sv[0],
            value: "" + sv[1]
          }
        })}
        onChange={(val) => {
          let attributes = {}
          attributes[v] = val.value
          this.updateVariables(attributes)
        }}
        clearable={false}
        searchable={false}
        backspaceRemoves={false}
        autoBlur={true}
      />
      </div>
    } else {
      return <input id={v} defaultValue={variables[v] || ""} onBlur={(e) => {
          let attributes = {}
          attributes[v] = e.target.value
          this.updateVariables(attributes)
        }} type="text" className="form-control" />
    }
  }

  handleSubmit(e) {
    if (e) {
      e.preventDefault()
    }

    this.props.onSubmit(this.state.variables)
  }

  render() {
    const { onSubmit } = this.props
    const { bindVars, dateVars } = this.state

    // TODO datepicker
    if (bindVars.length > 0 || dateVars) {
      return (
        <form onSubmit={this.handleSubmit.bind(this)} className="form-inline" style={{marginBottom: "10px"}}>
          {bindVars.map((v, i) => {
            return (
              <span key={i}>
                <label htmlFor={v}>{v}</label>
                {" "}
                {this.renderVariableInput(v)}
                {" "}
              </span>
            )
          })}
          {this.renderDateVars()}
          {this.renderRun()}
        </form>
      )
    } else {
      return null
    }
  }

  renderDateVars() {
    const { dateVars, variables } = this.state

    if (dateVars) {
      return (
        <span>
          <label>start_time & end_time</label>
          {" "}
          <div className="boom" style={{width: "auto"}}>
            <div className="Select Select--single has-value" style={{width: "300px", display: "inline-block"}}>
              <div ref={(c) => this._dateRangePicker = c} className="Select-control">
                <span className="Select-multi-value-wrapper">
                  <div className="Select-value">
                    <span className="Select-value-label">
                      {moment(variables.start_time).tz(gon.time_zone).format("MMMM D, YYYY")}
                      {" - "}
                      {moment(variables.end_time).tz(gon.time_zone).format("MMMM D, YYYY")}
                    </span>
                  </div>
                </span>
                <span className="Select-arrow-zone"><span className="Select-arrow"></span></span>
              </div>
            </div>
          </div>
          {" "}
        </span>
      )
    }
  }

  renderRun() {
    if (this.props.runButton) {
      return  <input type="submit" className="btn btn-success" value="Run" style={{verticalAlign: "top"}} />
    }
  }
}
