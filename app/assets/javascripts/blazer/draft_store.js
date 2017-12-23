var DraftStore = {
  isSessionStorageSupported: function() {
    return typeof(Storage) !== "undefined"
  },

  tabID: function() {
    return sessionStorage.tabID ? sessionStorage.tabID : sessionStorage.tabID = Math.random()
  },

  saveDraft: function(value) {
    if (!this.isSessionStorageSupported()) {
      return
    }
    sessionStorage.setItem("blazer-query-" + this.tabID(), value)
  },

  restoreDraft: function() {
    if (!this.isSessionStorageSupported()) {
      return
    }
    return sessionStorage.getItem("blazer-query-" + this.tabID())
  }
}
