---
title: 首页
nav_order: 1
nav_exclude: false
---

<div class="page-intro">
  <p class="page-eyebrow">技术笔记</p>
  <h1>首页</h1>
  <p>本站用于整理编程语言与相关计算主题的学习记录。内容按主题归档，优先保证结构清晰、检索方便与长期维护。</p>
</div>

<section class="page-section">
  <h2>栏目</h2>
  <ul class="catalog-list">
    <li>
      <a class="catalog-link" href="{{ '/categories/programming-languages/' | relative_url }}">编程语言</a>
      <p class="catalog-meta">C++、CUDA 与相关工具链。</p>
    </li>
    <li>
      <a class="catalog-link" href="{{ '/notes/' | relative_url }}">所有笔记</a>
      <p class="catalog-meta">集中查看全部笔记条目与后续归档页。</p>
    </li>
  </ul>
</section>

<section class="page-section">
  <h2>最近更新</h2>
  <ul class="note-list">
    {%- assign recent = site.pages
          | where_exp: "p", "p.url != page.url"
          | where_exp: "p", "p.name != 'index.md'"
          | where_exp: "p", "p.date != nil"
    -%}
    {%- if recent.size > 0 -%}
      {%- include note_list_items.html notes=recent limit=6 -%}
    {%- else -%}
      <li class="catalog-empty">尚无可展示的更新。</li>
    {%- endif -%}
  </ul>
</section>
