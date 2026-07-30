---
title: "C++ new 操作讨论"
date:
  created: 2024-01-14
  updated: 2024-02-03
slug: cpp-new-operator
categories:
  - C++
tags:
  - C++
  - Memory Management
description: "C++ new 操作学习笔记"
draft: true
---

<!-- more -->

c++ 中的new express有哪些?
创建并初始化拥有动态存储期的对象，这些对象的生存期不受它们创建时所在的作用域限制。



常规new,省略

分配
new可以作为分配函数使用
operator new或operator new[]

如果使用::operator new 或者 ::new 则会忽略替代函数(自己自定义了替换函数)
new T 会先查找T内的new
而::new T 则会从全局查找

    // ① 仅分配原始内存（不调用构造）
    void* raw = ::operator new(sizeof(Widget));

    // ② 显式构造
    Widget* pw = std::construct_at(static_cast<Widget*>(raw), 42);

    // ③ 正常使用
    std::printf("%d\n", pw->x);

    // ④ 显式析构 + 释放
    std::destroy_at(pw);
    ::operator delete(raw);
	
placement new
这玩意写法就有点狂野了
    alignas(Foo) std::byte buf[sizeof(Foo)];   // (1) 原始存储
    Foo* p = new (buf) Foo(42);                // (2) placement new → 调用构造
    std::printf("%d\n", p->a);                 // 正常使用
    std::destroy_at(p);                        // (3) 显式析构
	
	
将构造函数再指定的内存上调用
C++20 提供 std::construct_at / std::destroy_at 配合<new>头文件

构造高性能内存池的时候可能会用到
