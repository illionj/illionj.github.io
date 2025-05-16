---
layout: default
title: "CUDA 笔记"
permalink: /categories/programming-languages/cuda/
---

# CUDA 笔记

下面自动列出本目录下所有的 Markdown 笔记（不含自己）：

<ul>
{%- assign items = site.pages 
     | where_exp: "p", "p.path contains 'categories/programming-languages/cuda/'" 
     | reject: "path", "categories/programming-languages/cuda/index.md"
     | sort: "path" -%}
{%- for p in items -%}
  <li>
    <a href="{{ p.url | relative_url }}">{{ p.title }}</a>
    {%- if p.date -%}
      <small>（{{ p.date | date: "%Y-%m-%d" }}）</small>
    {%- endif -%}
  </li>
{%- endfor -%}
</ul>


