---
title: "cuda c++ 编程指南 12.6笔记"
date:
  created: 2025-07-30
  updated: 2025-07-30
slug: cuda-cpp-programming-guide-12-6-notes
categories:
  - CUDA
tags:
  - CUDA
  - CUDA C++
description: "cuda c++ 编程指南 12.6 学习笔记"
draft: true
---

# cuda c++ 编程指南 12.6笔记

<!-- more -->

chapter 3
cuda 核心就是 
a hierarchy of thread groups 
shared memories 
barrier synchronization 


Chapter 5. Programming Model

cuda c++ 通过定义一种叫kernels的c++函数 (__global__)
当kernels被调用的时候,它会在N个不同的cuda线程中执行N次


5.2 thread hierarchy
每个块的线程数存在显著,因为一个块的所有线程都应该驻留在同一个流式多处理器核心上,并且必须共享该核心有限的内存资源
在当前gpu上一个线程块最多可以包含1024个线程

2.块内的线程可以通过一些共享内存共享数据，并通过同步其执行来协调内存访问，从而进行协作
__syncthreads() 来设置一个强制同步点

5.2.1
内存结构
线程  拥有本地寄存器和本地内存
block share_memory
cluster  所有block的share_memory在一个簇中都是共享的
grid    全局内存


managed memory可以被系统中的所有cpu和gpu访问 

6.1
cuda指令集叫做ptx  无论是c++还是ptx都是需要经过nvcc的编译

6.11 编译工作流

离线编译

0.nvcc会先把device code和host code中分离
1.编译device code 变成 PTX code 或者二进制格式		
2.修改host部分的代码  通过替换<<<>>>    利用必要的cuda运行时函数调用PTX代码或者二进制对象加载和启动每个编译的内核
3.修改后的host coda交给其他工具编译 或者在编译过程的最后阶段作为目标代码直接交给nvcc唤醒的宿主编译器
4.上层应用可以直接链接到编译好的hostcoda或者忽略host code 直接使用cuda驱动api载入和执行ptx或者cubin


gpt解释
分离设备代码与主机代码：
nvcc首先会识别源文件中的主机代码和设备代码。设备代码通常包含了CUDA的内核函数（Kernel），这些函数通过特殊的语法<<<...>>>（执行配置）标识。

编译设备代码：
设备代码被编译成两种形式：

PTX（Parallel Thread Execution）代码：这是一种中间汇编形式，可以在多种不同的NVIDIA GPU架构上进行进一步的编译。
CUBIN对象文件：这是针对特定GPU架构优化后的二进制形式。
修改主机代码：
nvcc会修改主机代码，将内核函数的CUDA特殊语法<<<...>>>替换为必要的CUDA运行时函数调用。这些调用负责加载和启动每个已编译的内核。修改后的主机代码可以输出为两种形式：

C++代码：这部分代码需要使用其他工具（如g++或clang）来编译。
对象代码：如果在编译过程中让nvcc调用主机编译器，这部分代码会直接输出为编译好的对象文件。
链接和执行：
应用程序可以选择链接到已编译的主机代码，这是最常见的情况。也可以选择忽略修改后的主机代码，直接使用CUDA驱动API（Driver API）来加载和执行PTX代码或CUBIN对象

just-in-Time Compilation 即时编译 也叫实时编译
实时编译会增加上层应用的载入时间
但它有两个极大的好处
1.运行应用程序从新设备驱动程序带来的任何新的编译器改进中受益
2.这也是 应用程序在不存在设备的平台上编译的唯一办法

针对这个载入时间的问题  设备驱动会将已经编译的PTX代码进行缓存
这样二次使用的时候就不会重复编译  ,而且这个缓存会随着设备驱动程序的升级而失效


cuda兼容性
二进制兼容性 
只能在大版本中的小版本和这个小版本的下一个版本中兼容
无法兼容上一个小版本或者跨大版本

ptx兼容性

一旦使用-arch选项 则不能向后或者向前兼容

6.2 cuda运行时
只有载入相同cuda运行时的组件,互相传递地址才是安全的
所以的载入点都是以cuda作为前缀


6.2.1 cuda初始化
使用特定api cudaInitDevice cudaSetDevice 进行初始化
如果不使用上述api则自动选择device 0并进行自初始化
但是cuda12 之前 cudaSetDevice 并不会初始运行时

一个primary context 共享于此应用中的所有host 线程
初始化的过程中也包含了设备代码的实时编译
cudaDeviceReset会摧毁当前host指定的context 
将此设备作为当前设备的任何主机线程进行的下一次运行时函数调用将为此设备创建新的主上下文
从这里能看出context其实是在device上的



这个提示被强调的原因是为了避免在主机程序初始化和终止阶段调用CUDA接口导致的未定义行为。虽然看似在程序的初始化和终止阶段调用CUDA接口是不可能的，但实际上这种情况是可能发生的，特别是在复杂的应用程序中

主要原因包括：
全局状态的管理：

CUDA使用全局状态进行管理，这些状态在主机程序启动时初始化，在程序终止时销毁。如果在这些阶段调用CUDA接口，可能会访问尚未初始化或已经销毁的状态，从而导致未定义行为。
程序结构和构造函数/析构函数：

在C++等语言中，全局对象的构造函数和析构函数可能在main()函数执行之前或之后运行。如果这些构造函数或析构函数中调用了CUDA相关的代码，那么就可能触发这一警告。因为在main()之外调用CUDA接口可能会访问到未初始化或已销毁的全局状态。
静态和全局变量：

使用全局或静态变量初始化CUDA设备或资源，可能导致在程序的正常执行流程外访问CUDA接口。
防范措施：
尽量确保所有CUDA相关的调用都在程序的主体部分（即main()函数内部）进行，避免在全局对象的构造和析构阶段涉及CUDA操作。
对于需要在程序启动前初始化或在程序结束后清理的CUDA资源，应通过显式函数调用来管理，而不是依赖自动构造和析构

cuda12开始 cudaSetDevice 会在切换设备后显示初始化 
之前则是会在第一次调用的时候进行初始化
这次改动使得在调用cudaSetDevice 后检查返回值有必要

备注 错误处理和版本管理中的运行时函数不会初始化运行时

6.2.2
cuda内存可以被分配为线性内存和不透明的cuda array
我主要还是用第一个

1设置block大小的时候通常为32的倍数
因为一个wrap中有32个线程,它们以同步的方式运行

2block的最大不能超过1024

3资源使用情况  如果每个线程占用使用大量的寄存器或者共享内存 
那么每个块过多的线程会导致高资源竞争和低占有率 导致性能下降

线性内存也可以使用cudaAllocPitch和cudaAlloc3D进行分配,它们适用于2d或者3d阵列
而确保在访问行地址或在2D阵列和设备内存的其他区域之间执行复制时具有最佳性能
cudaAllocPitch会根据传入数据计算一个合适的pitch大小,保证内存对齐
实际使用的时候每行要按照pitch字节计算  pitch在这里的含义就是每行数据中间隔的字节
它突出的是行间距概念 所有没有叫2D

cudaAlloc3D整体功能类似  也是一个pitch 只是在使用的时候除了考虑height还要考虑depth

1. cudaMallocHost
用途：该函数用于在主机内存中分配“锁定”或“固定”的内存。锁定内存不会被操作系统交换到磁盘上，这使得GPU可以更快地访问主机内存，因为锁定内存的物理地址是静态的。
优势：使用锁定内存可以显著提高主机到设备（或设备到主机）内存传输的速度，适合于需要频繁在主机和GPU之间传输大量数据的应用。
2. cudaHostRegister
用途：此函数用于将已经分配的主机内存“注册”为锁定内存。与cudaMallocHost不同，cudaHostRegister允许开发者在不重新分配内存的情况下，将现有的主机内存转换为可由GPU直接访问的内存。
优势：这是一种灵活的方式，可以在不改变原有内存管理策略的基础上，优化现有应用程序的内存访问速度，特别是在已有大量主机内存管理逻辑的遗留代码中非常有用。
3. cudaMallocManaged
用途：该函数用于分配统一虚拟地址空间（Unified Memory）中的内存，这种内存可以同时被CPU和GPU访问，无需显式地进行内存传输操作。
优势：通过cudaMallocManaged分配的内存提供了一个简化的编程模型，开发者不需要关心内存在主机和设备之间的显式传输，这可以大大简化程序的开发和维护。此外，它还可以使CUDA运行时自动处理数据迁移，根据访问模式动态优化内存位置

只有英伟达的移动端芯片支持 pinned mem直接读取  
目前架构所有的操作都需要拷贝到显存中使用 只不过是隐式或显式而已

变量
__constant__ 常量内存
只能通过 CPU（主机）代码进行初始化。
在内核函数中只读，不可修改。
对于小数据量的访问非常快，适用于所有线程访问相同的数据

__device__ 变量的用途
跨内核函数共享数据：
__device__ 变量可以在多个内核函数之间共享数据。你可以在一个内核函数中修改 __device__ 变量的值，然后在另一个内核函数中读取或继续修改它。

全局数据存储：
__device__ 变量适用于需要在多个线程块之间共享的全局数据。例如，计数器、标志位、全局配置参数等。

持久化数据：
__device__ 变量在整个应用程序执行期间保持持久化状态，可以用于在内核函数调用之间保存数据

cudaMemcpyToSymbol 上面两个的专属拷贝方式
通过名称引用,而不是使用指针

cudaGetSymbolAddress() 获取符号地址
cudaGetSymbolSize()   获取符号大小

块内共享数据  需要使用  __shared__


6.2.3  L2缓存管理
重复访问视为持久访问
访问一次视为流式访问
可以将一部分L2强制预留给全局数据访问

但是多实例gpu mig模式 L2缓存预留被禁用
多进程服务中MPS 不能使用cuda更改L2缓存只能使用环境变量设置

这个好复杂  以后用到再说吧

6.2.4 shared memory 


一个warp确实有32个线程  但是一个sm流式多处理器可以多个warp 
一个sm中可以被分配一个或多个block 取决于sm的硬件架构
一个block中的所有线程都会由同一个SM执行。多个block可以同时分配给一个SM执行，但具体数量取决于block的资源需求和SM的硬件资源。

共享内存的核心思路是每个block中的线程只读取一部分数据.所有线程总共读取全部数据
如果共享内存设置的非常小且可以重复使用,则需要:
读取
同步
计算
同步   
这样一种流程  具体可以参考share_mem的代码示例

6.2.5 Distributed Shared Memory  (分布式共享内存)
需要最新的hopper架构  和 capability 9.0支持
所以暂时跳过

6.2.6 Page_Locked Host Memory(pinned memory)
好处1:
执行主机端与设备端的复制动作时,可以和kernel同上进行
好处2:
在某些设备上可以消除内存拷贝,通过映射地址空间的方式
好处3:
在具有前端总线的系统上，如果主机内存被分配为页面锁定，
则主机内存和设备内存之间的带宽会更高，如果另外被分配为写组合，则带宽会更大

这三个都不太懂
注意:
页面锁定的主机内存不会缓存在非I/O一致的Tegra设备上。
此外，非I/O一致的Tegra设备不支持cuda-HostRegister（）

额,这个也不太懂

6.2.6.1 Portable Memory 
通常情况下pinned mem只对分配时的当前设备有好处,如果想要对所有设备都生效(多块显卡)
要传递专用flag  cudaHostAllocPortable to cudaHostAlloc()

6.2.6.2 Write-Combining Memory
通常来说 page_locked是缓存化的  但是可以通过传递写组合flag cudaHostAllocWriteCombined
使其不在主机端L1 L2上缓存.
并且写组合在PCI总线上传输时,因为没有检查,所有传输性能会快40%
代价就是从 host读取这些内存会很慢,所有写组合内存通常用于主机仅写入内存
另外就是要避免在WC(写组合内存缩写)上使用cpu原子操作,因为不是所有cpu都保证功能

6.2.6.3 Mapped Memory
可以使用cudaHostAllocMapped 去设定映射地址,但是这种映射在两处空间(host-device)有不同的地址
可以使用cudaHostGetDevicePointer()获取设备端的地址
也就是说他俩存在地址转化,唯一的例外是使用统一地址空间(uva)的时候不需要这种地址转化

kernel访问mapped host mem 的带宽是低于普通 device mem的,但是也有几个好处:
1.不需要在分配block 然后拷贝  .整个数据传输是隐式发生的(注意依然存在copy,只是对开发人员不可见了)
2.不需要在使用stream是overlap数据传输了,在这种情况下会自动overlap

我感觉好像没啥用,,,,,

使用mapped memory的限制
1.因为mapped memory是共享的,所以应用要自己同步内存通过streams或者events 
去避免潜在的 读后写 写后读 写后写问题

这里流的使用不是为了管理数据传输，而是为了控制执行顺序和同步，以防止数据竞争和确保数据的一致性

2.使用前还要设置cudaSetDeviceFlags()  使用cudaDeviceMapHost
3.设备还必须支持mapped 功能
3.所有原子化的函数在mapped mem上面都不是原子化的
4.cuda运行时要求主机内存 1 2 4 8字节 自然对齐(几字节就是几字节的倍数)
CUDA运行时要求，从设备启动对主机内存的1字节、2字节、4字节和8字节自然对齐的加载和存储操作，
必须从主机和其他设备的角度保持为单一的访问。

有些PIC 总线拓扑会将一个8字节的写操作拆分成两个4字节的写入 这就是破坏了原子性
cuda不支持这些设备




20240806

6.2.7 内存同步域

6.2.7.1 memory fence interference
a.如果内存屏障或刷新操作等待的事务数量超过了实际需要，
这意味着GPU在完成这些同步操作之前可能不得不无谓地延迟处理其他任务。
这种过度同步可能导致资源利用率降低，进而影响程序的整体执行效率


b.内存一致性 
pdf 44页上给出了一个例子,其中sm上运行两个gpu线程,cpu上运行一个cpu线程.
gpu线程之间内存一致是相互可见的
但是cpu是系统级同步,这表示它可以看到线程2的写操作,也能看到所有线程2可见线程的写操作
上述特性称之为  累积性（cumulativity）

补充:gpu自身采用保守策略 来保证在极端情况下的内存一致性

这就可能导致一些不必要的等待操作,即在源码中没有设置同步点,但是由于内存屏障和刷新,会导致gpu等待时间更长

6.2.7.2 isolating traffic with domains
这一部分也需要hopper架构和12 以上的cuda  跳过


6.2.8  asynchronous concurrent execution

cuda可以将以下操作作为独立任务并发进行
1.在host上计算
2.在device上计算
3.从host传输到device
4.从device传输到host
5.在给定device内部进行内存传输
6.设备间进行内存传输

6.2.8.1 concurrent execution between Host and Device
以下操作对相对于主机是异步的
a.kernel启动
b.单一设备内部的内存拷贝
c.从主机拷贝小于64kb的内存到device
d.特殊异步函数的内存拷贝
e.内存集函数调用(不懂)

补充 可以通过设置 CUDA_LAUNCH_BLOCKING 为1 组织所有内核的异步性  
但是这个东西只是用来调试使用的

重要补充
1.使用性能分析工具的时候 (Nsight等)内核启动行为可能会变成同步模式 除非另行设置
2.如果内存不是pinned的那么异步copy可能会变成同步,因为这些数据可能会被交换到磁盘,交换到磁盘再想使用就需要占用cpu了


6.2.8.2 concurrent kernel execution

通常情况下cuda上下文只与一个进程关联,不同context之间是隔离的
为了推进多个进程,gpu采用时间片机制在一个device交替执行不同进程
如果希望在一个device并发执行多个进程的计算任务则必须开启MPS(多进程服务)

6.2.8.3 overlap of data transfer and kernel execution
6.2.8.4 concurrent data transfers
这种折叠内存传输首先需要被设备支持,其次如果涉及到host内存,则必须是pinned 原因同上重要补充
另外一点就是对于支持的设备,intra-device copy(设备内部拷贝,使用标准拷贝函数cudaMemcpy)是可以和以下两个东西并行的
1.kernel 计算
2.主机到设备 设备到主机拷贝


6.2.8.5 streams

流是一组命令序列,这些命令可能来自不同的主机线程,只要它们都向一个流中添加命令
不同流之间的执行可能是乱序的也可能是并发的,它们之间的行为不做保证,所以不能依赖它的执行顺序
流中命令会在所以的依赖都满足时才会执行,
依赖关系可能是同一流中的前置命令,也可能是其他流的依赖
但是这种跨流依赖往往需要同步机制(比如cuda事件)进行显示管理
流的最后需要进行同步来确保流内的所有操作都完成了

流中进行overlap of date transfer 主要有两个依赖
1.cpu内存必须是pinned
2.拷贝函数必须是异步的  后缀带有aysn

cudaStreamDestroy  如果执行此函数的时候 流依然在工作,则该函数会离开返回
当工作完毕后,释放流中所有资源

这种设计我有点不太能理解,gpt说在进行视频流处理的时候可能会有这种需求
为了提高吞吐量,容忍单帧失败
感觉没有场景需要这个功能

6.2.8.5.2 default stream

默认流是一种特殊流 它的内部存在隐式同步机制  即等待流上所有操作完成
如果开启默认流每线程,则这种情况下的流为常规流

对顺序依赖比较重和有兼容性需求的应用可以使用默认流

注意：使用nvcc编译时，不能仅通过#define CUDA_API_PER_THREAD_DEFAULT_STREAM 1来启用这一行为，
因为nvcc会在编译单元的顶部隐式包含cuda_runtime.h。
必须使用编译标志--default-stream per-thread
或在编译器标志中使用-DCUDA_API_PER_THREAD_DEFAULT_STREAM=1来定义宏。

6.2.8.5.3 explicit synchronization 显式同步
cudaDeviceSynchronize()  终极全局同步
cudaStreamSynchronize() 以一个流为参数,同步流
cudaStreamWaitEvent() 这个有点像设置函数  它是接受一个流和一个事件作为参数 只有当事件发生时才会开始执行流
cudaStreamQuery()  查询现在流干到哪了


6.2.8.5.4 implicit synchronization 隐式同步
以下几种操作会干扰stream之间的并行
1.一个 pinned host memory 被分配
2.一个是设备内存被分配
3.一个设备内存被赋值
4.两个地址处的内存被拷贝到相同device memory
5.默认流(NULL stream)中的命令
6.L1/共享内存配置之间的切换

1,2是因为要修改全局内存管理状态
3是因为要保证内存一致性
4是因为要等待相关内存区域不再被使用
5.参考之前
6.配置修改会影响整个gpu运行方式

两个流在添加命令(启动kernel)后就不应该再做上面6种操作了
因为这样会让并行的流变成隐式同步的串行
指导原则:
1.发起独立操作在依赖操作之前
2.尽可能延迟同步

6.2.8.5.5 overlapping behavior
是否折叠还取决于设备是否支持,不支持怎么都白搭

6.2.8.5.6 host function 
stream 回调  这个估计就是给那个destroy用的
stream回调会在前面完成后才开始执行,回调未完成的时候不会调用后面的函数
回调函数中不能进行cuda api调用 因为这样可能会自己等待自己 死锁

这个东西配合destroy非常的合适
回调函数可以等效视为一次隐式同步

6.2.8.5.7 stream priorities  流的优先级

The range of allowable priorities, ordered as [ highest priority, lowest priority ] can be obtained
using the cudaDeviceGetStreamPriorityRange() function. 

注意 这里并没有写反,而是更高优先级的数更小

给出的范围,可以在范围中选择任意整数选择优先级
优先级只是hint而不是强制,这只是对gpu的提示
常规流是中间到优先这部分  当然这个主要也依赖gpu和cuda的具体实现

20240807

6.2.8.6 programmatic dependent launch and synchronization

要求计算能力9.0  跳过  只有tm的h100是 9.0的计算能力

6.2.8.7 cuda graphs

cuda graph 是一系列操作  类似流 但是性能比流更好
它的主要优势在于可以减少graph中所有kernel启动的耗时 降低cpu和gpu的启动成本
因为是一个整体工作流,所以cuda可以更好的优化整体
分为三个步骤
1.definition 
创建graph中的操作和依赖关系
2.instantiation
实例化会对图模板进行快照,并验证图的结果,执行中的大部分的设置和初始化工作
这些预处理操作就是快的原因
3.执行阶段
可以把它当成一个普通的kernel放在流中执行

6.2.8.7.1 graph structure
操作是节点  依赖是边  一旦依赖关系满足,节点就会按照计算执行
6.2.8.7.1.1 Node Types
几乎所有操作都可以视为节点
特别强调 子图,空节点,外部信号交互,时间交互也可以作为节点

6.2.8.7.1.2 edge data
12.3才引入
由三部分构成 outgoing port  incomeing port   a type
outgoing port 指示何时触发
incoming port 指定节点的哪些部分取决于关联的边缘


不行 这部分完全看不懂

6.2.8.7.2 creating a Graph Using Graph APIs
图的创建有两种方式,显式api创建和流捕获

显式创建不说了就是按照api操作
流捕获则是在向流添加命令的时候,从中使用特定api进行捕获,这种情况下添加进流的任务不再是按照已排队的进行执行
而是在内部的图中执行


注意NULL流是不能被捕获的,但是可以给NULL流重新定义成cudaStreamPerThread来进行捕获
对于被捕获的流可以使用api查询,也可以使用api讲流捕获到外部图,而不是内部图

6.2.8.7.3.1 cross-stream dependencies and events
流捕获的时候可以处理以事件形式产生的跨流依赖
但是前提是这种跨流依赖的流a 流b都被捕获到一个图中


流模式的事件依赖
如果一个流b等待另外一个处于捕获模式下流a的事件,会进入以下状态
1.如果streamb不处于捕获模式,它会自动进入捕获模式(wait的时候)
2.wait之后的操作都会被添加到流a的图中

有一个重要准则,谁开始的流捕获,也要由谁结束

可以简单的理解为捕获模式下的流压根没有压入命令,压入的命令之间进入图了

6.2.8.7.3.2 prohibited and unhandled operations
1.查询和同步一个处于捕获状态的流执行状态或者一个捕获的事件都是没意义的
涉及捕获的更广泛的上下文也是没意义的(虽然不知道它在说什么)
当然,因为那会根本没有执行,东西都被放到图里面了

2.在处于捕获模式的时候要避免传统流和阻塞流  因为这俩会隐式的建立上下等待关系
而因为捕获模式中获取的命令并没有执行,仅仅记录   
这种等待依赖会破坏捕获的一致性

3.捕获模式调用任何同步操作也都是无效的,无论隐式还是显式
包括cudamemcpy 在默认流中调用

cuda9之后可以简单的默认流与流之间没有依赖关系的都是并行状态
cuda9之前 默认流开始和结束都会产生一次全局同步

当捕获模式和非捕获模式已经排队执行的操作产生关联时,cuda更倾向与报错
但是例外是进入和退出捕获模式,退出前后的依赖关联会离开斩断

4.两个图是不能通过事件等待来合并的
但是可以使用专用参数cudaEventWaitExternal来等待外部事件

时刻记着 捕获模式没有任何gpu动作执行就很好理解了

5.目前还有一小部分异步api不能在图中使用

6.2.8.7.3.3 invalidation

简单的说任何无效动作都会导致整个图的无效,并且与图相关连的图也会无效
使用cudaStreamEndCapture() 结束捕获可以是流恢复
但是图还是无效的  捕获会返回一个错误值


6.2.8.7.4 cuda user object
这玩意可有帮助管理异步工作所使用资源的生命周期
对流捕获和cuda graph很有效

这个东西很想shared_ptr ,但是它本身并不持有资源
而且它自身不会管理引用计数,需要程序员手动管理
比如使用专用的api给图传递用户对象 他会自己增加
调用相应提前设置的destroy 它会自己减少 如果到0 就会执行销毁

官方实例提供了一个新思路
设置一个user obj初始状态为1
然后将它转移给图  ,图完成后会自己减一,自动释放
就是官方样例里面用的那个api是省略版本 要注意 它没有写专用回调

下面有一下小限制
1.这个绑定在user object上的c++对象析构,是不能被cuda api等待的.
cuda api不会等你析构完再执行
2.但是你可以通过在析构函数中同步条件变量或者信号量等方式同步给程序的其他线程
3.禁止在析构函数中使用cuda api
4.但是不禁止用信号方式通知其他线程执行cuda api
前提是依赖是单向的,并且不会影响到cuda工作

6.2.8.7.5 updating instantiated graphs
cuda 图通过分离定义,实例化和执行三部分
在工作流不变的情况下，定义和实例化的开销可以在多次执行中分摊，graph比stream提供了明显的优势

对于整个图形拓扑和节点类型发生改变的情况下就不得不重新实例化graph.这就会让整体的性能下降
如果仅仅是对节点参数,比如内核参数和cudamemcpy的地址进行更新,cuda提供了一种轻量化更新的机制
无需构建整个graph

这种更新只会在下次执行时生效,不会影响本次graph图像
至于更详细的全图更新和独立节点更新暂时跳过

6.2.8.7.6 using graph APIs
cudaGraph_t 不是线程安全的
cudaGraph_t 不能与自身同时运行,它的启动是在之前启动的相同可执行图之后
graph是在流中完成,用于与其他异步工作进行排序,但是stream只用于排序,它不会干涉图中的内部并行性

6.2.8.7...
图还分为device graph 和host graph  
不过图的内容太多了,我暂时还处于看不懂的状态
跳过


6.2.8.8 event

event可以用来记录时间



6.2.8.9
当进行Synchronous时,请求任务未完成前控制权不会返回给host thread
因此可以利用专用api  cudaSetDeviceFlags()进行设置
让在这一段等待时间cpu更好的利用资源
1.yield  让出
cpu资源交给其他线程使用
2.block  阻塞 
默认行为,cpu等待任务完成
3.spin 自旋
不断检查任务是否完成,来更快的相应任务完成
但是会占用cpu资源



6.2.9 多设备协调
这个跳过,暂时没有多设备的需求

6.2.10 unified virtual address space
统一虚拟地址空间

cuda capability 大于2.0并且应用程序以64位进程运行
主机和所有设备都共享单一内存虚拟地址空间

a.可以使用cudaPointerGetAttributes来确定任何通过cuda分配内存的位置
b.内存复制的时候可以使用默认参数 让cuda自行决定方向
甚至支持未使用cuda分配的主机内存
c.使用cudaHostAlloc分配的pinned mem自动在统一寻址空间下portable
普通的pinned mem只对当前上下文设备分配的device有提升,而设置为portable后就会对所有设备生效

所有其实对于现代设备 cudaHostGetDevicePointer() 可以大大减少使用了
因为我这边应该没有低于7.0的设备了


6.2.11  interprocess communication  进程间通信
任何有主机线程创建的设备内存指针和事件句柄都可以被同进程的任意线程引用
但是它对其他进程是无效的

跨进程 ipc api 只能支持64位的linux系统上并且设备能力要大于2.0

这个应该对我也没什么用,竟然不支持win平台  挺神奇

6.2.12 error checking
所有的运行时函数都会返回一个错误码 除了异步函数
异步函数的报错只能是执行任务之前在主机上发生的错误,通常都是参数校验
如果真的发生错误,后续的一些无关运行时函数调用会报告此错误
检查异步的错误的唯一办法是检查cudaDeviceSynchronize()的返回

cudaPeekAtLastError() 获取最后一次错误
cudaGetLastError() 获取最后一次错误,并且重置错误值 也就是说无论什么错误连续两次调用的cudaGetLastError第二次一定正常

流查询和事件查询的notReady不会被视为错误码

6.2.13 call stack 调用栈

当调用堆栈溢出时,使用cuda debug会产生内核调用错误
否则则是未指定的启动错误
当内核无法确定调用栈大小时(通常由递归导致),编译的时候会产生警告

chapter 7 hardware implementation

gpu架构是围绕一组可扩展流式处理器建立的
当host调用一个kernel的时候,会生成一个grid
然后grid中的block会分配给一个或多个sm并行执行
一旦一个block完成,新的block就会在腾出来的处理器上启动

SIMT架构   single instruction multiple thread

SIMT允许多个线程通常是一个warp执行相同的命令,但是每个线程可以操作不太的数据
整体类似SIMD,但是在处理独立控制流上更灵活

gpu sm具有硬件级线程调度能力,可以在warp上快速切换,隐藏内存访问延迟
一个block内的线程共享内存和其他资源,可能成为性能瓶颈

gpu的一个warp切换极快 ,每个sm支持上百个线程

gpu指令调度通常是顺序发射
gpu也不存在分支预测和投机执行

英伟达gpu架构使用小端法

7.1 SIMT architecture
处理器在创建 管理 调度和执行都是以一种叫warp的最小单位进行
一个warp包含32个并行线程

warp中每个独立线程都开始于相同的程序地址,但是它们有自己的指令地址计数器和寄存器状态
所以它们之间可以独立执行

一个warp可以被分为更小的子集,比如half warp 和 quarter warp
block被送到sm后,它会被划分为多个warp.每个warp包含32个线程,每个warp中的线程号都是连续增加的
warp的槽位是固定的,block的线程数如果不是32的倍数会导致warp槽位空闲


这个真的有点危险啊,看来cuda里面真不能随便写if
每个warp在任意给定时刻都只执行一个共同命令,当32个线程在执行路径上一致,就实现了最高性能

如果warp中线程因为数据依赖的条件分支偏离了,那么这个warp会执行每个被采用分支,暂停不通过此分支的warp
分支偏离只发生在一个warp中,不同warp不会相互影响


如果存在分支发散现象,warp会识别那些分支走那些路径,比如有A B两个执行路径
warp会统一执行那些走A路径的线程,然后再统一执行走B路径的线程

并不是要规避if的使用,而是要尽量保证一个warp内部的线程不发生分支发散


SIMT架构于SIMD相类似的地方在原单一指令控制多条处理元素.
关键的差异在于SIMD直接暴露宽带,而SIMT则是指定单一线程的执行与分支行为
程序员写作针对独立的标量线程的线程级并行代码,以及针对协调线程的数据并行代码
如果主要关心性能,开发人员可以不用考虑warp中的分支发散,就像cpu开发中的缓存行一样
但是SIMD就不行,必须手动管理所有

volta之前的架构是一个warp中的32个线程共享一个程序计数器
因此处于分支发散或者不同执行状态的同一个warp中的线程不能相互信号或交换数据
在细粒度数据共享算法中这就很容易导致死锁风险

volta开始独立的线程调度允许线程直接充分并行
gpu为每个线程维护独立的执行状态包括pc和call stack,每个线程都有自己的控制流,不在受整个warp状态的限制
现在的执行粒度是线程级,所有现在即使是在一个warp内部,线程也可以在适当的时刻聚集与发散


参与相同指令的线程叫active threads,不在当前指令但是inactive 
线程进入inactive状态存在多种可能性
1.比其他线程先退出了(活干完)
2.走到其他分支去了,并且与warp当前执行的分支不同.
3.warp中那些压根就没有被使用的线程(warp32 block30  2个线程就是inactive)
这里补充一下  warp会优先填充block的线程,跨block的线程一定是在不同warp中的


非原子化的,同一warp的多写指令,写多少次是根据设备能力来的  ,谁最后写是未定义的
原子化的读写,同一warp,相同地址,每次都会发生,但是顺序是未知的

7.2 Hardware Multithreading 
每个warp的执行上下文在整个生命周期都维护才芯片上,所以不同执行上下文直接切换没有成本
每个流处理器都有一组32位寄存器 这些寄存器在各个warp之间分配

block warp的总数就是线程数除32 向上取整



8 performance guidelines

8.1 overall performance optimization strategies

四条基本原则
1.最大化并行执行获取最大化利用率
2.优化内存使用来最大化内存吞吐量
3.优化指令使用来最大化指令吞吐量
4.最小化内存(缓存?)抖动

优化的时候要不断检测上述情况中谁是真正的性能瓶颈来进行改进

8.2  maximize utilization  最大化利用率

最大化利用率的核心是要让整个系统中尽可能多的组件都处于忙碌状态

8.2.1 application level
从应用层面来说 最大化的并行由三部分进行  host  device  bus
优化它们的方案就是使用异步函数和stream 
让host做它擅长的串行负载,device做它擅长的并行负载

除此之外 要注意的就是线程同步问题
相同块内的线程同步可以利用共享内存和syncthreads函数高效完成

不同块中线程则必须需要共享内存来完成同步,需要两次内核调用.
因此应该尽可能使用算法映射,让需要同步的计算在一个block中完成


8.2.3 multiprocessor level

这里有两种并行级
指令级并行和线程级并行
指令级并行是指 warp调度器从自身指令中选择一条独立指令交给活跃线程支持(但是这种不是主要场景)
更多的是线程级并行 warp调度器从别的warp中选择一条指令执行

为一条指令做执行准备需要时间,称为latency  在latency时,warp 调度器可以不断选择已经准备好的指令交给warp执行
这就是充分利用

对于主流设备  (除6.0以外)
一个SM可以在一个时钟周期内向四个warp发射不同的指令
当试图隐藏一个延迟为L时钟周期的指令时,就需要4L个warp指令  这样才能吃满SM
使其等待时间被完全规避

一个warp不能立刻执行它的下一条指令
最常见的原因是输入未准备完成

如果所有的操作数都来在寄存器,并且这些操作数都依赖之前指令的写操作  这种latency就叫寄存器依赖
以7.x的设备为例  每个算数指令大概就是4个时钟周期    ,每个周期调度器可以给4个warp发射指令,以最大吞吐量计算
这就是需要16个active warp

如果warp允许指令级并行,那就是需要更少的warp,因为一个warp可以连续处理多个不依赖于其他warp或者长延迟操作的指令
比如当遇到一个长延迟等待准备结束时,warp可以继续执行它后面的独立指令,知道长延迟等待准备结束,所以就不需要多余warp保持繁忙
来维持忙碌状态

如果一些操作数驻留在片外内存(off-chip memory 除了寄存器和share都算片外内存 )则它需要更多的warp来摊平上百个时钟周期的latency
这种情况下就依赖于kernel代码和指令并行了
引入一个专用名词  arithmetic intensity  算术强度  即算术指令和内存访问指令的比率
这个比例越高越容易隐藏内存访问延迟
所以在开发过程中要提高算术强度的比率

另外一种导致暂停的原因是内存屏障和同步操作,这些等待会发生在一个block中
所以sm上有多个block ,当某些block在处于同步等待的时候其他block可以正常使用

驻留在SM上的block和warp个数取决于调用的执行设置,sm的内存资源,kernel的资源需要


执行配置指定了内核启动的线程块大小和网格大小

每个线程块所需的共享内存量是精通分配和动态申请之总和
一个sm上能驻留的block数量由寄存器使用数量和共享内存使用量控制
sm上极限就是2*512*64个寄存器
96k的共享内存(取决于具体计算能力,但总体不大)
补充说明 cuda杂类 5

8.2.3.1 occupancy calculator  占用率计算器
很贴心的准备了计算器帮助开发人员选择register和shared memory 需求

8.3 Maximize Memory Throughput  最大内存吞吐量
第一步就是让程序将低带宽的数据传输行为降到最低
这意味着最小化host--device数据传输,因为它比全局内存和device数据传输带宽低
也意味着最小化全局内存和device数据传输,因为它比 on chip内存低 shared memory 和cache

共享内存等效于一个用户手动管理的cache
以下提供一个典型场景:
针对每一个block中的线程
1.从设备内存载入数据到shared memory
2.同步这个block中的其他线程,使得每个线程都可以安全的读取由其他不同线程填充的共享内存位置
3.操作共享内存的数据
4.如果要就再次同步,确保共享内存都被写回到共享内存
5.写回结果到设备内存
很经典的结果,因为cuda矩阵乘法利用shared就是这么干的

对于 7.x之后的设备 shared memory和L1 cache 共享片上内存
不同访存模式可能会带来一个数量级的优化,所以优化访存对全局内存的访问非常重要

8.3.1 data transfer between host and device 
尽可能缩小数据传输规模
将更多的计算放在device上,即使某些任务的并行度并不高
将小的传输合并成一个大数据传输表现更好

对于只使用一次读写的内存,使用pinned map要比显式传递更好

对于集成系统 host和device内存在物理层面一致,所以使用pinned mapped memory最好
(一个经典的争论)

8.3.2 device memory accesses 
一个warp内32个线程,如果每个线程的访存地址比较分散,那这些访存指令很可能需要重复发出
这是因为warp内动作的一致性
并且不同的内存对于分散的容忍性是不一样的

A.全局内存  global memory
全局内存的一次访问  32  64  128  并且必须自然对齐
当warp访问全局内存时,它会根据每个线程访问的字的大小和线程减内存地址的分布将warp内线程的访问合并成一个或多个事务
(现在明白为啥会影响内存了吧)

并且需要的事务越多,未使用的字就越多,整体的吞吐量就会下降

因此 提高性能的关键是
1.遵循当前架构的最优访存模式
2.使用合适的类型满足对齐规则
3.填充额外字符

尺寸和对齐要求
全局内存指令要求 1 2 4 8 16字节的自然对齐 当且仅当满足这种情况,访存会被转化为一条单一指令

如果尺寸和对齐要求不被满足,访存就会变成多条指令,这种交错访问模式会降低访存的集结效应
内置标量 自动满足最优对齐
任何驻留在全局内存中的变量地址或者由运行时api返回的内存分配地址
都至少对齐到256

读取非自然对齐的8字节或16字节结构体会产生错误结果
有一个要注意的点是  当你使用cudaAlloc等api申请一个大内存池
然后自己内部存储数据时并没有手动管理,则很容易导致以上的错误结果


结构体对齐要使用专用的__align__ 关键字
struct __align__(16) {
float x;
float y;
float z;
};
__align__的主要作用是让结构体的起始地址满足自然对齐,结构体内部的成员自动使用自然对齐

这就是为啥有时候我调整结构体内部数据顺序会影响cuda 结果的原因

访问二维数组的最大化利用方式就是线程块宽度和数组宽度都是warp size(32)的倍数

这就是cudaMallocPitch() and cuMemAllocPitch()的意义,它们可以自动选择硬件最优访存模式
实现代码的硬件无关


B.local memory
(注意 这玩意不是啥好东西,和cpu编程中的栈空间不一样,5.0以后local memory是在L2上,通常global memory也在L2上
因此说 local memory和global memory 基本一致
)
主要用来存放automatic variables
1.无法确定是否用常量索引的数组
2.大结构体或者大数组,占用太多寄存器空间的
3.寄存器空间满了之后的任何变量

检查ptx代码可以查看在第一阶段是否存在local memory使用,但是不准确

使用cuobjdump可以查看最终使用,--ptxas-options=-v可以报告每个kernel的local memory的使用情况

注意 某些数学库会可能会使用local memory 因为数学计算可能会使用较多的额外空间

local memory 和global memory几乎一样慢 ,并它服从于内存合并要求和设备内存访问要求

它的唯一优势是 如果warp中的线程都是访问相同的相对地址(第i个线程访问第i个偏移)
那么它可以合并成一次内存访问事务


C.shared memory 
高贵的on chip内存,比local和global都快
它位于每个独立的sm上,并且shared memory使用等尺寸内存模型(成为bank)
如果多个线程访问不同bank的地址,那么这些地址可以同时进行   
所以理论上限的 n*bank带宽   n为访问不同bank的线程数

但是如果两个或两个以上内存访问落在了同一bank中,就会发生bank conflicts
导致这些内存访问必须串行化,这个时候硬件监测到bank conflicts就会将冲突的内存访问进行分割
这会导致原版一次可以完成的工作可能需要多次

n-way bank conflict  如果一个内存请求被分割成n个独立请求

想要避免bank confiict就要对bank行为和内存映射有深刻理解
(这就太难了吧)

D. constant memory
驻留在全局内存,但有专用constant缓存
同样受warp中thread访存方式影响(不连续的话就会被拆分成多次)
缓存命中的情况下以缓存吞吐量访存
缓存不命中的情况下以global 缓存吞吐量访存


E.texture and surface memory
它们也是驻留在设备内存,使用专用cache(texture cache)
texture cache是专门为2d空间优化过的 
当一个warp中的线程都访问靠近的地址时,可以获得最大性能

texture memory 可以提供固定的提取时间,无论缓存是否命中,如果命中的话可以减少使用带宽

如果内存读取不能遵循全局和常量的最优访问模式,那么只要能满足局部性
texture都可以提供高带宽

texture的地址转换的使用专用结构,不占用kernel

在单一操作中,打包数据可以被广播给分离变量
比如读取png图片像素的时候会一次读取多个相邻像素(这就是打包,将多个小size的内存操作打包成一个大size的
)但是使用的时候则是分配给不同的变量  

很擅长将8位或者16位整数映射到0~1 或-1~1这个范围的浮点数,这种转化是gpu进行专门适配的

8.4 maximize instruction throughput

基本方案是
a.精度换速度  使用内部函数而不是常规函数,单精度替换双精度   清零非标准化
b.减少控制流分歧
c.尽可能优化同步点

一个指令可以在warp上运行,假设一个sm在一个时钟周期内执行的操作数是N
那么在一个时钟周期内执行的指令数就是N/32

给了一堆表,但是看不懂

cuda复杂函数和指令是组合原生指令而来
可以使用cuobjdump查看,这些东西很容易变化

-ftz=true可以将非规格化数清零
-prec-div 和 -prec-sqrt(false)可以降低除法和平方根的精度 提供速度


__fdividef(x, y)可以提供更快的单精度除法  比  \操作符 快

在开启上述-pre...优化的时候 1.0∕sqrtf() 可以替换成rsqrtf() 更快
单精度浮点平方跟在cuda中实现为倒数平方跟然后倒数而不是倒数平分根后再乘法
这样做的好处是可以表达出0~无穷


计算三角函数是很昂贵的  如果入参很大,则性能代价会更昂贵
计算三角函数分为快速通道和慢速通道,入参x过大后就会走慢速路径
慢速路径的慢的原因一部分是需要更复杂的计算,另一部分则是需要使用local memory
后者导致慢速路径比快速路径慢一个数量级



对于2的倍数
使用移位操作代替除法
(i∕n) ==(i>>log2(n)) 
使用按位与计算模操作
 (i%n) is equivalent to (i&(n-1))
 
说实话这种最基本的东西nvcc自己不优化还需要我来写,有点离谱

half precision aritmetic 半精度计算
推荐使用half2类型作为半精度代替half
推荐使用__nv_bfloat162 代替 __nv_bfloat16
后缀带2的变量类型一次存储两个半精度(一对)
使用向量内联函数的时候使用上述类型,可以提高性能表现

其中  half(IEEE标准)和__nv_bfloat16(阶码更长)的区别:
__nv_bfloat16提供给更广的范围,但是精度较低,主要就是为深度学习设计,用来计算累积和权重

类型转化
有两种情况编译器会额外插入指令去转化类型   char short等使用的时候转化int
双精度浮点常量传递给单精度操作函数
(这一条说明了 在日常使用单精度的时候,即使入参是写明的常数也尽量增加后缀)


8.4.2 control flow instructions
流程控制会导致warp diverge   ,因此要尽量避免显式的流程控制
但是  编译器优化的时候会自己利用循环展开和分支断言优化if或者switch  在这种情况下可以避免diverge
分支预测技术
它不同于cpu的条件分支
分支预测不会跳过任何依赖控制条件的指令
它会为每个线程分配一个predicate  如果为真则正常执行 如果为假也会调度执行单不会进行任何操作
即不写入不读取不计算地址

根据一个实际场景来表达
假设现在有一个简单的kernel 使用一个warp 32个线程
现在有一个条件 x>0 分支A  x<=0 分支B
假设对于前16个线程 x>0 对于后16个线程 x<=0

如果进入thread diverge场景
因为warp中的所有线程再同一时刻都执行相同指令
所有会先计算前16个线程的分支A,计算完毕后
再计算后16线程的分支B

如果进入 branch predicate场景
warp为每个线程分配一个predicate
每一个线程都先后执行了分支A 分支B
根据predicate 前16个线程只有分支A有真正执行 后16个线程只有分支B有真正执行

这要做的好处显而易见,提高了并行性,减少了条件分支


8.4.3 synchronization instruction
不同设备能力的__syncthreads()不一样,8.x是一个时钟周期进行64次 
__syncthreads() 是同步一个块内的线程

8.5 minimize memory thrashing 最小化内存抖动(准确的说应该是缓存抖动)
重复分配释放会导致分配函数愈来愈慢,以下有几个建议:
a.根据手头问题调整分配规模,而不是直接分配所有可以用内存
b.在程序早期并且没用它的时候分配内存,减少分配和释放调用
c.如果设备不能获取足够的设备的内存,可以使用cudaMallocHost或者cudaMallocManaged作为让步,这样会慢,但至少可以跑
注意 cudaMallocManaged会更慢一些  因为它没有要求是pinned

d.cudaMallocManaged可以配合cudaMemAdvice 达到大部分cudaMalloc的性能
但是说实话我感觉还是没人用


10.1 function execution space specifiers

10.1.1 __global__
就是kernel
a.在设备上执行
b.在主机上调用
c.5.0以后也可以在主机上调用
ps.必须返回void  ,不能是类成员,异步执行

10.1.2 __device__
a.在device上执行
b.只能从device上调用

__global__和__device__修饰符不能混用

10.1.3 __host__
a.只能在host上执行
b.只能从host上调用
缺省修饰默认host

__global不能和__host__混用
__host可以和__device__混用
原理是为device和host各自编译一套代码 __CUDA_ARCH__可以用来指定不同平台的逻辑

10.1.4 undefined behavior 未定义行为
a.使用__CUDA_ARCH__ .在非纯host函数中调用host函数
b.未使用__CUDA_ARCH__.在host函数内部调用device

10.1.5 __noinline__ __forceinline__ __inline_hint_
不允许内联
强制内联
建议内联

10.2 variable memory space specifiers

一个在device code中普通的变量声明通常是被放在寄存器上的.但是如果发生了寄存器溢出,就会放在local memory
通常一个寄存器会放置一个元素,小型数组/结构体会由多个寄存器存储 ,如果寄存器压力过大,这部分就会被放在localmemory上

10.2.1 __device__
表明变量驻留在device上
如果直接指定变量,则该变量应该拥有以下属性
a.驻留在全局内存空间
b.拥有cuda上下文的生命周期
c.每个设备都有不同的对象
d.可以被所有线程访问,也可以被host 通过api访问

10.2.2__constant__
a.驻留在常量空间
b.同上
c.同上
ps.当有任何grid访问这个常量时,从host修改它都是未定义行为

10.2.3 __shared__
a.驻留在一个block的shared memory (它和L1 Cathe使用相同存储硬件)
b.生命周期伴随block
c.每个block都是不同对象
d.只能被块内线程访问
e.没有常量地址,因为它是随block 按块分配的

使用方式
kernel内部定义 extern __shared__ float shared[];

一个kernel中可以定义多个__shared__,但是只能有一个extern __shared__  ,它的大小由外部输入指定
如果不需要根据外部输入,而是在编译期完成设定,则可以去除extern标识 
比如  __shared__ uint s_key[SHARED_SIZE_LIMIT];

10.2.4 _grid_constant__
它的主要作用是对于值传递参数避免每个线程创建副本   要求计算能力7.0以上
并且指示在整个kernel执行过程不可变,提供更强保证

10.2.5 __managed__
a.可以直接被host和device访问
b.声明周期是整个程序

10.2.6 __restrict__ 受限指针
void foo(const float* a,const float* b,float* c)
对应这种函数 有一种理论上的风险,就是 a b c指向的区域可能重叠
(假设你的本意abc都指向不同内存)
编译器在优化是就无法自由地重排序内存操作,从而不能增强流水线,并且增加不必要的加载和存储
原生c++中没有对应方案,但是主流编译器都支持类似关键字

cuda中使用__restrict__ 标识入参,标识在其作用域内没有其他指针会指向相同内存
也就是说 被__restrict__ 修饰的指针是在其作用域内修改内存的唯一方式
注意:如果使用了__restrict__ 那所有指针变量都需要使用__restrict__
使用__restrict__可以安全的重排内存访问并且可以识别公共子表达式来提高性能
但是这会导致寄存器压力,而寄存器压力往往是kernel的性能瓶颈

所以要谨慎考虑__restrict__的使用


10.3.1 char.short int long,longlong,float,double
dim3是基于uint3类型,但不同的是它的三个维度默认初始化为1

gridDim  blockIdx blockDim threadIdx

10.5 Memory Fence Function
cuda编程模型使用弱序内存模型
即 一个线程写入数据的顺序,不同于别的线程观察到的顺序.
两个线程同时读写相同内存区域是未定义行为

All writes to all memory made by the calling thread before the call to __threadfence_block()
are observed by all threads in the block of the calling thread as occurring before all writes to all
memory made by the calling thread after the call to __threadfence_block()

先于__threadfence_block由调用线程发起的所有的写入操作到所有内存动作都可以被同block内的线程观察到,
并且这些写入操作都先于调用__ threadfence_block之后的操作

__threadfence_block是一个同步点,它的控制范围是一个block
__threadfence 控制范围是一个device
__threadfence_system 控制范围就是整个系统了 包括所有设备和host

10.6 synchronization function 

__syncthreads 这个尽量不要放在条件分支中,除非可以确保所有的线程都可以可以走如此分支
因为如果有线程跳过了的话  这里可能会一直卡住(等待所有线程到达同步点)
__syncthreads_count  统计谓词为真的个数
__syncthreads_and	 所有谓词都为真返回非0
__syncthreads_or	只要有一个为真返回非0

__syncwarp          同步一个warp中的线程,参数是32位掩码

10.10 read-only data cache load function
T __ldg(const T* address)
对于某些数据需要频繁读取但不做修改的  可以利用gpu只读缓存机制
10.11 load function
__ldcg  强制使用L1和L2缓存  高频访问,并且数据将再同一个内核执行多次
__ldca  不使用L1只使用L2  适合访问次数比较少 
__ldcs  只使用全局内存,适合只访问一次或极少,防止缓存污染
__ldlu  强调使用最后一级缓存,基本同ca
__ldcv  使用volatile cache 保证每次都是最新数据

10.12 store function 
__stwb  写入全局内存,但是会经过L1和L2 ,适用于不远的将来再次访问

__stcg  基本同上

__stcs  写入全局内存,绕过L1 适合写入不需要立即访问的场合

__stwt  写如全局内存 ,使用write-Through策略更新L1和全局内存 适用于要求数据一致性严格的场景

10.14 atomic function
atomic 函数支持32位  64位  128位 驻留在全局和shared memory
atomic只能在device上使用

atomic函数根据不同的后缀指定不同作用范围
_system  全局
无       单个设备
_block   一个block

使用atomicCAS可以实现所以的原子操作
原理就是使用循环不断的检测

这种模拟原子的方式可以用来处理复杂原子操作,并且原理可以被使用在cpu编程上(但是因为cpu线程切换开销大,通常不用) 

10.14.1 arithmetic functions
10.14.1.1 atomicAdd()
基本的类型都支持,对于向量类型,每个元素都是原子的,但不保证整体是原子的
atomicSub
说是为了可读性和兼容性才暴露的
atomicExch
用新值替换旧值,返回旧值
atomicMin
用新值和旧值比较,存入最小的,返回旧值
atomicMax
参考上面
atomiclnc  无符号的
((old >= val) ? 0 : (old+1))
返回old 通常用来当循环计数器

atomicDec  无符号
类似atomiclnc  但是减的   可以当作引用计数用

10.14.2 bitwise function
atomicAnd 按位与 不过是原子化的
atomicOr  按位或  
atomicXor  按位异或

10.16 一堆的指针转化函数  
我目前应该是用不到

10.17  栈分配函数

gpu的栈主要服务于动态分配
local memory主要服务于寄存器溢出

10.18 compiler optimization hint functions
编译器优化提示函数
这个目前不太可能用到

10,19 warp vote function 
轻量化的 __syncthreads_系列函数

1.对于nvcc  -g指使host代码保留调试信息  -G 指使device代码保留调试信息
所以调试cuda的时候 必须带上-g -G

2.cuda gdb是专用调试工具  普通gdb只能调试host代码

3.对于vscode   如果在vscode使用专用插件调试,但是你还想用命令去调试
在调试控制台 必须使用如下格式
-exec 你的命令

4.vscode工具在切换线程有快捷入口 右下


5.我终于知道cuda编程中 不建议写太复杂的kernel是啥标准了
首先cuda kernel非常依赖寄存器,这是为了提高线程执行效率
如果寄存器个数不足以支持一个kernel 就会发生寄存器溢出
一旦发生寄存器溢出,多余变量就会被转移到栈上,而栈在cuda中是非常非常慢的

可以通过--ptxas-options=-v 这个编译选项进行观察

理论上最优就是让sm上的warp基本上吃满,还没有发生寄存器溢出

大概数据就是一个sm 2048线程  65536寄存器  96kb的share memory
这三者要达到一个均衡才能实现最大性能


英伟达官方回复  解答我栈和局部内存的困惑

这是关于CUDA编程中局部内存的详细说明：

在C/C++中，线程的栈用于处理寄存器溢出。栈是每个线程局部内存的一部分。局部内存在L1中缓存。

你所说的“CUDA栈”实际上是C/C++的线程栈。这是保留的线程局部内存区域，用于存储自动或局部变量。此外，它包含函数调用的帧数据，并可以支持使用alloca进行函数范围的动态分配。参见Wikipedia上的基于栈的内存分配。

线程栈是位于全局内存地址空间的GPU局部内存分配的一部分。这种分配可以物理存在于设备内存或系统内存中。出于性能考虑，局部内存分配通常在设备内存中进行。

线程局部内存的大小由CUDA驱动程序自动控制。如果需要额外的alloca大小的栈，则可以使用cudaDeviceSetLimit(cudaLimitStackSize, sizeInBytesPerThread)指定每个线程的大小。增加这个大小可能会导致非常大的内存分配，因为分配是cudaDevAttrMultiProcessorCount x cudaDevAttrMaxThreadsPerMultiProcessor x (cudaLimitStackSize + driverStackSize + rounding)。这可能导致数百到数千MiBs的分配。

局部内存和全局内存的主要区别在于，局部内存在32个warp通道中以4字节的粒度交错。这允许当所有线程访问一个局部变量时，进行合并的内存访问。

问题

GPU的栈在哪里物理存储？ 局部内存位于全局虚拟地址空间。这些内存可以物理存在于设备内存或系统内存中。在几乎所有情况下，它都将位于设备内存中，以实现最优的延迟和吞吐量。

为什么不合并栈和局部内存？在CPU编程中，栈用于存储中间变量。 C/C++的栈位于线程局部内存中。

哪个更快，栈还是局部内存？ 这两者是一样的。

似乎文档中几乎没有提到GPU的栈。我错过了什么吗（CUDA C++编程指南12.6）？ 是的，你错过了CUDA C++编程指南中的相当多的文档。PTX ISA 8.5文档中也有有用的信息。
