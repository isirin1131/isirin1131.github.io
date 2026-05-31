"use strict";

(function () {
  function dateRank(value) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value || "")) {
      return Number.NEGATIVE_INFINITY;
    }
    return Number(value.replace(/-/g, ""));
  }

  function titleCompare(a, b) {
    return (a.dataset.title || "").localeCompare(b.dataset.title || "", "zh-Hans-CN", {
      numeric: true,
      sensitivity: "base",
    });
  }

  function sortEntries(items, mode) {
    return items.slice().sort(function (a, b) {
      if (mode === "title-asc") {
        return titleCompare(a, b);
      }

      var field = mode === "published-desc" ? "published" : "updated";
      var diff = dateRank(b.dataset[field]) - dateRank(a.dataset[field]);
      return diff || titleCompare(a, b);
    });
  }

  function initArchive(archive) {
    var list = archive.querySelector("[data-entry-list]");
    var sort = archive.querySelector("[data-sort]");
    var result = archive.querySelector("[data-result-count]");
    var filters = Array.prototype.slice.call(archive.querySelectorAll("[data-filter]"));
    var items = Array.prototype.slice.call(archive.querySelectorAll("[data-entry]"));
    var activeType = "all";

    function render() {
      var visibleCount = 0;
      var ordered = sortEntries(items, sort ? sort.value : "updated-desc");

      ordered.forEach(function (item) {
        var visible = activeType === "all" || item.dataset.type === activeType;
        item.hidden = !visible;
        if (visible) {
          visibleCount += 1;
        }
        list.appendChild(item);
      });

      filters.forEach(function (button) {
        var active = button.dataset.filter === activeType;
        button.classList.toggle("is-active", active);
        button.setAttribute("aria-pressed", active ? "true" : "false");
      });

      if (result) {
        result.textContent = visibleCount + " 篇";
      }
    }

    filters.forEach(function (button) {
      button.addEventListener("click", function () {
        activeType = button.dataset.filter || "all";
        render();
      });
    });

    if (sort) {
      sort.addEventListener("change", render);
    }

    render();
  }

  function initFold(details) {
    var state = details.querySelector("[data-fold-state]");

    function update() {
      if (state) {
        state.textContent = details.open ? "收起" : "展开";
      }
    }

    details.addEventListener("toggle", update);
    update();
  }

  document.querySelectorAll("[data-archive]").forEach(initArchive);
  document.querySelectorAll("[data-fold]").forEach(initFold);
})();
