---
layout: default
title: "CUDA 笔记"                          # 这里改成子分类的名称
permalink: /categories/programming-languages/cuda/
---

# CUDA 笔记

下面自动列出本子分类目录下的所有笔记（不包含本页面）：

<ul>
  {%- assign items = site.pages
       | where_exp: "p", "p.url != page.url and p.url contains page.url"
       | sort: "p.title"
  -%}
  {%- for p in items -%}
    <li>
      <a href="{{ p.url | relative_url }}">{{ p.title }}</a>
      {%- if p.date -%}
        <small>（{{ p.date | date: "%Y-%m-%d" }}）</small>
      {%- endif -%}
    </li>
  {%- endfor -%}
</ul>

