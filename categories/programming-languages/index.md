---
title: 编程语言                     # 顶级栏目名称
nav_order: 2                        # 在 5 个一级入口中的排序
nav_exclude: false                  # 显式加入侧边导航
has_children: true                  # 告诉 Just the Docs 还有下一层
permalink: /categories/programming-languages/
description: "汇总 C/C++、CUDA、Python 等语言及工具链的学习笔记"
---

# 编程语言

这111里记录我在 **C/C++、CUDA、Python** 及相关工具链上的学习与实践。  
左侧导航将在本页下自动展开三个子分类（C++ / CUDA / Python）。

<!-- --- -->

<!-- ## 📂 子分类入口
- [C++](/categories/programming-languages/cpp/)
- [CUDA](/categories/programming-languages/cuda/)
- [Python](/categories/programming-languages/python/) -->

<!-- --- -->

## 📝 最近更新（编程语言栏目内）
<ul>
  {%- assign base = page.path | remove: 'index.md' -%}
  {%- assign recent = site.pages
        | where_exp:"p","p.path != page.path"        # 排除当前页
        | where_exp:"p","p.path contains base"       # 只要编程语言栏目的文章
        | where_exp:"p","p.name != 'index.md'"       # 关键：排除任何 index.md
        | sort: "date" | reverse | slice: 0, 5       # 最新 5 条
  -%}
  {%- if recent.size > 0 -%}
    {%- for p in recent -%}
      <li>{{ p.date | date: "%Y-%m-%d" }} — <a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>
    {%- endfor -%}
  {%- else -%}
    <li>尚无文章，敬请期待。</li>
  {%- endif -%}
</ul>


