---
layout: default
title: "所有笔记"
permalink: /notes/
---

# 笔记列表

<ul>
{% for note in site.notes %}
  <li>
    <a href="{{ note.url }}">{{ note.title }}</a>
    {% if note.date %} <small>{{ note.date | date: "%Y-%m-%d" }}</small>{% endif %}
  </li>
{% endfor %}
</ul>
