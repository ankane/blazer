class DashboardsForm extends React.Component {
  constructor(props) {
    super(props)

    const queryIdOptions = props.queries.map((query) => {
      return {value: query.id, label: query.name}
    })

    this.state = {
      dashboard: {...this.props.dashboard},
      queryIdOptions,
      loading: false,
      errors: [],
      queries: [...this.props.dashboard_queries]
    }
  }

  handleSubmit(e) {
    e.preventDefault()

    this.setState({loading: true})

    let {id, ...data} = this.state.dashboard;
    let queryIds = this._sortable.toArray()

    let method, url
    if (id) {
      method = "PUT"
      url = Routes.blazer_dashboard_path(id)
    } else {
      method = "POST"
      url = Routes.blazer_dashboards_path()
    }

    var jqxhr = $.ajax({
      method: method,
      url: url,
      data: {dashboard: data, query_ids: queryIds},
      dataType: "json"
    }).done((data) => {
      window.location.href = Routes.blazer_dashboard_path(data.id)
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
    const { dashboard, queryIdOptions, loading } = this.state

    return (
      <div>
       {this.renderErrors()}
        <form onSubmit={this.handleSubmit.bind(this)}>
          <div className="form-group">
            <label htmlFor="name">Name</label>
            <input id="name" type="text" value={dashboard.name || ""} onChange={(e) => this.updateDashboard({name: e.target.value})} className="form-control" />
          </div>
          {this.renderCharts()}
          <div className="form-group">
            <label htmlFor="query_id">Add Chart</label>
            <Select
              name="query_id"
              value={null}
              placeholder="Select chart"
              options={queryIdOptions}
              onChange={(val) => this.addChart(val)}
              clearable={false}
              autoBlur={true}
            />
          </div>
          <p>
            {this.renderDelete()}
            {" "}
            <input type="submit" value="Save" className="btn btn-success" disabled={loading} />
          </p>
        </form>
      </div>
    )
  }

  renderDelete() {
    const { dashboard, loading } = this.state
    if (dashboard.id) {
      return <button onClick={this.handleDelete.bind(this)} className="btn btn-danger" disabled={loading}>Delete</button>
    }
  }

  handleDelete(e) {
    e.preventDefault()

    if (confirm("Are you sure?")) {
      this.setState({loading: true})

      const { dashboard } = this.state

      $.ajax({
        method: "DELETE",
        url: Routes.blazer_dashboard_path(dashboard.id),
        dataType: "json"
      }).done((data) => {
        window.location.href = Routes.blazer_dashboards_path()
      })
    }
  }

  renderErrors() {
    if (this.state.errors.length > 0) {
      return <div className="alert alert-danger">{this.state.errors[0]}</div>
    }
  }

  sortableGroupDecorator(componentBackingInstance) {
    // check if backing instance not null
    if (componentBackingInstance) {
      let options = {
        draggable: "li",
        filter: ".glyphicon-remove",
        onFilter: (evt) => {
          let item = evt.item, ctrl = evt.target
          if (Sortable.utils.is(ctrl, ".glyphicon-remove")) {
            item.parentNode.removeChild(item)
          }
        }
      }
      this._sortable = Sortable.create(componentBackingInstance, options)
    }
  }

  renderCharts() {
    const { queries } = this.state

    if (queries.length > 0) {
      return (
        <div className="form-group">
          <label htmlFor="charts">Charts</label>
          <ul className="list-group" ref={this.sortableGroupDecorator.bind(this)}>
            {queries.map((query, i) => {
              return (
                <li key={i} data-id={query.id} className="list-group-item">
                  <span className="glyphicon glyphicon-remove" aria-hidden={true}></span>
                  {query.name}
                </li>
              )
            })}
          </ul>
        </div>
      )
    }
  }

  addChart(val) {
    this.setState({
      queries: [...this.state.queries, {id: val.value, name: val.label}]
    })
  }

  removeQuery(i) {
    this.setState({
      queries: [
        ...this.state.queries.slice(0, i),
        ...this.state.queries.slice(i + 1)
      ]
    })
  }

  updateDashboard(attributes) {
    this.setState({
      dashboard: {...this.state.dashboard, ...attributes}
    })
  }
}
