---
title: 计算机架构
nav_order: 4
nav_exclude: false
has_children: false
permalink: /categories/computer-architecture/
description: "基本就是 CSAPP 的笔记"
---

<div class="page-intro">
  <h1>计算机架构</h1>
  <p>记录计算机系统、处理器架构、内存层次等 CSAPP 相关学习笔记。</p>
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
