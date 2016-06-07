//= require ./core

function runQuery(data, success, error) {
  return $.ajax({
    url: window.runQueriesPath,
    method: "POST",
    data: data,
    dataType: "html"
  }).done(success).fail( function(jqXHR, textStatus, errorThrown) {
    var message = (typeof errorThrown === "string") ? errorThrown : errorThrown.message;
    error(message);
  });
}
