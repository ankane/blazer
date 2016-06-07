//= require ./core

function runQuery(data, success, failure) {
  return $.ajax({
    url: window.runQueryUrl,
    method: "POST",
    data: data,
    dataType: "html"
  }).done(function(data) {
    success(data);
  }).fail(function(jqXHR, textStatus, errorThrown) {
    var message = (typeof errorThrown === "string") ? errorThrown : errorThrown.message;
    failure(message);
  });
}
