module Blazer
  module TimelineHelper
    def vis_timeline(chart_id, rows)
      values = rows.map.with_index(1) { |array, index| { id: index, content: array[0], start: array[1], end: array[2] } }
      groups = if rows.first[3].present?
                 rows.map { |array| array[3] }.uniq.map { |group_name| { id: group_name, content: group_name } }
               end
      if groups
        return <<~JS
          <div id="visualization_#{chart_id}"></div>

          <script type="text/javascript">
              // DOM element where the Timeline will be attached
              var container = document.getElementById('visualization_#{chart_id}');

              // Create a DataSet (allows two way data-binding)
              var items = new vis.DataSet(JSON.parse('#{values.to_json}'));
              var groups = new vis.DataSet(JSON.parse('#{groups.to_json}'));

              // Configuration for the Timeline
              var options = {};

              // Create a Timeline
              new vis.Timeline(container, items, groups options);
          </script>
        JS
      end

      <<~JS
        <div id="visualization_#{chart_id}"></div>

        <script type="text/javascript">
            // DOM element where the Timeline will be attached
            var container = document.getElementById('visualization_#{chart_id}');

            // Create a DataSet (allows two way data-binding)
            var items = new vis.DataSet(JSON.parse('#{values.to_json}'));

            // Configuration for the Timeline
            var options = {};

            // Create a Timeline
            new vis.Timeline(container, items, options);
        </script>
      JS
    end
  end
end