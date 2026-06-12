---
title: 异构计算
nav_order: 3
nav_exclude: false
has_children: false
permalink: /categories/heterogeneous-computing/
description: "记录一些 CUDA 学习经验，基本就是 PMPP 和 CUDA Program Guide 笔记"
---

<div class="page-intro">
  <h1>异构计算</h1>
  <p>记录 GPU 并行编程、CUDA、内存模型与性能优化等学习笔记。</p>
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
