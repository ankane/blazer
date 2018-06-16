var DraftStore = {
  isSessionStorageSupported: function () {
    return typeof (Storage) !== "undefined"
  },

  saveDraft: function (value) {
    if (!this.isSessionStorageSupported()) { return }
    sessionStorage.setItem(this._tabID(), value)
  },

  restoreDraft: function () {
    if (!this.isSessionStorageSupported()) { return }
    return sessionStorage.getItem(this._tabID())
  },

  removeDraft: function () {
    if (!this.isSessionStorageSupported()) { return }
    return sessionStorage.removeItem(this._tabID())
  },

  _tabID: function () {
    return sessionStorage._tabID ? sessionStorage._tabID : sessionStorage._tabID = ("blazer-query-" + Math.random())
  }
}
