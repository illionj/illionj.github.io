---
title: CUDA
parent: 编程语言
nav_order: 2
nav_exclude: false
has_children: true
permalink: /categories/programming-languages/cuda/
description: "GPU 并行编程、内存模型与优化实践"
---

<div class="page-intro">
  <p class="page-eyebrow">子栏目</p>
  <h1>CUDA</h1>
  <p>集中整理 GPU 并行编程、内存模型、性能调优与主机设备协同相关内容。</p>
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
