function removeDelimiters(string) {
  return string.replace(/,/g, "")
}

function compareInt(a, b) {
  return parseInt(removeDelimiters(a), 10) - parseInt(removeDelimiters(b), 10)
}

function compareFloat(a, b) {
  return parseFloat(removeDelimiters(a)) - parseFloat(removeDelimiters(b))
}

function compareString(a, b) {
  return a.localeCompare(b, undefined, {sensitivity: "base"})
}

function tablesort(element) {
  let lastIndex = -1
  let reverse = false

  element.addEventListener("click", function (e) {
    const target = e.target.closest("th")
    if (target) {
      const columnIndex = Array.from(element.querySelectorAll("thead th")).indexOf(target)
      const sortType = target.getAttribute("data-sort")
      const compareFn = sortType == "int" ? compareInt : (sortType == "float" ? compareFloat : compareString)
      reverse = columnIndex != lastIndex ? false : !reverse

      const tbody = element.querySelector("tbody")
      const rows = Array.from(tbody.querySelectorAll("tr"))
      rows.sort(function (a, b) {
        const av = a.children[columnIndex].textContent
        const bv = b.children[columnIndex].textContent
        const r = compareFn(av, bv)
        return reverse ? -r : r
      })
      tbody.replaceChildren(...rows)

      lastIndex = columnIndex
    }
  })
}
