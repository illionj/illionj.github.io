---
title: 首页
nav_order: 1
nav_exclude: false
---

<div class="page-intro">
  <h3>我想说的</h3>
  <p>人的注意力在当下环境非常稀缺<br>
  如果别人投入的注意力进来,我不希望别人看到的是AI信息倾泻<br>
  </p>
</div>

<section class="page-section">
  <ul class="catalog-list">
    <li>
      <a class="catalog-link" href="{{ '/categories/heterogeneous-computing/' | relative_url }}">异构计算</a>
      <p class="catalog-meta">记录一些cuda学习经验,基本就是pmpp和cuda program guide笔记</p>
    </li>
    <li>
      <a class="catalog-link" href="{{ '/categories/computer-architecture/' | relative_url }}">计算机架构</a>
      <p class="catalog-meta">基本就是csapp的笔记</p>
    </li>
    <li>
      <a class="catalog-link" href="{{ '/categories/tools/' | relative_url }}">工具命令</a>
      <p class="catalog-meta">git,vscode,vim,linux命令,sh等等</p>
    </li>
    <li>
      <a class="catalog-link" href="{{ '/categories/language-lawyer/' | relative_url }}">语法律师</a>
      <p class="catalog-meta">"你写过TM的cpp吗?你个XX滚出去"--嘎子</p>
    </li>
    <li>
      <a class="catalog-link" href="{{ '/categories/linear-algebra/' | relative_url }}">线性代数</a>
      <p class="catalog-meta">感谢Gilbert Strang教授</p>
    </li>
    <li>
      <a class="catalog-link" href="{{ '/notes/' | relative_url }}">所有笔记</a>
      <p class="catalog-meta">集中查看全部笔记条目与后续归档页。</p>
    </li>
  </ul>
</section>

<section class="page-section">
  <h3>最近更新</h3>
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
