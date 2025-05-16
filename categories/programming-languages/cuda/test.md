---
title: "这里写你的笔记标题"
date: 2025-05-16     # 可选，用于显示日期
---

# CUDA 相关文章

<ul>
{% for post in site.categories.cuda %}
  <li>
    <a href="{{ post.url }}">{{ post.title }}</a>
    <small>（{{ post.date | date: "%Y-%m-%d" }}）</small>
  </li>
{% endfor %}
</ul>
