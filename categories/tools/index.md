---
title: 工具命令
nav_order: 5
nav_exclude: false
has_children: false
permalink: /categories/tools/
description: "git, vscode, vim, linux 命令, shell 等等"
---

<div class="page-intro">
  <h1>工具命令</h1>
  <p>记录日常开发工具的使用技巧、命令备忘与配置经验。</p>
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
