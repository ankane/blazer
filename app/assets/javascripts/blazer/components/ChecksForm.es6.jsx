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

// <%= form_for @check do |f| %>
//   <div class="form-group">
//     <%= f.label :query_id, "Query" %>
//     <div class="hide">
//       <%= f.select :query_id, [], {include_blank: true} %>
//     </div>
//     <script>
//       var queries = <%= blazer_json_escape(Blazer::Query.named.order(:name).select("id, name").map { |q| {text: q.name, value: q.id} }.to_json).html_safe %>;
//       var items = <%= blazer_json_escape([@check.query_id].compact.to_json).html_safe %>;

//       $("#check_query_id").selectize({options: queries, items: items, highlight: false, maxOptions: 100}).parents(".hide").removeClass("hide");
//     </script>
//   </div>

//   <% if @check.respond_to?(:check_type) %>
//     <div class="form-group">
//       <%= f.label :check_type, "Alert if" %>
//       <div class="hide">
//         <% check_options = [["Any results (bad data)", "bad_data"], ["No results (missing data)", "missing_data"]] %>
//         <% check_options << ["Anomaly (most recent data point)", "anomaly"] if Blazer.anomaly_checks %>
//         <%= f.select :check_type, check_options %>
//       </div>
//       <script>
//         $("#check_check_type").selectize({}).parent().removeClass("hide");
//       </script>
//     </div>
//   <% elsif @check.respond_to?(:invert) %>
//     <div class="form-group">
//       <%= f.label :invert, "Fails if" %>
//       <div class="hide">
//         <%= f.select :invert, [["Any results (bad data)", false], ["No results (missing data)", true]] %>
//       </div>
//       <script>
//         $("#check_invert").selectize({}).parent().removeClass("hide");
//       </script>
//     </div>
//   <% end %>

//   <% if @check.respond_to?(:schedule) && Blazer.check_schedules %>
//     <div class="form-group">
//       <%= f.label :schedule, "Run every" %>
//       <div class="hide">
//         <%= f.select :schedule, Blazer.check_schedules.map { |v| [v, v] } %>
//       </div>
//       <script>
//         $("#check_schedule").selectize({}).parent().removeClass("hide");
//       </script>
//     </div>
//   <% end %>

//   <div class="form-group">
//     <%= f.label :emails %>
//     <%= f.text_field :emails, placeholder: "Optional, comma separated", class: "form-control" %>
//   </div>
//   <p class="text-muted">Emails are sent when a check starts failing, and when it starts passing again.
//   <p>
//     <% if @check.persisted? %>
//       <%= link_to "Delete", check_path(@check), method: :delete, "data-confirm" => "Are you sure?", class: "btn btn-danger" %>
//     <% end %>
//     <%= f.submit "Save", class: "btn btn-success" %>
//   </p>
// <% end %>
