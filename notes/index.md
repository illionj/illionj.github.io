---
layout: default
title: "所有笔记"
nav_order: 3
nav_exclude: false
permalink: /notes/
---

<div class="page-intro">
  <p class="page-eyebrow">索引</p>
  <h1>所有笔记</h1>
  <p>这里集中列出全部笔记条目，并支持按标签或最后修改日期筛选。</p>
</div>

<section class="page-section">
  <h2 id="notes-filter-title">全部条目</h2>
  <ul class="note-list">
    {%- assign notes = site.pages
          | where_exp:"p","p.path != page.path"
          | where_exp:"p","p.name != 'index.md'"
          | where_exp:"p","p.date != nil"
    -%}
    {%- if notes.size > 0 -%}
      {%- include note_list_items.html notes=notes -%}
    {%- else -%}
      <li class="catalog-empty">notes 目录下暂时还没有可展示的条目。</li>
    {%- endif -%}
  </ul>
  <p class="catalog-empty" id="notes-filter-empty" hidden>没有匹配的文章。</p>
</section>

<script>
  (function () {
    var params = new URLSearchParams(window.location.search);
    var tag = params.get("tag");
    var date = params.get("date");
    var updated = params.get("updated");
    if (!tag && !date && !updated) return;

    var title = document.getElementById("notes-filter-title");
    var empty = document.getElementById("notes-filter-empty");
    var items = Array.prototype.slice.call(document.querySelectorAll(".note-list > li[data-tags]"));
    var visible = 0;

    items.forEach(function (item) {
      var tags = (item.getAttribute("data-tags") || "").split(",");
      var itemDate = item.getAttribute("data-date");
      var itemUpdated = item.getAttribute("data-updated");
      var matchesTag = !tag || tags.indexOf(tag) !== -1;
      var matchesDate = !date || itemDate === date;
      var matchesUpdated = !updated || itemUpdated === updated;
      var matches = matchesTag && matchesDate && matchesUpdated;

      item.classList.toggle("is-filtered-out", !matches);
      if (matches) visible += 1;
    });

    if (title) {
      title.textContent = tag ? "标签：" + tag : (date ? "创建日期：" + date : "最后修改：" + updated);
    }

    if (empty) {
      empty.hidden = visible !== 0;
    }
  })();
</script>
