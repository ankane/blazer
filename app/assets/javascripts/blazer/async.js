// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the rails generate channel command.
//
//= require ./core
//= require action_cable

var runCount = 0;

function runQuery(data, success, failure) {
  var cable = ActionCable.createConsumer();
  runCount++;

  var sub = cable.subscriptions.create({channel: "Blazer::QueriesChannel", run: runCount}, {
    connected: function () {
      sub.run(data);
    },
    received: function (data) {
      success(data.data);
      cable.disconnect();
    },
    run: function(data) {
      this.perform("run", data);
    }
  });
}
