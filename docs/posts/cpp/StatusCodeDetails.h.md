---
title: "deepseek 3fs 代码欣赏 StatusCodeDetails.h"
date:
  created: 2025-02-23
  updated: 2025-03-16
slug: 3fs-status-code-details
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

# deepseek 3fs 代码欣赏 StatusCodeDetails.h

这个头文件主要是定义一些错误量含义的

但是也玩的很花哨

<!-- more -->
首先它有一个单独的头文件  就是StatusCodeDetails



这里面没有任何引用 
单看这个文件纯粹就是

```cpp
#ifndef RAW_STATUS
#define RAW_STATUS(...)
#endif

#ifndef STATUS
#define STATUS(...)
#endif

#define COMMON_STATUS(...) RAW_STATUS(__VA_ARGS__)

COMMON_STATUS(OK, 0)
COMMON_STATUS(NotImplemented, 1)

...

#undef RAW_STATUS
#undef STATUS
```

看起来很懵逼  这是啥玩意  ,说实话我也是玩宏的熟手 也没看明白


接着再看 StatusCode.h 这个文件
一上来先定义了 using status_code_t = uint16_t;

```cpp
#define RAW_STATUS(name, value)                   \
  namespace StatusCode {                          \
  inline constexpr status_code_t k##name = value; \
  }

#define STATUS(ns, name, value)                     \
  namespace ns##Code {                              \
    inline constexpr status_code_t k##name = value; \
  }
```
  
接着引入 `#include "StatusCodeDetails.h"`。

也就是说StatusCodeDetails中的内容全部被宏展开了,展开方式按照上面的定义

接着定义了一个枚举类 里面定义了状态类型
然后使用一个专用命名空间 定义了三个处理的函数
1.status_code_t转字符串
2.status_code_t转枚举类型
3.status_code_t转int

再来看看StatusCode.cc 就是上面的头文件的cc文件

精彩的来了
为什么需要StatusCodeDetails?
因为StatusCodeDetail中内容会被复用

```cpp
std::string_view toString(status_code_t code) {
  switch (code) {
#define RAW_STATUS(name, ...) \
  case k##name:               \
    return #name;
#define STATUS(ns, name, ...) \
  case ns##Code::k##name:     \
    return #ns "::" #name;
#include "StatusCodeDetails.h"
#undef RAW_STATUS
#undef STATUS
  };
  return "UnknownStatusCode";
}
```

```
#name 表示直接现实入参名字
##则是拼接
```


直接就把整个作为转化非常高效简洁发方式给搞出来了
