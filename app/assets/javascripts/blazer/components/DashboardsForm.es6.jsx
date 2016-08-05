class DashboardsForm extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      dashboard: {...this.props.dashboard},
      loading: false,
      errors: []
    }
  }

  handleSubmit(e) {
    e.preventDefault()

    this.setState({loading: true})
  }

  render() {
    const { dashboard, loading } = this.state

    return (
      <div>
        <form onSubmit={this.handleSubmit.bind(this)}>
          <div className="form-group">
            <label htmlFor="name">Name</label>
            <input id="name" type="text" value={dashboard.name || ""} onChange={(e) => this.updateDashboard({name: e.target.value})} className="form-control" />
          </div>
          <p>
            <input type="submit" value="Save" className="btn btn-success" disabled={loading} />
          </p>
        </form>
      </div>
    )
  }

  updateDashboard(attributes) {
    this.setState({
      dashboard: {...this.state.dashboard, ...attributes}
    })
  }
}

// <%= form_for @dashboard, url: (@dashboard.persisted? ? dashboard_path(@dashboard, variable_params) : dashboards_path(variable_params)) do |f| %>
//   <div class="form-group">
//     <%= f.label :name %>
//     <%= f.text_field :name, class: "form-control" %>
//   </div>
//   <div class="form-group <%= "hide" if (@queries || @dashboard.queries).empty? %>">
//     <%= f.label :charts %>
//     <ul class="list-group">
//       <% (@queries || @dashboard.dashboard_queries.order(:position).map(&:query)).each do |query| %>
//         <li class="list-group-item">
//           <span class="glyphicon glyphicon-remove" aria-hidden="true" style="float: right; margin-top: 3px;"></span>
//           <%= query.name %>
//           <%= hidden_field_tag "query_ids[]", query.id %>
//         </li>
//       <% end %>
//     </ul>
//   </div>
//   <div class="form-group">
//     <%= f.label :query_id, "Add Chart" %>
//     <div class="hide">
//       <%= select_tag :query_id, nil, {include_blank: true, placeholder: "Select chart"} %>
//     </div>
//     <script>
//       var queries = <%= blazer_json_escape(Blazer::Query.named.order(:name).select("id, name").map { |q| {text: q.name, value: q.id} }.to_json).html_safe %>;
//       $("#query_id").selectize({options: queries, highlight: false, maxOptions: 100}).parents(".hide").removeClass("hide");
//       $("#query_id").change( function () {
//         var $option = $(this).find("option:selected");
//         if ($option.val() !== "") {
//           var $li = $("<li></li>");
//           $li.addClass("list-group-item");
//           $li.text($option.text());
//           $li.prepend('<span class="glyphicon glyphicon-remove" aria-hidden="true" style="float: right; margin-top: 3px;"></span><input type="hidden" name="query_ids[]" id="query_ids_" value="' + $option.val() + '">');
//           $(".list-group").append($li);
//           $(this)[0].selectize.setValue("");
//           $(".form-group").removeClass("hide");
//         }
//       });
//     </script>
//   </div>
//   <p>
//     <% if @dashboard.persisted? %>
//       <%= link_to "Delete", dashboard_path(@dashboard), method: :delete, "data-confirm" => "Are you sure?", class: "btn btn-danger" %>
//     <% end %>
//     <%= f.submit "Save", class: "btn btn-success" %>
//   </p>
// <% end %>

// <script>
//   $(".list-group").on("click", ".glyphicon-remove", function () {
//     $(this).parents("li:first").remove();
//   });
//   Sortable.create($(".list-group").get(0));

//   // $("form").submit( function () {
//   //   var query_ids = $("li").map( function () {
//   //     return $(this).attr("data-query-id");
//   //   });
//   //   console.log(query_ids.join(","));
//   //   return false;
//   // });

//   // var editableList = Sortable.create($(".list-group").get(0), {
//   //   filter: '.js-remove',
//   //   onFilter: function (evt) {
//   //     var el = editableList.closest(evt.item); // get dragged item
//   //     el && el.parentNode.removeChild(el);
//   //   }
//   // });
// </script>
