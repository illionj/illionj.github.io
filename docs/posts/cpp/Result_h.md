---
title: "deepseek 3fs 代码欣赏 Result_h"
date:
  created: 2025-04-20
  updated: 2025-05-11
slug: 3fs-result
categories:
  - C++
tags:
  - C++
  - DeepSeek
  - 3FS
  - Error Handling
description: "学习cpp技法"
draft: true
---

# deepseek 3fs 代码欣赏 Result_h

模板和宏警告
不要畏惧,c++不学宏和模板,丧失90%的编程乐趣

<!-- more -->

看看使用了哪些头文件
可以看到
```cpp
#include <folly/Expected.h>
#include <folly/logging/xlog.h>
```
folly开始被启用了

首先要知道folly::Expected 这是什么玩意


这个都能单开一篇,讲讲c++的异常处理
刚开始是errno处理,errno作为一个全局或者本地线程共享的的错误码
它会让函数失去pure function 纯函数主要是函数式编程的叫法,c/c++对应概念是可重入 或者线程安全函数
一个函数内部使用了外部定义变量,这个就不太好,影响编译优化,也影响安全

后来大家更喜欢用错误码 error code 
所有函数返回一个枚举类值或者整数等等 然后检查函数返回
这个也是最最常见的方案,它也可以是函数拜托全局变量的依赖
但它的问题也很明显,所有函数的返回都是整数了.出参入参都放在函数参数列表里面
影响函数形式

c++的std::exception,说实话到了2025年也没有一个真正一锤定音的结论
比如谷歌非常不喜欢异常,甚至强制禁用.道理也很有说服力,触发异常之后栈展开时间不确定
影响性能等等
微软则表示ok,微软在自己的官方教学上推荐大伙使用异常,说这是现代c++,而且异常已经优化的很好了
两家都说的没问题.适合自己就行

还有一种方案是expected ,比如c++23中引入的std::excepted.并且早在c++23之前,市面上也有很多很多的三方实现
Expected<V,E>
从形式上看就很像std::variant,存储两种类型值,v表示正常李祥,e表示错误类型
有点就是无异常和有异常执行路径时间可预测
不使用全局变量
对函数接口影响小

这个folly::Expected就是facebook自己实现并使用的一个版本


先从模板开始看

template <typename T>
using Result = folly::Expected<T, Status>;

直接定义了所有的Result都是包含原本返回值和状态的


template <typename T>
struct IsResult : std::false_type {};

template <typename T>
struct IsResult<Result<T>> : std::true_type {};
SFINAE的经典用法利用利用匹配机制来确定是否为期望类型


using Void = folly::Unit;
直接看folly:Unit的注释
/// 在函数式编程中，退化的情况通常被称为“unit”。在
/// C++ 中，“void”通常是最佳的类比。然而，由于 void 需要特殊的语法，因此它常常成为模板元编程的负担。因此，库作者可以排除这种情况，而不是编写专门的代码来处理像 SomeContainer<void> 这样的情况，而只是让库用户使用 SomeContainer<Unit>。包含的值可能会被忽略。
/// 简单得多。
///
/// “void” 是完全不接受任何值的类型。不可能
/// 构造这种类型的值。
/// “unit” 是只接受一个唯一值的类型。可以
/// 构造这种类型的值，但每次都是相同的值，所以这没什么意义。


template <typename... Args>
[[nodiscard]] inline folly::Unexpected<Status> makeError(Args &&...args) {
  return folly::makeUnexpected(Status(std::forward<Args>(args)...));
}

template <typename T>
[[nodiscard]] inline status_code_t getStatusCode(const Result<T> &result) {
  return result.hasError() ? result.error().code() : StatusCode::kOK;
}

不要懵,这是变参模板+折叠表达式
一点点来看
template <typename... Args> 变参模板的起手,表示参数个数和类型未知
[[nodiscard]] 说明这个函数的返回值必须接收
inline 内联,虽然现代编译器不会真听话,只是对编译器的提示,启发编译器内联优化
folly::Unexpected<Status> 返回值,如果发生错误了需要创建错误状态传递
&& 和forward不说了,从这也能看出来,所谓变参也就是Status的所有构造函数类型而已

比如
```cpp
#include <folly/Expected.h>
#include <string>
#include <iostream>

folly::Expected<int, std::string> divide(int a, int b) {
    if (b == 0) {
        return folly::makeUnexpected(std::string("Division by zero"));
    }
    return a / b;
}

int main() {
    auto result = divide(10, 2);
    if (result.hasValue()) {
        std::cout << "Result: " << result.value() << "\n";
    } else {
        std::cout << "Error: " << result.error() << "\n";
    }
}
```



