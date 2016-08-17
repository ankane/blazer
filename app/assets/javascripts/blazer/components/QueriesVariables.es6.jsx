class QueriesVariables extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      variables: props.variable_params
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
    const { bind_vars, smart_vars } = this.props
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
    const { bind_vars, onSubmit } = this.props

    // TODO datepicker
    if (bind_vars.length > 0) {
      return (
        <form onSubmit={this.handleSubmit.bind(this)} className="form-inline" style={{marginBottom: "10px"}}>
          {bind_vars.map((v, i) => {
            return (
              <span key={i}>
                <label htmlFor={v}>{v}</label>
                {" "}
                {this.renderVariableInput(v)}
                {" "}
              </span>
            )
          })}
          <input type="submit" className="btn btn-success" value="Run" style={{verticalAlign: "top"}} />
        </form>
      )
    } else {
      return null
    }
  }
}
