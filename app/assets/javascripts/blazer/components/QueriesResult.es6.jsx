class QueriesResult extends React.Component {
  render() {
    return (
      <div id="results">
        {() => {
          if (this.props.loading) return <p className="text-muted">Loading...</p>
          return <div dangerouslySetInnerHTML={{__html: this.props.result}}></div>
        }()}
      </div>
    );
  }
}
