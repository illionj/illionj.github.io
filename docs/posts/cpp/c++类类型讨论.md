---
title: "C++ 类类型讨论"
date:
  created: 2024-02-18
  updated: 2024-03-09
slug: cpp-class-types
categories:
  - C++
tags:
  - C++
  - Type System
description: "C++ 类类型学习笔记"
draft: true
---

# C++ 类类型讨论

<!-- more -->

POD :Plain Old Data  简单旧数据类型
Trivial Type 平凡类型
Standard Layout Type 标准布局类型


可平凡复制类
可平凡复制类 ﻿是满足以下所有条件的类：

至少有一个合格的复制构造函数，移动构造函数，复制赋值运算符或移动赋值运算符，
每个合格的复制构造函数都是平凡的，
每个合格的移动构造函数都是平凡的，
每个合格的复制赋值运算符都是平凡的，
每个合格的移动赋值运算符都是平凡的，并且
有一个未被弃置的平凡析构函数


标准布局类
标准布局类 ﻿是满足以下所有条件的类：

没有具有非标准布局类类型（或这种类型的数组）或引用类型的非静态数据成员，
没有虚函数和虚基类，
所有非静态数据成员都具有相同的可访问性，
没有非标准布局的基类，
继承层级中仅有一个类具有非静态数据成员，并且
非正式地说，该类的所有基类的类型均不同于第一个非静态数据成员。或者，正式来说，给定该类为 S，满足 M(S) 中没有 S 的基类，其中 M(X) 对于类型 X 定义如下：
如果 X 是没有（可能继承来的）非静态数据成员的非联合体类类型，那么集合 M(X) 为空。
如果 X 是首个非静态数据成员（可能是匿名联合体）具有 X0 类型的非联合体类类型，那么集合 M(X) 包含 X0 和 M(X0) 中的元素。
如果 X 是联合体类型，那么集合 M(X) 是包含所有 Ui 的集合与每个 M(Ui) 集合的并集，其中每个 Ui 是 X 的第 i 个非静态数据成员的类型。
如果 X 是元素类型为 Xe 的数组类型，那么集合 M(X) 包含 Xe 和 M(Xe) 中的元素。
如果 X 不是类类型或数组类型，那么集合 M(X) 为空。
标准布局结构体 ﻿是以类关键词 struct 或类关键词 class 定义的标准布局类。标准布局联合体 ﻿是以类关键词 union 定义的标准布局类。


同时满足Trivial Type 和 Standard Layout Type 的就是POD

给出一个最简单的pod刻板印象
struct pod{
	int c;
	char * a;
}

看起来和c结构体完全一致


1 为什么先 deprecate POD（C++20）
冗余 自 C++11 起，标准已把 POD 精确拆解成
“标准布局” + “平凡(或 trivially-copyable)**；POD 只是二者逻辑“与”的别名，没有独立信息量。

误导 很多场景只需要其中一半：

ABI 对齐、offsetof → 只关心 standard-layout

memcpy、文件映射 → 只关心 trivially-copyable

命名历史包袱 “Plain-Old-Data” 暗示能与 C 结构体互换，但其实还需考虑对齐/填充、大小端等问题——POD 名称容易让人掉坑。

因此 WG21 在 P0769R2 中提议把 概念与 std::is_pod trait 一并标记为 deprecated；鼓励直接组合更准确的 traits。
Stack Overflow

2 接着 deprecate Trivial type（拟定 C++26）
Paper P3247R2 “Deprecating the notion of trivial types”（现已进入 C++26 工作草案）提出：
“与其问『这个类型是不是 完全 平凡？』，不如问『它 哪几个 特殊成员是平凡的？』”
Stack Overflow
gcc.gnu.org

主要理由
“平凡类型”仍然是一个大筐子

若你只想知道 能否按位构造/析构，查 is_trivially_default_constructible+is_trivially_destructible 就够。

若你只关心拷贝成本，查 is_trivially_copyable。
统一问 is_trivial 反而含混不清。

语言层面几乎不用它
标准的语义规则早已改成谈“某个特殊成员函数是否平凡”。核心语言对整类型是否平凡不再有独立需求。

鼓励精确的库 API
库若写 requires is_trivial_v<T>，无意间把析构器等额外限制也绑进去，降低可用范围；改用精确 trait 可获得更松耦合的概念化接口。


首先要讨论,为什么划分出pod trivial standard,任何定义的诞生与弃用都是演化来的
一定有它能解决的问题,和它解决不了的问题
pod怎么来的
c++ 98/03年度,模板元编程未成熟,ABI考虑最重要
所以 只需要解决能不能memcpy就行.开发人员需要一种定义和工具判定能不能memcpy

c++11 语言特性爆发 如果单纯的从pod的角度来衡量则会误杀很多可以memcpy的类
因为从 layout 和lifetime 两个方向拆分了pod
layout 满足就是standard   指针偏移访问
lifetime 满足就是trivial  能否使用mem系统接口


再额外扩展一些  trivial的意义在哪
其实理论上任何数据结构都可以memcpy,拷贝出去又不犯法
但如果其中的成员变量是指针,memcpy只能拿到指针.这就会出现两个类共享一组成员.双重释放直接崩溃
同样的概念可以扩展到构造,移动,复制.本质就是所有权的问题

standard的意义在哪呢?
c语言中访问成员变量很多时候会采用指针偏移方式,参考linux中大量的宏
c++可没保证当前指向类的指针同时也一定指向类的第一个元素


紧接着 库与概念化编程需要更严谨的定义
trivial对六个函数都有平凡化要求
默认构造 拷贝构造 移动构造 拷贝赋值 移动赋值 析构
std::is_trivially_default_constructible_v<T> 负责默认构造的平凡
std::is_trivially_copyable 管理 拷贝构造 移动构造 拷贝赋值 移动赋值 析构的平凡
is_trivially_default_constructible_v的意义在于,你试图初始化一些容器的时,如果容器存储的对象类型满足
is_trivially_default_constructible_v,并且初始化的时候采用默认构造函数
可以直接,零成本初始化
void* raw = ::operator new(sizeof(T) * n);
return std::unique_ptr<T[]>(static_cast<T*>(raw));
而不是调用n个构造函数
std::unique_ptr<T[]> arr{ new T[n] };

is_trivially_copyable则是继承了原本trivial的字节拷贝构造能力
这也就是c++26拟废除trivial的原因
