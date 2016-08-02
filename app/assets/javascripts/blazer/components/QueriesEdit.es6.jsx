class QueriesEdit extends React.Component {
  componentDidMount() {
    document.title = "Edit Query"
  }

  render() {
    return (
      <QueriesForm />
    );
  }
}
