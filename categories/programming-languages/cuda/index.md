---
title: CUDA
parent: 编程语言
nav_order: 2
nav_exclude: false
has_children: true                     # 若 CUDA 下还想分 Stream / Kernel / Opt
permalink: /categories/programming-languages/cuda/
description: "GPU 并行编程、内存模型与优化实践"
---

# CUDA

专注 **GPU 并行编程**、内存模型、性能调优与跨主机-设备协同。

## 📑 文章目录
<ul>
  {%- assign base = page.path | remove: 'index.md' -%}
  {%- assign notes = site.pages
        | where_exp:"p","p.path != page.path"
        | where_exp:"p","p.path contains base"
        | sort:'path' %}
  {%- if notes.size > 0 -%}
    {%- for p in notes -%}
      <li><a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>
    {%- endfor -%}
  {%- else -%}
    <p>尚无内容，敬请期待。</p>
  {%- endif -%}
</ul>
