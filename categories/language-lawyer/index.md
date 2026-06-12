---
title: 语法律师
nav_order: 6
nav_exclude: false
has_children: false
permalink: /categories/language-lawyer/
description: "C++ 语法细节、陷阱与最佳实践 — language lawyer"
---

<div class="page-intro">
  <h1>语法律师</h1>
  <p>记录 C++ 语法细节、常见陷阱、编译错误排查与最佳实践。</p>
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
