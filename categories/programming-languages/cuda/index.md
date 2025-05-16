---
layout: default
title: "CUDA 笔记"
permalink: /categories/programming-languages/cuda/
---

# CUDA 笔记

下面自动列出本目录下所有 Markdown 文件（不含本页）：

<ul>
{% comment %}
  第一步：筛选出本目录下的所有页面
{% endcomment %}
{% assign all_cuda = site.pages | where_exp: "item", "item.path contains 'categories/programming-languages/cuda/'" %}

{% comment %}
  第二步：排除自己 (index.md)
{% endcomment %}
{% assign notes = all_cuda | reject: "path", "categories/programming-languages/cuda/index.md" %}

{% comment %}
  第三步：按文件路径排序（也可改成按 title 或 date 排序）
{% endcomment %}
{% assign notes = notes | sort: "path" %}

{% comment %}
  最后，遍历输出
{% endcomment %}
{% for p in notes %}
  <li>
    <a href="{{ p.url | relative_url }}">{{ p.title }}</a>
    {% if p.date %}
      <small>（{{ p.date | date: "%Y-%m-%d" }}）</small>
    {% endif %}
  </li>
{% endfor %}
</ul>



