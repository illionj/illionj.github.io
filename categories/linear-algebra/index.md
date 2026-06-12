---
title: 线性代数
nav_order: 7
nav_exclude: false
has_children: false
permalink: /categories/linear-algebra/
description: "感谢 Gilbert Strang 教授"
---

<div class="page-intro">
  <h1>线性代数</h1>
  <p>记录 Gilbert Strang 教授线性代数课程的学习笔记与理解。</p>
</div>

<section class="page-section">
  <h2>文章目录</h2>
  <ul class="note-list">
  {%- assign base = page.path | remove: 'index.md' -%}
  {%- assign notes = site.pages
        | where_exp:"p","p.path != page.path"
        | where_exp:"p","p.path contains base"
        | where_exp:"p","p.name != 'index.md'"
  -%}
  {%- if notes.size > 0 -%}
    {%- include note_list_items.html notes=notes -%}
  {%- else -%}
    <li class="catalog-empty">尚无内容。</li>
  {%- endif -%}
</ul>
</section>
