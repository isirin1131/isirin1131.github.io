"use strict";

(function () {
  var root = document.querySelector("[data-gallery]");
  if (!root) {
    return;
  }

  var state = {
    items: [],
    activeId: "",
    filter: "all",
  };

  var els = {
    list: root.querySelector("[data-gallery-list]"),
    count: root.querySelector("[data-gallery-count]"),
    visibleCount: root.querySelector("[data-gallery-visible-count]"),
    current: root.querySelector("[data-gallery-current]"),
    image: root.querySelector("[data-gallery-image]"),
    imageTitle: root.querySelector("[data-gallery-image-title]"),
    caption: root.querySelector("[data-gallery-caption]"),
    kind: root.querySelector("[data-gallery-kind]"),
    doc: root.querySelector("[data-gallery-doc]"),
    docTitle: root.querySelector("[data-gallery-doc-title]"),
    mdLink: root.querySelector("[data-gallery-md-link]"),
    clock: root.querySelector("[data-gallery-clock]"),
    filters: Array.prototype.slice.call(root.querySelectorAll("[data-gallery-filter]")),
  };

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function escapeAttr(value) {
    return escapeHtml(value).replace(/`/g, "&#96;");
  }

  function inlineMarkdown(text) {
    var escaped = escapeHtml(text);
    var codeStore = [];

    escaped = escaped.replace(/`([^`]+)`/g, function (_, code) {
      var token = "\u0000CODE" + codeStore.length + "\u0000";
      codeStore.push("<code>" + code + "</code>");
      return token;
    });

    escaped = escaped.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, function (_, label, href) {
      return '<a href="' + escapeAttr(href) + '" target="_blank" rel="noopener">' + label + "</a>";
    });
    escaped = escaped.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
    escaped = escaped.replace(/\*([^*]+)\*/g, "<em>$1</em>");

    codeStore.forEach(function (code, index) {
      escaped = escaped.replace("\u0000CODE" + index + "\u0000", code);
    });

    return escaped;
  }

  function flushParagraph(buffer, html) {
    if (buffer.length) {
      html.push("<p>" + inlineMarkdown(buffer.join(" ")) + "</p>");
      buffer.length = 0;
    }
  }

  function flushList(list, html) {
    if (list.items.length) {
      html.push("<" + list.type + ">");
      list.items.forEach(function (item) {
        html.push("<li>" + inlineMarkdown(item) + "</li>");
      });
      html.push("</" + list.type + ">");
      list.items.length = 0;
      list.type = "";
    }
  }

  function markdownToHtml(markdown) {
    var html = [];
    var paragraph = [];
    var list = { type: "", items: [] };
    var inCode = false;
    var codeLines = [];
    var lines = String(markdown || "").replace(/\r\n/g, "\n").split("\n");

    lines.forEach(function (line) {
      var trimmed = line.trim();
      var match;

      if (trimmed.indexOf("```") === 0) {
        flushParagraph(paragraph, html);
        flushList(list, html);
        if (inCode) {
          html.push("<pre><code>" + escapeHtml(codeLines.join("\n")) + "</code></pre>");
          codeLines = [];
          inCode = false;
        } else {
          inCode = true;
        }
        return;
      }

      if (inCode) {
        codeLines.push(line);
        return;
      }

      if (!trimmed) {
        flushParagraph(paragraph, html);
        flushList(list, html);
        return;
      }

      if (/^---+$/.test(trimmed)) {
        flushParagraph(paragraph, html);
        flushList(list, html);
        html.push("<hr>");
        return;
      }

      match = /^(#{1,3})\s+(.+)$/.exec(trimmed);
      if (match) {
        flushParagraph(paragraph, html);
        flushList(list, html);
        html.push("<h" + match[1].length + ">" + inlineMarkdown(match[2]) + "</h" + match[1].length + ">");
        return;
      }

      match = /^>\s?(.*)$/.exec(trimmed);
      if (match) {
        flushParagraph(paragraph, html);
        flushList(list, html);
        html.push("<blockquote>" + inlineMarkdown(match[1]) + "</blockquote>");
        return;
      }

      match = /^[-*]\s+(.+)$/.exec(trimmed);
      if (match) {
        flushParagraph(paragraph, html);
        if (list.type && list.type !== "ul") {
          flushList(list, html);
        }
        list.type = "ul";
        list.items.push(match[1]);
        return;
      }

      match = /^\d+\.\s+(.+)$/.exec(trimmed);
      if (match) {
        flushParagraph(paragraph, html);
        if (list.type && list.type !== "ol") {
          flushList(list, html);
        }
        list.type = "ol";
        list.items.push(match[1]);
        return;
      }

      paragraph.push(trimmed);
    });

    if (inCode) {
      html.push("<pre><code>" + escapeHtml(codeLines.join("\n")) + "</code></pre>");
    }
    flushParagraph(paragraph, html);
    flushList(list, html);

    return html.join("\n");
  }

  function kindLabel() {
    return "ITEM";
  }

  function visibleItems() {
    return state.items.filter(function (item) {
      return state.filter === "all";
    });
  }

  function renderList() {
    var items = visibleItems();

    els.list.innerHTML = "";
    if (els.visibleCount) {
      els.visibleCount.textContent = items.length + " ITEMS";
    }

    items.forEach(function (item) {
      var button = document.createElement("button");
      button.type = "button";
      button.className = "gallery-card-button" + (item.id === state.activeId ? " is-active" : "");
      button.dataset.galleryItem = item.id;
      button.innerHTML =
        '<span class="gallery-card-title">' + escapeHtml(item.title) + "</span>" +
        '<span class="gallery-card-meta">' +
        "<span>ITEM</span>" +
        "<span>" + escapeHtml(item.date || "undated") + "</span>" +
        "</span>";
      button.addEventListener("click", function () {
        selectItem(item.id);
      });
      els.list.appendChild(button);
    });

    if (!items.length) {
      els.list.innerHTML = '<p class="gallery-card-button">NO ITEMS</p>';
    }
  }

  function updateFilterButtons() {
    els.filters.forEach(function (button) {
      var active = button.dataset.galleryFilter === state.filter;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-pressed", active ? "true" : "false");
    });
  }

  function selectItem(id) {
    var item = state.items.find(function (candidate) {
      return candidate.id === id;
    });
    if (!item) {
      return;
    }

    state.activeId = item.id;
    renderList();

    els.image.hidden = !item.image;
    els.image.src = item.image || "";
    els.image.alt = item.alt || item.title;
    els.imageTitle.textContent = item.title;
    els.caption.textContent = "";
    els.caption.hidden = true;
    els.kind.textContent = kindLabel();
    els.docTitle.textContent = item.source ? "MARKDOWN: " + item.source.split("/").pop() : "MARKDOWN";
    els.mdLink.href = item.source || "#";
    els.current.textContent = item.title;

    els.doc.innerHTML = item.body ? markdownToHtml(item.body) : "";
  }

  function setFilter(filter) {
    state.filter = filter;
    updateFilterButtons();
    var items = visibleItems();
    if (!items.some(function (item) { return item.id === state.activeId; }) && items[0]) {
      state.activeId = items[0].id;
      selectItem(items[0].id);
    } else {
      renderList();
    }
  }

  function updateClock() {
    if (!els.clock) {
      return;
    }
    els.clock.textContent = new Date().toLocaleTimeString("zh-CN", {
      hour12: false,
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
  }

  els.filters.forEach(function (button) {
    button.addEventListener("click", function () {
      setFilter(button.dataset.galleryFilter || "all");
    });
  });

  updateClock();
  window.setInterval(updateClock, 1000);

  function loadItems() {
    var dataNode = document.getElementById("gallery-data");
    if (!dataNode) {
      return [];
    }

    try {
      var data = JSON.parse(dataNode.textContent || "[]");
      return Array.isArray(data) ? data : [];
    } catch (_) {
      return [];
    }
  }

  state.items = loadItems();
  if (els.count) {
    els.count.textContent = state.items.length;
  }
  updateFilterButtons();
  renderList();
  if (state.items[0]) {
    selectItem(state.items[0].id);
  } else {
    els.image.hidden = true;
    els.doc.innerHTML = "<p>NO ITEMS</p>";
  }
})();
