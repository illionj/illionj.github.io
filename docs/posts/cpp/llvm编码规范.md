---
title: "LLVM 编码规范"
date:
  created: 2024-08-11
  updated: 2024-09-07
slug: llvm-coding-standards
categories:
  - C++
tags:
  - C++
  - LLVM
  - Coding Standards
description: "LLVM 编码规范学习笔记"
draft: true
---

# LLVM 编码规范

<!-- more -->

这写我必须坚持的东西
左花括号要换行
标准缩进是4个空格



1.推荐使用std和llvm支持库
但是如果它们都可以,则优先使用llvm

2.python部分代码坚持PEP 8,并且使用专用的工具自动format

$ pip install black=='23.*' darker # install black 23.x and darker
$ darker test.py                   # format uncommitted changes
$ darker -r HEAD^ test.py          # also format changes from last commit
$ black test.py                    # format entire file

根据目录查找
$ darker -r HEAD^ $(git diff --name-only --diff-filter=d HEAD^)


3.注释要求
适当使用大写和标点 专注于代码要做什么而不是在细节怎么做的

4 文件头
标准要求是 第一行为文件名
接着跟license  (我应该不需要)
下面是doxygen的注释主体 使用///注释

//===-- llvm/Instruction.h - Instruction class definition -------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file contains the declaration of the Instruction class, which is the
/// base class for all of the VM instructions.
///
//===----------------------------------------------------------------------===//

5.头文件保护
真实路径
llvm/include/llvm/Analysis/Utils/Local.h 
包含路径
#include-ed as #include "llvm/Analysis/Utils/Local.h", 
头文件包含宏
LLVM_ANALYSIS_UTILS_LOCAL_H

6.类预览
每个类都需要有一个doxygen注释块

7.函数信息
方法和全局函数都应该被归档
一个关于它做什么和边缘条件的快速记录是必须的
读者应该能直接理解如何使用这个接口而不需要阅读代码本身
一个值得讨论的事情是  当没有按照预期运行时会发生什么,比如会不会返回null

8.注释格式
通常情况下推荐c++风格注释(//为正常注释  ///为doxygen注释)
但是也有使用c风格注释的场景
通常就是和提供给c语言的源文件会用

9.doxygen在文档注释中的使用
对于所有的公共接口,避免重复
注释尽量写在头文件中,实现文件当然也可以为私有接口写注释,看情况
写注释前不用重复类名或者函数名

10.错误与警告信息
Support/WithColor.h
这个是llvm官方提供的错误打印方式

11. #include style
在文件头注释之后,应该立刻添加最小化#include

推荐顺序  
1.主模块头文件 就是这个文件直接对应的头文件
2.本地或者私有头文件 一些支持函数或者其他  它们没有被广泛使用,仅仅是在此文件或者部分文件使用	
3.llvm项目或者子项目头文件(类似支撑函数等)  
4.系统include

每个类别都应该按照完整路径的字典顺序排列

头文件include应该从最具体到最不具体
比如 lldb依赖clang,clang依赖llvm,那么在include的时候应该优先include lldb自己的头文件
再include clang的头文件 再include llvm的

这样做的好处在于,如果lldb存在头文件缺失,可以立刻发现,而不是因为其他include覆盖


整体思想就是从最具体到最不具体

12.代码宽度
代码宽度的限制的本意是方便开发人员多文件显示
推荐限制在80列
很多显存项目都是80列

13.空白
推荐使用空格而不是table
最好不要添加尾行空格,因为编辑器的自动删除会触发不必要的提交记录

14.lambda
对于一个多行的lambda,应该使用代码块一样的排版风格

15.初始化列表
对待初始化列表可以沿用一个简单的规则
把花括号视为小括号

16.对待警告如同错误
17.尽量书写可移植的代码  如果真的需要依赖不可移植代码,将它置于良好定义和良好文档的后面
18.不要使用rtti和异常
比如dynamic_cast,但是llvm内部使用自制的类型检查和转化方法
llvm不使用rtti和异常的根本原因是减少代码和可执行文件的大小

19.尽量使用c++style cast
但是可以有两点例外  涉及void转化带来警告
都是整型类型转化,包括枚举  可以使用传统风格转化


20,不要使用静态构造器
比如静态构造和析构,全局变量的类型中包含构造和析构
不要添加进代码,并且要尽可能移除
原因是
1.在不同源文件中的全局变量初始化顺序是随机的
2.对启动时间有负面影响
3.附加条件对于llvm相关的库,静态构造函数会对启动时间产生负面影响

21.不要使用初始化列表来调用构造函数
当你调用一个专用或者复杂的构造函数时,最好不要使用初始化列表
因为它可能被解释为aggregate constructor(即按照顺序依次给类成员赋值)
另外当使用初始化列表初始化变量时,推荐使用等号

22.不一定要almost always auto
在增加可读性的情况下使用auto
在上下文明确的地方使用auto
在类型会被抽象掉的地方  比如迭代器类型

c++14添加了泛型lambda  .在有模板需求的地方使用它

23.切记不要因为auto的便利性而忘记它的默认行为是copy
使用auto &或auto *  除非你真的需要copy


24.注意指针序的非决定性
如果以指针作为keys存入无序容器,那么程序的输出可能不是一致的
解决方案是使用有序容器
或者使用前先排序

25.注意sort是非稳定排序

26.自包含头文件
头文件应当是自包含的,而不是依赖某些特定的包含顺序

27,库分层
a unix linker 严格的从左到右扫描一个库的依赖项,并且不回头访问
以这种方式链接,不会存在循环依赖的问题

28.尽可能的少#include
添加头文件会极大损害编译性能
但是有时候你需要类定义的话,还是要大胆的incude
不过即使是这种情况,也是存在不include的场景的
如果你只是使用指针或者引用,或者函数声明场景时的return
则不需要类的完整定义,只要声明就可以了

但是也不要过分优化,可以参考上面头文件的include顺序来减少隐式依赖

29 .keep internal headers private
对于一些复杂的类,很可能有多个cpp文件定义(一个.h文件,多个cpp文件)
这种情况下,很容易就会把一些公共接口,比如辅助类或者额外函数放在公共头文件中
千万不要这样做,这样会暴露类的内部实现

如果真的需要类似的方式,可以把公共接口放在一个私有的头文件中,让相应cpp单独包含
或者可以直接把一些辅助函数作为私有成员,这样也不会破坏类的封装


30.use namespace qualifiers to implement previously declared functions

比如在一个命名空间中声明了一个函数原型
在cpp文件实现的时候,不要打开namespace block,而是在cpp中使用using namespace xxx;
// Foo.h
namespace llvm {
int foo(const char *s);
}

// Foo.cpp  推荐这种
#include "Foo.h"
using namespace llvm;
int llvm::foo(const char *s) {
  // ...
}
// Foo.cpp 不推荐这种
#include "Foo.h"
namespace llvm {
int foo(char *s) { // Mismatch between "const char *" and "char *"
}
} // namespace llvm
这样做的好处在于如果出现定义不一致的时候,第一种会有提示报错
第二种会将cpp中的视为重载

31 use early exits and continue to simplify code
if内部不要膨胀,多个条件最好可以拆分出来

对于for循环里面使用if嵌套if
最好的方式是使用一个条件变量,当不满足条件的时候直接continue,而不是if层层嵌套

32 千万不要在return后面使用else
准确的说千万不要在任何可能打断控制流的操作后面接else 或者else if
比如  return  break continue goto

这样做的好处是可以减少缩进层数和便于阅读
但是注意对于constexpr if   这条建议不适用,删除else可能导致错误的模板实例化

33 将条件循环转为条件函数
在一些场景中,需要循环检查来决定一个flag
大部分人都喜欢直接将这个循环写在函数体内部,但推荐的写法是将这个动作转变为一个小函数,可以为static


低层次细节

34 命名规范
整体采用驼峰机制
类型命名:应该是一个名词,并且以大写字母开头
变量命名:应该是一个名词,并且以大写字母开头
说实话这个有问题啊  类型和变量容易重复  这更考验取名的艺术了
函数命名: 一个动词短语,使用小驼峰
枚举声明:整体参照类型命名,往往带有一个Kind的后缀
枚举器和公有成员 :应该以大写字母开头,参照类型的命名规则
这些公有成员通常要有一个前缀.除非它们在自己的小命名空间或者类中比如 
enum ValueKind {VK_Argument,VK_BasicBlock};
但是对于简单的方便常数,也不用前缀

命名规范中存在一个例外,就是模仿标准库的命名规范,使用小写单词和下划线进行命名
提供多种迭代器的的类可以在begin前面增加单数前缀表示区分

35 assert liberally
断言应该广泛的使用
其中要注意不要和未使用的变量这个警告产生冲头
当断言被禁用的时候,很可能会触发这个警告
1.断言值直接写在assert中
2.存在副作用的值,使用(void)变量名,来禁用未使用的值警告

36.using namespace std; 
就llvm而言  推荐显式写出标准库中的所有std
在头文件中是严禁使用using namespace std;
但是在cpp文件中,这更像是一个风格规定,其实也相当于严禁使用

如果cpp中的代码全部都是实现于某一特定空间,那么可以考虑在最上使用using namespace xxx;

37 虚函数类的一个最佳实践
如果某个类存在虚表,不论它是从哪来的
它至少有一个out-line实现的虚函数,也就是说至少有一个虚函数被实现在cpp文件
否则编译器会把虚表在所有include此类复制一份

38 对于完全覆盖的枚举值,不要使用default 
这样当枚举值增加时,对于没有完全覆盖的switch会有警告

39 鼓励使用range-based  不鼓励使用for-each

40.循环小tips

不鼓励,因为每次都计算一次end,除非容器大小会变动
BasicBlock *BB = ...
for (auto I = BB->begin(); I != BB->end(); ++I)
  ... use I ...

鼓励,只计算一次end 
BasicBlock *BB = ...
for (auto I = BB->begin(), E = BB->end(); I != E; ++I)
  ... use I ...
  
如果只是一个简单的BB->end() 其实上升的成本是很小的.但是一旦表达式变得复杂,则成本上升会很迅速
比如SomeMap[X]->end()
另外就是第二种写法可以立刻让别人知道,容器的大小不会改变

41.禁用iostream  
因为它里面有很多静态方法会注入到所有包含它的.o文件中

其他stream 比如 sstream则没有这种问题

42 禁用 std::endl
很多时候只是想换行  endl还额外搞了一次刷新

43 不要在类定义中定义函数时使用inline
因为它已经是inline了

微观细节

44 控制流前的括号增加空格,函数的不变
这个真的有点存疑

45 多使用前++而不是后++
对于原始类型没有什么区别,但是对于迭代器类型则影响很大
养成习惯总是好的

46.不要缩进命名空间  这样做的好处可以容纳在80行,并且不会过度包装
可以考虑在结尾处添加注释,表示}正在关闭哪个命名空间

47,匿名命名空间
可以理解为static的现代增强版本
但它的问题是  static可以一眼认出,匿名命名空间可能要看一大块才能发现
所有指导原则就是 匿名命名空间一定要小
并且不要将类以外的声明放在匿名命名空间中

