var DraftStore = {
  isSessionStorageSupported: function() {
    return typeof(Storage) !== "undefined"
  },

  tabID: function() {
    return sessionStorage.tabID ? sessionStorage.tabID : sessionStorage.tabID = this._generateTabID()
  },

  saveDraft: function(value) {
    if (!this.isSessionStorageSupported()) {
      return
    }
    sessionStorage.setItem(this.tabID(), value)
  },

  restoreDraft: function() {
    if (!this.isSessionStorageSupported()) {
      return
    }
    return sessionStorage.getItem(this.tabID())
  },

  _generateTabID: function() {
    return "blazer-query-" + Math.random()
  }
}
