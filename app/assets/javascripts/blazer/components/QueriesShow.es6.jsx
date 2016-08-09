class QueriesShow extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      statementHeight: "236px",
      variables: props.variable_params
    }
    this.expandStatement = this.expandStatement.bind(this)
  }

  componentDidMount() {
    const { query, variable_params, success, statement } = this.props

    if (success) {
      const showRun = (data) => {
        this.setState({results: data})
      }

      const showError = (message) => {
        this.setState({errorMessage: message})
      }

      let data = $.extend({}, variable_params, {statement: statement, query_id: query.id})
      runQuery(data, showRun, showError);
    }

    const sqlAdapter = this.props.adapter === "sql" || this.props.adapter === "presto"
    if (this.props.statement.length < 10000 && sqlAdapter) {
      hljs.highlightBlock(this._code);
    }
  }

  expandStatement() {
    this.setState({statementHeight: "none"})
  }

  render() {
    const { query, variable_params, editable, error, success, statement } = this.props

    return (
      <div>
        <div className="topbar">
          <div className="container">
            <div className="row" style={{paddingTop: "13px"}}>
              <div className="col-sm-9">
                <Nav queryId={query.id} />
                <h3>
                  {query.name}
                </h3>
              </div>
              <div className="col-sm-3 text-right">
                <a href={Routes.blazer_edit_query_path(query.id, variable_params)} className="btn btn-default" disabled={!editable}>Edit</a>
                {" "}
                <a href={Routes.blazer_new_query_path($.extend({}, variable_params, {fork_query_id: query.id, data_source: query.data_source, name: query.name}))} className="btn btn-info">Fork</a>
                {" "}
                {() => {
                  if (!error && success) {
                    // return <%= button_to "Download", run_queries_path(query_id: @query.id, format: "csv"), params: {statement: @statement}, class: "btn btn-primary" %>
                    return <input className="btn btn-primary" type="submit" value="Download" />
                  }
                }()}
              </div>
            </div>
          </div>
        </div>
        <div style={{marginBottom: "60px"}}></div>
        {this.renderSqlErrors()}
        {this.renderDescription()}
        {this.renderVariables()}
        <pre style={{maxHeight: this.state.statementHeight, overflow: "hidden"}} onClick={this.expandStatement}>
          <code ref={(n) => this._code = n}>{statement}</code>
        </pre>
        <div id="results">
          {this.renderResults()}
        </div>
      </div>
    )
  }

  renderDescription() {
    const query = this.props.query
    if ((query.description || "").length > 0) {
      return <p>{query.description}</p>
    }
  }

  renderResults() {
    if (this.state.results) {
      return <QueriesResult stickyHeaders={true} {...this.state.results} />
    } else if (this.state.errorMessage) {
      return <p style={{color: "red"}}>{this.state.errorMessage}</p>
    } else if (this.props.success) {
      return <p className="text-muted">Loading...</p>
    }
  }

  renderSqlErrors() {
    if (this.props.sql_errors.length > 0) {
      return (
        <div className="alert alert-danger">
          <ul>
            {this.props.sql_errors.map((message, i) => {
              return <li key={i}>{message}</li>
            })}
          </ul>
        </div>
      )
    }
  }

  handleSubmit(e) {
    if (e) {
      e.preventDefault()
    }

    const { query } = this.props
    const { variables } = this.state

    window.location.href = Routes.blazer_query_path(query.id, variables)
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

  renderVariables() {
    const { bind_vars } = this.props
    const { variables } = this.state

    if (bind_vars.length > 0) {
      return (
        <form onSubmit={this.handleSubmit.bind(this)} className="form-inline" style={{marginBottom: "10px"}}>
          {bind_vars.map((v, i) => {
            return (
              <span key={i}>
                <label htmlFor={v}>{v}</label>
                {" "}
                <input id={v} defaultValue={variables[v] || ""} onBlur={(e) => {
                  let attributes = {}
                  attributes[v] = e.target.value
                  this.updateVariables(attributes)
                }} type="text" className="form-control" />
                {" "}
              </span>
            )
          })}
          <input type="submit" className="btn btn-success" value="Run" style={{verticalAlign: "top"}} />
        </form>
      )
    }

    // <% date_vars = ["start_time", "end_time"] %>
    // <% if (date_vars - @bind_vars).empty? %>
    //   <% @bind_vars = @bind_vars - date_vars %>
    // <% else %>
    //   <% date_vars = nil %>
    // <% end %>

    // <% @bind_vars.each_with_index do |var, i| %>
    //   <%= label_tag var, var %>
    //   <% if (data = @smart_vars[var]) %>
    //     <%= select_tag var, options_for_select([[nil, nil]] + data, selected: params[var]), style: "margin-right: 20px; width: 200px; display: none;" %>
    //     <script>
    //       $("#<%= var %>").selectize({
    //         create: true
    //       });
    //     </script>
    //   <% else %>
    //     <%= text_field_tag var, params[var], style: "width: 120px; margin-right: 20px;", autofocus: i == 0 && !var.end_with?("_at") && !params[var], class: "form-control" %>
    //     <% if var.end_with?("_at") %>
    //       <script>
    //         $("#<%= var %>").daterangepicker({singleDatePicker: true, locale: {format: "YYYY-MM-DD"}});
    //       </script>
    //     <% end %>
    //   <% end %>
    // <% end %>

    // <% if date_vars %>
    //   <% date_vars.each do |var| %>
    //     <%= hidden_field_tag var, params[var] %>
    //   <% end %>

    //   <%= label_tag nil, date_vars.join(" & ") %>
    //   <div class="selectize-control single" style="width: 300px;">
    //     <div id="reportrange" class="selectize-input" style="display: inline-block;">
    //       <span>Select a time range</span>
    //     </div>
    //   </div>

    //   <script>
    //     var timeZone = "<%= Blazer.time_zone.tzinfo.name %>";
    //     var format = "YYYY-MM-DD";
    //     var now = moment.tz(timeZone);

    //     function dateStr(daysAgo) {
    //       return now.clone().subtract(daysAgo || 0, "days").format(format);
    //     }

    //     function toDate(time) {
    //       return moment.tz(time.format(format), timeZone);
    //     }

    //     function setTimeInputs(start, end) {
    //       $("#start_time").val(toDate(start).utc().format());
    //       $("#end_time").val(toDate(end).endOf("day").utc().format());
    //     }

    //     $('#reportrange').daterangepicker(
    //       {
    //         ranges: {
    //          "Today": [dateStr(), dateStr()],
    //          "Last 7 Days": [dateStr(6), dateStr()],
    //          "Last 30 Days": [dateStr(29), dateStr()]
    //         },
    //         locale: {
    //           format: format
    //         },
    //         startDate: dateStr(29),
    //         endDate: dateStr(),
    //         opens: "right"
    //       },
    //       function(start, end) {
    //         setTimeInputs(start, end);
    //         submitIfCompleted($("#start_time").closest("form"));
    //       }
    //     ).on('apply.daterangepicker', function(ev, picker) {
    //       setTimeInputs(picker.startDate, picker.endDate);
    //       $('#reportrange span').html(toDate(picker.startDate).format('MMMM D, YYYY') + ' - ' + toDate(picker.endDate).format('MMMM D, YYYY'));
    //     })

    //     if ($("#start_time").val().length > 0) {
    //       var picker = $("#reportrange").data('daterangepicker');
    //       picker.setStartDate(moment.tz($("#start_time").val(), timeZone));
    //       picker.setEndDate(moment.tz($("#end_time").val(), timeZone));
    //       $("#reportrange").trigger('apply.daterangepicker', picker)
    //     } else {
    //       var picker = $("#reportrange").data('daterangepicker');
    //       $("#reportrange").trigger('apply.daterangepicker', picker);
    //       submitIfCompleted($("#start_time").closest("form"));
    //     }
    //   </script>
    // <% end %>
  }
}
