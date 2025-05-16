---
layout: home
title: "我的笔记汇总"
---

欢迎来到我的笔记站！下面是最近的更新：

<ul>
{% for post in site.posts limit:5 %}
  <li><a href="{{ post.url }}">{{ post.title }}</a> <small>{{ post.date | date: "%Y-%m-%d" }}</small></li>
{% endfor %}
</ul>

