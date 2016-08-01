class ChecksForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  render() {
    const logChange = (val) => {
      console.log(val);

      // fix for possible bug with react-select
      if (val instanceof Array) {
        val = null;
      }

      this.setState({queryId: val});
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
        <form onSubmit={this.handleSubmit}>
          <div className="form-group">
            <label htmlFor="check_query_id">Query</label>
            <div>
              <Select.Async
                name="check[query_id]"
                value={this.state.queryId}
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
            <input placeholder="Optional, comma separated" className="form-control" type="text" name="check[emails]" id="check_emails" />
          </div>
          <p className="text-muted">Emails are sent when a check starts failing, and when it starts passing again.</p>
          <p>
            <input type="submit" name="commit" value="Save" className="btn btn-success" />
          </p>
        </form>
      </div>
    );
  }

  handleSubmit(e) {
    e.preventDefault();
    var data = $(e.target).serialize();
    console.log(data);
    $.post(Routes.blazer_checks_path(), data, function (data) {
      console.log(data);
      browserHistory.push("/checks");
    }.bind(this));
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
