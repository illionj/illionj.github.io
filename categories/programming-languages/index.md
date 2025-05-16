---
title: 编程语言                 # 侧栏显示文字
nav_order: 2                    # 在 5 个一级入口中的排序
nav_exclude: false              # 显式加入导航（其余页面默认隐藏）
permalink: /categories/programming-languages/
description: "C/C++, Python、CUDA 及相关工具链的学习笔记索引"
---

# 编程语言

这里汇总我在 **C/C++、Python、CUDA** 及周边工具链上的踩坑记录与实践经验。  
页面列表会自动生成，无需手动维护——只管在该目录（或子目录）添加 `.md` 文件即可。

---

## 📑 文章目录
<ul>
  {%- assign base = page.path | remove: 'index.md' -%}
  {%- assign notes = site.pages
        | where_exp:"p","p.path != page.path"
        | where_exp:"p","p.path contains base"
        | sort: "path" %}
  {%- if notes.size > 0 -%}
    {%- for p in notes -%}
      <li><a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>
    {%- endfor -%}
  {%- else -%}
    <p>尚无内容，敬请期待。</p>
  {%- endif -%}
</ul>
