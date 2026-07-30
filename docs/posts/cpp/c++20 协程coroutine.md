---
title: "C++20 协程 coroutine"
date:
  created: 2024-06-23
  updated: 2024-07-21
slug: cpp20-coroutine
categories:
  - C++
tags:
  - C++
  - C++20
  - Coroutine
description: "C++20 协程学习笔记"
draft: true
---

<!-- more -->

c++20 协程
要区分协程与协程实现
就好像要区分虚函数与虚函数实现一样

协程是一种广义的函数,支持挂起和恢复

传统函数的调用和返回看csapp即可

协程是将传统函数的调用与返回拆分成三个步骤:
挂起,恢复,销毁

挂起:
挂起操作是在当前协程函数挂起点处挂起,然后传递调用权给caller.
但是不会销毁激活帧.然后挂起点处的生命周期仍然存活
注意.挂起需要在定义良好的挂起点处

恢复:
从挂起点恢复

销毁:
销毁激活帧,并且不会恢复操作

协程帧
因为协程激活帧不再保证激活帧生命周期严格嵌套.
这就意味着协程激活帧不能被用帧数据结构存储,而是用堆
(有栈协程和无栈协程)

但是把如果编译器可以证明协程的生命周期严格嵌套在caller中,那么可以将协程激活帧放在caller的栈帧中.

还有一些情况.一些变量的生命周期没有跨越挂起点,那么它们也没必要被保存
可以这么理解.协程的激活帧由两部分组成,协程帧和堆栈帧

协程帧长久存在,对照传统函数的栈帧
堆栈帧只在协程运行时存在,对照传统函数寄存器



挂起操作:
当协程到达挂起点的时候,它要先为恢复做准备.
1.将所有存储在寄存器中的值存储至协程帧
2.在协程帧中记录一个值,记录当前挂起点,使恢复和销毁操作知道起点

一旦协程完成了恢复准备,这个协程就被认为被挂起
挂起之后,传递控制权返回之前协程还可能有一个额外操作.增加一个访问协程帧的句柄.
方便后续的恢复和销毁

协程最重要的能力就是挂起之后可恢复,如果试图在它挂起之前就恢复,会产生很多竟态问题


协程也可以立刻恢复/继续协程,也可以转交控制权给caller.
但是转交控制权后,协程的stack frame就会立刻释放,回退 堆栈

恢复操作:
一个协程处于挂起状态时,可以执行恢复操作

这个恢复的方式就是调用挂起操作中的协程句柄上的void resume方法
这个方法会分配新的栈帧,并且传递操作到挂起点
一旦协程运行到新的挂起点,或者运行完成后,就会返回resume


销毁操作:
销毁操作不会resume协程,销毁操作只能发生在挂起状态
销毁和恢复是极像的,它都会激活协程帧,包括重新分配栈帧和存储caller的返回地址
但是不同于传递执行到协程内部挂起点而是传递执行到一个新代码路径,该路径在挂起点处调用所以局部变量的析构函数,然后释放协程帧内存

类似resume操作,销毁操作通过调用destroy方法,方法来自协程帧句柄,句柄在挂起的时候定义




协程return


协程的co_return做的更多,它的返回值没有被直接返回给调用者,而是先被保存在某个地方.
这个地方可以自定义
co_return之后会销毁作用域中的局部变量,但不会销毁参数,因为参数在协程帧中
协程还可以执行一段额外逻辑
比如:
1.将返回值发布出去
2.通知等待的其他协程
3.进行一些清理动作

co_return之后还可以挂起或者销毁
完成之后控制权返回给resume的人,协程返回不是立刻传给caller,而是先被保存
然后调用者通过get或者result去显式获取
也就是说协程函数返回的是协程对象,而不是结果


协程理解
理解co_await操作

c++ coroutines的核心组件是co_await
新的coroutines带来了新的关键字
co_await co_yield co_return

但这些基础组件抽象级别太低,不适合直接使用,应该由库作者封装成高级抽象

有趣的地方在于,c++协程没有定义各种细节,比如如何返回,什么适合恢复,怎么处理异常
它的做法更像标准库中通过定义begin和end 与iterator类型来做各种个性操作

真正由协程定义的就是两个接口
promise和awaitable
promise指定了定制协程行为的方法,调用后会发什么,返回会发生什么等等
awaitable指定了控制co_await的表达式,当一个值为co_await时,代码会被转化为对可唤醒对象上的方法的一系列调用.这些方法允许它指定:是否暂停当前协程,在暂停后执行一些逻辑安排协程稍后恢复,等等

co_await 是一个新的施用于变量的一元运算符.
支持co_await的操作叫做awaitbale



Channel<std::string> result_queue;

Task<void> spawn_reader(std::string file) {
    std::string content = co_await read_file(file);  // 🔥 多线程运行
    co_await result_queue.push(content);             // ✅ 在 resume 所在线程 push
}

Task<void> main_task() {
    co_await spawn_reader("a.txt");
    co_await spawn_reader("b.txt");
    co_await spawn_reader("c.txt");

    for (int i = 0; i < 3; ++i) {
        auto result = co_await result_queue.pop();       // ✅ 谁先来先处理
        std::cout << "[main] got result: " << result << "\n";
    }
}

协程辨析

协程是一种广义的函数,运行暂时挂起和稍后执行
对于常规函数只有call和return操作
下面都是csapp里面讲过的内容,出于对作者的尊重我再学习一遍
call创建栈帧,挂起调用函数,传送控制权至被掉函数起点
return 向调用者传递返回值,销毁栈帧,恢复控制权至刚刚调用函数的位置

关于激活栈帧
以x86_64,c语言标准调用约定为例
16个寄存器分为caller saved和callee_saved
熟悉的rax rcx就属于caller saved
RBX和RBP等属于callee_saved   前者通常用来储存GOT基址 后者通常用来储存栈帧指针

对于caller saved,callee可以随意使用,因为调用者负责保存
对于callee saved ,调用约定规定,这些寄存器,进入和返回之前必须保持一致.其实也能用,只要callee
返回的时候push回来就行


讲理论的文章暂时停一停
先直接看看用法
任何包含co_await和co_yield和co_return关键字的都是协程
co_await挂起执行,直到返回
co_yield 返回一个值之后挂起
co_return 返回值以完成执行

每个协程都有一个要求很多的返回类型
协程不能是可变参数,不能没有返回void 不能使用占位符返回 (auto)
consteval 函数,constexpr 函数,构造函数,析构函数和主函数不能定义为coroutines

每个协程都涉及如下组件:
promise object 协程内部控制,协程向其提交自己是结果或者异常
coroutine object 从协程外部进行操控.它是一个non-owning handle,表示它不控制协程栈帧的生命周期
coroutine state  协程状态
包含 promise对象,
参数(全部按值拷贝),
当前挂起点的某种表示,方便恢复的时候知道从哪恢复,销毁的时候知道局部变量在作用域的哪里
当前生命周期跨越挂起点的局部变量和临时变量

实战
awaitable结构体
通常是写一个函数,函数内部定义结构体,但是返回这个定义结构体的实例化
只要结构体满足await_ready await_suspend/await_resume
