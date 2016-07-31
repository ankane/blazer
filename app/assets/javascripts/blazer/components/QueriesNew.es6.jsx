class QueriesNew extends React.Component {
  render() {
    return (
      <div>
        New
        <Link to="/">Boom</Link>
        <form onSubmit={this.handleSubmit}>
          <input name="query[name]" />
          <textarea name="query[statement]"></textarea>
          <input type="submit" className="btn btn-success" value="Create" />
        </form>
      </div>
    );
  }

  handleSubmit(e) {
    e.preventDefault();
    var data = $(e.target).serialize();
    console.log(data);
    $.post("/queries", data, function (data) {
      console.log(data);
      browserHistory.push('/queries/' + data.id);
    }.bind(this));
  }
}
