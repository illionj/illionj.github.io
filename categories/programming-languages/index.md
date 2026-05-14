---
title: 编程语言
nav_order: 2
nav_exclude: false
has_children: true
has_toc: false
permalink: /categories/programming-languages/
description: "汇总 C/C++、CUDA、Python 等语言及工具链的学习笔记"
---

<div class="page-intro">
  <p class="page-eyebrow">栏目</p>
  <h1>编程语言</h1>
  <p>用于记录 C++、CUDA 等语言与相关工具链的学习笔记、实验记录和问题排查。</p>
</div>

<section class="page-section">
  <h2>子栏目</h2>
  <ul class="catalog-list">
    {%- assign sections = site.pages | where: "parent", page.title | sort: "nav_order" -%}
    {%- if sections.size > 0 -%}
      {%- for item in sections -%}
        <li>
          <a class="catalog-link" href="{{ item.url | relative_url }}">{{ item.title }}</a>
          {%- if item.description -%}
            <p class="catalog-meta">{{ item.description }}</p>
          {%- endif -%}
        </li>
      {%- endfor -%}
    {%- else -%}
      <li class="catalog-empty">尚无可展示的子栏目。</li>
    {%- endif -%}
  </ul>
</section>

<section class="page-section">
  <h2>最近更新</h2>
  <ul class="note-list">
  {%- assign base = page.path | remove: 'index.md' -%}
  {%- assign recent = site.pages
        | where_exp:"p","p.path != page.path"
        | where_exp:"p","p.path contains base"
        | where_exp:"p","p.name != 'index.md'"
        | where_exp:"p","p.date != nil"
  -%}
  {%- if recent.size > 0 -%}
    {%- include note_list_items.html notes=recent limit=5 -%}
  {%- else -%}
    <li class="catalog-empty">尚无文章。</li>
  {%- endif -%}
</ul>
</section>
