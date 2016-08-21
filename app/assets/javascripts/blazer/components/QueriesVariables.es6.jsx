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
    const { dateVars } = this.state

    if (dateVars) {
      return (
        <div>
          <label>start_time & end_time</label>
          <div className="selectize-control single" style={{width: "300px"}}>
            <div id="reportrange" className="selectize-input" style={{display: "inline-block"}}>
              <span>Select a time range</span>
            </div>
          </div>
        </div>
      )
    }
  }

  renderRun() {
    if (this.props.runButton) {
      return  <input type="submit" className="btn btn-success" value="Run" style={{verticalAlign: "top"}} />
    }
  }
}
