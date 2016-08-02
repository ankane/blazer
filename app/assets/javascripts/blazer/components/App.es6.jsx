const { createHistory } = History;
const { Router, Route, Link, useRouterHistory } = ReactRouter;

const browserHistory = useRouterHistory(createHistory)({
  basename: "/boom"
});

class App extends React.Component {
  render() {
    return (
      <Router history={browserHistory}>
        <Route path="/" component={QueriesIndex}></Route>
        <Route path="/queries/new" component={QueriesNew}></Route>
        <Route path="/queries/:id" component={QueriesShow}></Route>
        <Route path="/queries/:id/edit" component={QueriesEdit}></Route>
        <Route path="/dashboards" component={DashboardsIndex}></Route>
        <Route path="/dashboards/new" component={DashboardsNew}></Route>
        <Route path="/dashboards/:id" component={DashboardsShow}></Route>
        <Route path="/dashboards/edit" component={DashboardsEdit}></Route>
        <Route path="/checks" component={ChecksIndex}></Route>
        <Route path="/checks/new" component={ChecksNew}></Route>
        <Route path="/checks/:id/edit" component={ChecksEdit}></Route>
        <Route path="*" component={NotFound}/>
      </Router>
    );
  }
}

$( function () {
  ReactDOM.render(<App />, document.getElementById("root"))
})
