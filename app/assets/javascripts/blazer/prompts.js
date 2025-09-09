var pendingPrompts = []
var runningPrompts = []
var maxPrompts = 3

function runPrompt(data, success, error) {
  var xhr = $.ajax({
    url: Routes.run_prompts_path(),
    method: "POST",
    data: data,
    dataType: "html"
  }).done( function (d) {
    success(d)
  }).fail( function(jqXHR, textStatus, errorThrown) {
    var message = (typeof errorThrown === "string") ? errorThrown : errorThrown.message
    error(message)
  });
}
