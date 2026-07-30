---
title: "deepseek 3fs 代码欣赏 Status_h"
date:
  created: 2025-03-23
  updated: 2025-04-13
slug: 3fs-status
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

# deepseek 3fs 代码欣赏 Status_h

进来先做一个静态断言
static_assert(std::endian::native == std::endian::little);

静态断言发生在编译时期
所以它的用处是检查编译设备是否为小端序

主流都是小端,谁家好人会检查自己的cpu是啥序,检查就说明存在潜在的直接内存操作

<!-- more -->

然后看到一个 Status的类
注释里面也说明了 它模仿了 abseil::Status
而这个abseil::status 来自Google Abseil,google内部是禁止使用异常的,那自然而然需要一个强大的错误处理机制来代替异常
3fs这里应该是从abseil::Status中吸取了部分内容

class [[nodiscard]] Status {
  struct status_ok_t {};

 public:
  Status() = delete;
  explicit Status(status_code_t code)
      : data_(construct(code, nullptr)) {}
  Status(const Status &other) { *this = other; }
  Status(Status &&other) = default;

  constexpr static status_ok_t OK{};
  /* implicit */ Status(status_ok_t)
      : Status(StatusCode::kOK) {}
  ...省略
  }
  
 上来就很吓人,[[nodiscard]] 表示这个类不能被忽略,如果你的一个函数返回此类对象,就必须处理它,非常严谨的定义
 后面定义一个空结构体 status_ok_t {};
 连着constexpr static status_ok_t OK{};
 这就是常见手段(虽然我是第一次见)
 
 它的好处是表达特殊含义,避免原始枚举值或者数字常量.明确这是在构建一个OK的状态.
 它的另外一个好处是解耦了接口和函数,OK状态可以独立定义而不是固定位kok
 
public后是删除默认构造函数,防止出现悬空状态
然后是指定 显式构造函数 接受一个status_code_t 使用construct初始化成员变量datat
显式构造的好处就是不会隐式类型转化
接着是常规的拷贝构造和移动构造,注意这里使用了等号,说明后面会重载赋值运算符


  /* implicit */ Status(status_ok_t)
      : Status(StatusCode::kOK) {}

的作用就是方便使用,允许直接写 Status s = Status::OK; 或者直接返回 Status::OK 时都能正常工作。

下面直接先看data_是啥玩意
  static_assert(StatusCode::kOK == 0, "StatusCode::kOK must be 0!");
  static_assert(sizeof(status_code_t) == 2, "The width of status_code_t must be 16b");

  static constexpr auto kPtrBits = 48u;
  static constexpr auto kPtrMask = ((1ul << kPtrBits) - 1);

  struct StatusRep {
    String message;
    std::any payload;
  };
  static StatusRep *extractPtr(StatusRep *rep) {
    return reinterpret_cast<StatusRep *>(reinterpret_cast<uintptr_t>(rep) & kPtrMask);
  }
  struct StatusRepDeleter {
    void operator()(StatusRep *rep) { delete extractPtr(rep); }
  };
 using StatusPtr = std::unique_ptr<StatusRep, StatusRepDeleter>;
StatusPtr data_;  // |<-- low 48 bits: rep ptr -->|<-- high 16 bits: status code -->|


先来两个静态断言 kOK必须是0 和 status_code_t 必须俩字节
再考虑前面小端序的静态断言,3fs要直接做内存操作了

kPtrBits和kPtrMask 就很清晰了,常见的位运算
将1向左移动48位,1左边有48个0,然后-1
这个数就变成了 0-47位全48-63位全0的数 常见的掩码操作


StatusRep就是一个常规结构体 有一个字符串传递信息,还有一个std::any 不知道要装啥

extractPtr就开始整活了,原本的rep指针被转为了一个size_t 然后与掩码按位与
即清零rep指针的高位地址,因为64位设备上,指针只用前48位(0-47)
它这样做说明原本的rep指针的高位被复用了

StatusRepDeleter 一个仿函数,用作unique_ptr的删除器

data_就是一个std::unique_ptr<StatusRep, StatusRepDeleter>;

再来看看construct这个静态函数,用来构造data_
  static StatusPtr construct(status_code_t code, std::unique_ptr<StatusRep> rep) {
    return StatusPtr(
        reinterpret_cast<StatusRep *>(reinterpret_cast<uintptr_t>(rep.release())
                                      | (uintptr_t(code) << kPtrBits)));
  }
  
 它接受一个错误码和一个正常rep的unique指针,因为c++17之后 nullptr可以隐式类型转化成任意unique_ptr
 

看看它是怎么做的吧
reinterpret_cast<uintptr_t>(rep.release())  原本的unique 放弃所有权 拿到指针转成一个size_t
然后将错误码左移48位,16位的错误码正好放原本指针高位地址
这样一来 64bit字节的指针就完全利用了


继续回到构造函数部分
  Status(status_code_t code, std::string_view msg) {
    auto rep = std::make_unique<StatusRep>();
    rep->message = msg;
    data_ = construct(code, std::move(rep));
  }

  Status(status_code_t code, std::string &&msg) {
    auto rep = std::make_unique<StatusRep>();
    rep->message = std::move(msg);
    data_ = construct(code, std::move(rep));
  }

  Status(status_code_t code, const char *msg)
      : Status(code, std::string_view(msg)) {}

3fs活真细了,它甚至担心编译器不给它隐式转化,显式委托构造函数. 构造message还专门区分常量字符串,拷贝,右值移动,虽然都是赋值到std::string中

下面是两个赋值运算符重载
  Status &operator=(const Status &other) {
    if (std::addressof(other) != this) {
      data_ = construct(other.code(), other.rep() ? std::make_unique<StatusRep>(*other.rep()) : nullptr);
    }
    return *this;
  }
  Status &operator=(Status &&other) = default;
 
  StatusRep *rep() { return extractPtr(data_.get()); }
  const StatusRep *rep() const { return extractPtr(data_.get()); }
 
非常经典的写法,const 左值和右值完美覆盖所有范围
左值部分先检查是否相同地址,就俩字,标准
然后调用construct构造data_ ,其中 other.rep() ? std::make_unique<StatusRep>(*other.rep()) : nullptr
深拷贝创建副本

  Status convert(status_code_t code) const {
    Status status = Status::OK;
    status.data_ = construct(code, rep() ? std::make_unique<StatusRep>(*rep()) : nullptr);
    return status;
  }

  String describe() const {
    return rep() ? fmt::format("{}({}) {}", StatusCode::toString(code()), code(), rep()->message)
                 : fmt::format("{}({})", StatusCode::toString(code()), code());
  }
  std::ostream &operator<<(std::ostream &os) const { return os << describe(); }

  bool isOK() const { return code() == StatusCode::kOK; }
  explicit operator bool() const { return isOK(); }



现在来看看payloads怎么设计的
  template <typename T>
  Status(status_code_t code, std::string_view msg, T &&payload)
      : Status(code, msg) {
    setPayload(std::forward<T>(payload));
  }

万能引用(引用折叠)的 T &&payload,万能引用都是要配合完美转发std::forward
对左值右值的灵活处理,左值拷贝,右值移动

  bool hasPayload() const { return rep() && rep()->payload.has_value(); }

  template <typename T>
  T *payload() { std::any_cast<T>(&rep()->payload);
    return std::any_cast<T>(&rep()->payload);
  }


  template <typename T>
  const T *payload() const {
    return std::any_cast<const T>(&rep()->payload);
  }
这里要解释一下 std::any_cast<T>(&rep()->payload);
为什么要选择这种形式 ,下面是any_cast的两种用法
 std::any_cast<T>(some_std_any_object)
 若 T 是非引用类型，会返回一个新的对象；若 T 是引用类型，则返回引用。
 如果没东西或者不匹配是会返回异常的
std::any_cast<T>(std::any * operand)而它没东西只会返回nullptr,成功则是返回内部指针

  StatusRep *ensuredRep() {
    if (rep() == nullptr) {
      data_ = construct(code(), std::make_unique<StatusRep>());
    }
    return rep();
  }
这又是一个设计.惰性分配,如果一开始使用的nullptr创建的Status,自然也不应该申请一个预备StatusRep浪费内存
只有在真的为其添加内容的时候才需要分配

  template <typename T>
  void setPayload(T &&payload) {
    ensuredRep()->payload = std::forward<T>(payload);
  }

  template <typename T, typename... Args>
  void emplacePayload(Args &&...args) {
    ensuredRep()->payload.emplace<T>(std::forward<Args>(args)...);
  }
emplac的原地构造,比创建一个any类型再传递给payloads更高效

  void resetPayload() { rep() ? rep()->payload.reset() : void(); }
  追求一行写完的代码风格,仅仅是风格差异


  StatusRep *rep() { return extractPtr(data_.get()); }
  const StatusRep *rep() const { return extractPtr(data_.get()); }
	  
C++ 标准规定，函数重载不能仅凭返回类型不同来区分。
但在成员函数中，const 限定符是签名的一部分,所以下面那个是专供常对象和常成员函数调用的

