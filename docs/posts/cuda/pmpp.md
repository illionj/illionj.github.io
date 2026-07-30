---
title: "大规模并行处理器程序设计 Programming Massively Parallel Processors: A Hands-on Approach"
date:
  created: 2026-03-30
  updated: 2026-05-30
slug: pmpp-notes
categories:
  - CUDA
tags:
  - CUDA
  - Parallel Programming
description: "PMPP 学习笔记"
draft: true
---

# 大规模并行处理器程序设计 Programming Massively Parallel Processors: A Hands-on Approach

<!-- more -->

1.1 heterogeneous parallel computing

异构并行编程 分两个方向
一个方向是 multicore  增加cpu的核数,并且保持单核的能力
另外一个是 many-thread 专注于并行应用程序的执行吞吐量


flops历史和实践双重决定的,大部分的运算场景都是浮点数
flops通常是统计一个fma  就是a*b+c
除了flops以外还有throughput和latency

gpu与cpu之间在峰值性能的巨大差距,已经形成了显著的电势积累,必须做一些让步
事实上大伙已经开始这么做了

为什么cpu和gpu的性能差距这么大呢?
因为这是两种设计理念的碰撞
对于cpu,算数单元和操作数据传输逻辑都以增加芯片大小和单个核心功耗的代价换取最小化算式操作延迟.
大缓存是为了讲高延迟访问转变为低延迟访问
复杂的分支预测和执行控制逻辑去减少条件分支指令的延迟
通过减少操作的延迟,cpu硬件减少了单独线程的执行延迟

然而，低延迟算术单元、复杂的操作数传递逻辑、大型缓存存储器和控制逻辑消耗了芯片面积和功率，
而这些芯片面积和功耗本可用于提供更多的算术执行单元和存储器访问通道。

cpu这种设计方法通常被称为面向延迟的设计 latency-oriented design

gpu由于是迫于先进电子游戏的需求(视角变换和物体渲染)发展来到
另外每秒执行大量内存访问的需求同样重要,甚至更重要
图形应用受限于内存带宽,gpu必须能将非常大的数据移入或移出图形帧缓冲区
更加松弛的内存模型,也同样被游戏应用支持,因此gpu更容易支持大规模并行的内存访问

传统的多功能处理器需要满足传统操作系统,应用,io设备,所有它更难适配大规模运算中并行内存访问
因此gpu对cpu在内存带宽上大概有10倍以上的优势

减少延迟比增加吞吐量更昂贵
翻倍吞吐量很可能需要翻倍芯片大小和功耗
-横向扩展增加两倍alu/mac单元,整体大致翻倍
-一阶近似

而将延迟降低一半,可能需要多倍的芯片大小和4倍功耗
-CMOS 动态功耗公式： p约等于cv^2f  和频率成正比和电压平方做正比
延迟越低就需要要强的导通性,更低的门延迟,更到的电容冲放电速度,因此都需要更到的电压
所有直觉上会有4倍功耗

所以gpu的主流方案是优化大量线程的执行吞吐量而不是降低单个线程的延迟
这种方法允许流水线存储通道和算数运算具有长延迟来节省面积和功耗
因此在一块芯片上允许更多的内存访问和运算单元,因此增加了总执行吞吐量

gpu这种设计方法被称为面向吞吐量的设计(throuhput-oriented design)



对于线程少的cpu快,对于线程多的gpu快
cuda: compute unified device architechture
由英伟达在2007年提出,联合gpucpu运算

也回答了一个重要问题,为什么英伟达在最初选择cuda,去复用消费级显卡,而不是另起炉灶去做专门的计算卡
因为专门计算卡这条路在过去几十年已经被证明走不通,市场环境太小,开发人员不会将目标硬件定为小众计算卡,否则将无法开发覆盖成本
This has been a major problem with traditional parallel computing systems 
that have negligi-ble market presence compared to general-purpose microprocessors.

而消费级显卡有着最庞大的装机量,如此大的市场份额使这些GPU成为应用程序开发人员在经济上具有吸引力的目标
开发人员就会为cuda和英伟达gpu开发软件,生态由此建立


1.2 why more speed or parallelism?
都是些套话

1.3 speeding up real applications

加速比  seedup

慢的耗时除以快的耗时得到加速比

再次提了一嘴阿姆达尔定律,如果程序本身并行化程度不高,即使将并行化部分得到了100x的加速,整体加速也不足

除了并行化,还有一个重要因素  数据从内存读取和写入的速度

在实际情况中,对应用程序进行直接简短的并行化,会快速耗尽内存带宽,导致加速比只有10x
因此通常需要采用各种优化变换,使用cpu上的专用存储器(on-chip memory),减少对dram的访问次数

做到这一步还不够,由于片上内存有限,还需要进一步优化代码,以突破限制


说了一个桃子比喻
适合顺序执行的部分好似果核,对这些地方执行并行化,就好像咬到果核上
虽然顺序执行部分的代码会很多,但执行耗时往往不多,cpu非常擅长执行顺序代码
适合并发化的部分好似果肉,原本的gpgpu方案只能吃掉一点果肉,因为它只能处理像素汇总形式的计算任务
cuda的意义就是覆盖更大的果肉部分

1.4 challenges in parallel programming
高性能并行编程时所面临的若干挑战
首先也是最重要的一点:
设计并行算法的时候,要使其具有与顺序算法相同级别的算法复杂度(计算复杂度),往往非常困难

因为有时候并行算法会增加工作量,以至于在处理大型数据输入的时候,它比顺序执行更慢
这尤其是个问题,因为我们采用并行算法就是为了快速处理大规模输入数据集

还有一些重要的算法基本操作,比如前缀和,它们能把原本基于顺序递归的形式转换为更适合并行执行的形式

其次,许多应用程序的执行速度会受到内存访问延迟(latency)和/或带宽吞吐量(throughput)的限制

这部分应用被称之为 内存受限型(memory-bound),
与之相对应的是计算受限型(computer-bound),计算受限型主要受限于每字节数据做需执行的指令数量
::这个定义很巧妙啊,"每字节数据做需执行的指令数量",作者没有用每字数据的执行时间,而是指令数量这样客观不受环境因素影响的指标

第三
并行程序的执行速度通常比对应的顺序程序更容易受到输入数据特性的影响

差异性极大的数据,例如变换剧烈或者难以预测的数据规模,以及不均匀数据分布
会让不同的并行进程的工作量不均衡,从而显著降低并行执行效率

对此有数据分布规整化(regularizing data distributions)和动态调整线程数量等技术来应对

第四
有些应用进行并行化,但线程之间不需要进行协作,这类应用成为天然并行(embarrassingly parallel)
而另一些就需要应用则需要线程协作,因此需要使用屏障(barrier),原子操作(atomic operations)等同步机制

这些同步机制会带来额外开销


1.5 related parallel programming interfaces
相关并行接口

用于共享内存多处理器系统的openmp
用于可扩展集群计算的消息传递接口MPI(message passing interface)


程序员通过向 OpenMP 编译器提供关于循环的 directives（指令）和 pragmas（编译提示），由编译器根据这些信息自动生成并行代码。

OpenMP 最初是为 CPU 执行设计的，后来也扩展支持 GPU 执行。

openmp的优势是通过编译器自动化和运行时支持,帮助开发人员屏蔽了大量并行编程的底层细节
并且在不同厂商之间和相同厂商的代际系统之间方便移植

这种被称为性能可移植性(performance portability)


MPI则是用于集群计算的编程接口,其中集群中的各个计算节点不共享内存
所有的数据共享和交互都通过显式的消息传递完成

MPI 的困难之一在于：不同计算节点之间没有共享内存，因此程序员必须显式地做数据划分和通信管理；
而 CUDA 在 GPU 内部提供了共享内存，因此线程之间协作更容易一些

对于 HPC 并行程序员而言，理解如何在现代采用多 GPU 节点的计算集群中进行 MPI/CUDA 联合编程，是非常重要的
与 CUDA 类似，OpenCL 编程模型也定义了语言扩展和运行时 API，使程序员能够管理大规模并行处理器中的并行执行和数据传输。

与 CUDA 相比，OpenCL 更依赖 API，而较少依赖语言扩展。

这种设计使得硬件厂商能够更快地适配现有编译器和工具，以支持 OpenCL 程序。

OpenCL 是一种标准化编程模型，也就是说：使用 OpenCL 开发的应用程序，可以无需修改地在所有支持 OpenCL 语言扩展和 API 的处理器上正确运行。


1.6 overarching goals
首要目标

教会读者如何为大规模并行处理器编程
不需要大量硬件方面知识,但需要对并行硬件架构具备良好的概念性理解

其次
高性能还不够
还需要易于调试,方便长期使用
通过专注于数据并行（data parallelism），应用程序能够同时实现高性能与高可靠性。

最后,实现面向未来硬件代际的可扩展性（scalability）。
让未来的新型机器能更高效的运行你的代码
关键在于对内存数据访问进行规整化(regularize)和局部化(localize),从而极可能减少关键资源消耗以及数据结构更新冲突

1.7 organization of the book


2.Heterogeneous data parallel computing
数据并行指的是计算工作可以作用于数据集的不同部分,因此可以相互独立工作.并且能相互并行工作
数据并行（data parallelism）指的是这样一种现象：
对数据集中不同部分所进行的计算工作，可以彼此独立地完成，因此这些计算也就能够并行执行

2.1 data parallelism
作者举了一个图像处理中的例子
rgb变灰度的处理
每个像素的变化都是独立,不会被干扰的,所以可以并行执行


这就是数据并行 data parallelism
另外还有任务并行
比如io和计算,是不同的任务,更多任务并行的问题会在stream中讨论

2.2 cuda c program structure

这部分我已经很熟悉了,但还是可以记录一些

每个cuda c 源文件都可以同时包含 
主机代码 host code
设备代码 device code

设备代码中包含一些函数,也就是kernel ,这些函数会以数据并行的方式执行

虽然示例中的cpu和gpu执行没有overlap,但实际上许多异构计算程序都会管理重叠cpu和gpu的执行来提高效率

和传统cpu编程中不同的是,gpu创建和调度线程非常快,而不是耗费几千个时钟周期

2.3 a vector addition kernel

代码见 learn_cuda
作者提醒:这种"透明"的外包模型效率很低,因为它需要在主机和设备端频繁的传输数据


现在已经开始埋伏笔了(技术书籍埋伏笔是好事)
1.要利用host端和device端的overlap
2.减少data tranfer 

2.4 device global memory and data transfer
当前的cuda 系统中,device都有自己 DRAM,通常被称为global memory 也就是显存


介绍cudaMalloc cudaMemcpy cudaFree

2.5 kernel functions and threading

单程序多数据
single-program multiple-data
注意与sigle-instruction multiple data的不同
SPMD只是说对数据的多个部分执行相同的程序,不需要同时执行相同部分的指令
simd则是要求处理单元在任何时刻都执行相同指令


当kernel启动的时候,cuda运行时启动一个线程网格,按照两级层次结构划分
+ grid
 + block
  +thread
  
对于一个给定的线程grid,每个block中的线程数量可以通过一个名为
blockDim的内建变量获得

blockDim是一个结构体,其中包含三个无符号整数
x y z


kernel launch 真正形式是
kernel<<<dim3(...), dim3(...)>>>();

threadIdx 当前thread坐标


blockIdx 当前block坐标


blockDim block里有多少thread

gridDim grid里有多少个block

想象一下,grid是一个立方体
它是有相同形状的block立方体组成的
gridDim表示grid的长宽高上由多个block
因此使用gridDim和blockIdx可以实现block一维顺序和三维顺序的转换
blockDim表示block的长宽高上由多个thread
当指定某个block后,可以使用threadIdx和blockDim,可以实现thread的一维与三维结构的转换


但gpu底层依然是线性了,RDAM这种东西的抽象逻辑说到底还是一个超长一维数组
grid block thread只是做了一次坐标映射


那为什么不做成无限维度,或者只保留一维
因此cuda的核心目标就那么几个

3维已经足够保留绝大多数空间语义


它的作用是帮助程序员将线程组织成一维数据,二维数据和三维数据
对于一维组织,只用到x
二维则是xy ,三维则是xyz

线程的组织方式通常反映数据本身的维度

通常建议:
线程块block每个维度的线程数量最好是32的倍数,这是出于硬件执行效率的考虑


kernel不会访问host内存

cuda c 特有关键词 __globla__ 表示
1.它是一个kernel函数
2.它可以被调用,在设备上生成一个线程grid

kernel函数的特点:
1.在设备端执行
2.可以由主机端调用

动态并行（dynamic parallelism）的 CUDA 系统中，它还可以由设备端调用

另外还有__host__ 和__device__

注意函数声明的时候可以同时声明__host__和__device__.编译器会生成两个版本


    vecAddKernel<<<ceil(n/256.0),256>>>(A_d, B_d  , C_d,n);
	使用浮点数 256.0，是为了保证除法结果为浮点值，从而使 ceil() 能够正确执行向上取整

还挺细节
SM（Streaming Multiprocessor）容量
GPU 的一个 SM 上，通常会同时驻留多个 block
CUDA 的最小调度单位不是 thread，而是：warp

Warp 是调度单位，但 Block 是资源管理单位
__syncthreads()
是 block 级同步。

1024-thread block：
32 warps 被强耦合

所有128~256是英伟达官方推荐的block大小

这些线程块可以以任意顺序执行。

程序员不应当对它们的执行顺序做任何假设。


2.7 compile
传统c语言编译器已经无法识别带cuda关键字的文件了
因此需要nvcc登场
nvcc会将传统的host函数交给系统c编译器编译 gcc/clang

对于cuda部分代码
则是先生成ptx (Parallel Thread Execution)
有点类似于jvm的字节码或者llvm IR
这样做的目标是克服不同gpu架构指令集细节不同的问题

因此nvcc其实是两阶段编译
CUDA C -> PTX
PTX -> GPU machine code  (Device just-in-time compiler 即时编译器)

ptx是什么时候被转化为gpu机器码(saas)
JIT的意思也就是程序会在kernel第一次运行的时候编译

但是现代cuda程序fatbin会在nvcc编译的时候
直接生成对应架构的sass和ptx
比如当我指定架构的时候
CUDA C：

↓

PTX（中间IR）

↓

ptxas：

↓

sm_120 对应 SASS

↓

打包进 fatbin

编译器内部仍然“经过 PTX”,但用户层面不感知

编译细节
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ nvcc -V
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2025 NVIDIA Corporation
Built on Wed_Jan_15_19:20:09_PST_2025
Cuda compilation tools, release 12.8, V12.8.61
Build cuda_12.8.r12.8/compiler.35404655_0
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ nvidia-smi
Thu May 21 15:25:17 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 570.153.02             Driver Version: 570.153.02     CUDA Version: 12.8  

这里的逻辑是这样的

(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ cuobjdump --dump-sass vecAdd_cu

Fatbin elf code:
================
arch = sm_52
code version = [1,7]
host = linux
compile_size = 64bit

        code for sm_52

nvcc vector_add.cu -o vecAdd_cu
现代cuda生成的fatbin中会包含ptx和saas
因为我没指定架构,所以它会生成兼容性最强的saas
sm_52表示Compute Capability 5.2 

因此当我执行./vecAdd_cu的时候在
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ ls -lh ~/.nv/ComputeCache
total 0
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ ./vecAdd_cu 
C_h[0]=3
C_h[1]=5
C_h[2]=7
C_h[3]=9
C_h[4]=11
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ ls -lh ~/.nv/ComputeCache
total 8.0K
drwx------ 3 saimo saimo 4.0K 5月  21 15:32 1
-rw-rw-r-- 1 saimo saimo   32 5月  21 15:32 index

可以明确看到缓存产生,也就说通过jit生成了我对应架构的saas

当我指定架构的后
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ nvcc -arch=sm_120 vector_add.cu -o vecAdd_cu
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ cuobjdump --dump-sass vecAdd_cu

Fatbin elf code:
================
arch = sm_120
code version = [1,8]
host = linux
compile_size = 64bit

再次执行就不会产生缓存
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ ls -lh ~/.nv/ComputeCache
total 0
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ ./vecAdd_cu 
C_h[0]=3
C_h[1]=5
C_h[2]=7
C_h[3]=9
C_h[4]=11
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ ls -lh ~/.nv/ComputeCache
total 0
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ 

查询当前架构
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ nvidia-smi --query-gpu=name,compute_cap --format=csv
name, compute_cap
NVIDIA GeForce RTX 5090 D, 12.0
(miniforge3) saimo@saimo-LEGION-REN9000K-34IAS:~/wangxiaolei/learn/learn_cuda/1.vecAdd$ 

假设我的fatbin是由多个文件编译而成的 假如触发了ptx的jit,它们是一次完成编译,还是执行到哪个文件编译哪个文件
第一次用到哪个kernel，
才JIT那个kernel所在module
lazy module loading



2.8 summary

补充说明一下cuda的编译链接逻辑
nvcc不仅充当了编译器,它其实还是一个调度器

step1 nvcc orchestration

nvcc a.cu b.cu -o app

nvcc 作为 driver，负责调度：
  - host compiler: g++ / gcc
  - device frontend
  - ptxas
  - nvlink
  - fatbinary
  - host linker


step2 host/device split

a.cu
  -> a_host.cpp
  -> a_device intermediate

b.cu
  -> b_host.cpp
  -> b_device intermediate

注意：
  这里不要直接写死成 ptx / cubin / device obj。
  它们是后续不同阶段的产物。


step3 host compile

g++ -c a_host.cpp -> a_host.o
g++ -c b_host.cpp -> b_host.o

这些是普通 host ELF object。
里面包含：
  - CPU code
  - host stub
  - kernel launch wrapper
  - fatbin registration 相关代码

step4 device frontend compile

device frontend / NVVM:

a_device source -> a_device.ptx
b_device source -> b_device.ptx

PTX 是 GPU 虚拟 ISA / IR，
还不是最终 GPU 机器码。


step5 device assemble / compile

ptxas:

如果不需要 RDC / device link：

  a_device.ptx -> a_device.cubin
  b_device.ptx -> b_device.cubin

如果需要 RDC / device link：

  a_device.ptx -> a_device relocatable device object
  b_device.ptx -> b_device relocatable device object

relocatable device object 里面有：
  - GPU machine code
  - device symbol table
  - device relocation
  - unresolved device extern


step6 device link, only if needed

nvlink:

输入：
  a_device relocatable object
  b_device relocatable object

输出：
  linked device image / linked cubin

主要处理：
  - __device__ 函数跨 TU 引用
  - device symbol resolution
  - device relocation
  - 合并 device sections
  
  
step7 fatbin packaging

fatbinary:

输入：
  linked device image / cubin
  PTX fallback, if preserved
  metadata

输出：
  fatbin

fatbin 是运行时 payload 容器，
不是 linker。
	
step8 embed fatbin into host object

nvcc 生成或合成 host-side registration object：

  __cudaRegisterFatBinary(...)
  __cudaRegisterFunction(...)

fatbin 被放进 ELF section，例如：

  .nv_fatbin	
	

step9 final host link

g++ / ld:

输入：
  a_host.o
  b_host.o
  CUDA registration object
  .nv_fatbin payload
  libcudart
  libc / libstdc++

输出：
  app



启动流程	
step1 program startup

OS loader:

  加载 app
  加载 libcudart.so
  加载其他 host 动态库
  
step9 CUDA registration at runtime

程序初始化阶段：

  __cudaRegisterFatBinary(fatbin)
  __cudaRegisterFunction(kernel metadata)

cudart 建立映射：

  host stub / kernel symbol
      -> fatbin 内的 GPU entry
	  
step2 kernel launch

原始代码：

  kernel<<<grid, block>>>(args)

nvcc 已改写成：

  cudaLaunchKernel(...)

运行时路径：

  host stub
    -> cudart
    -> CUDA Driver API / libcuda.so
    -> NVIDIA kernel driver
    -> GPU command processor
    -> SM 执行 SASS
	
	
用自己的话总结一下cuda是怎么玩的呢	
那个cu文件里面的host部分交给g++/clang++编译不提了
然后kernel部分,搞个wrapper(cudaLaunchKernel,一个符号),占个位置

然后那些kerenl,device代码这些通过编译器链接器,变成fatbin,里面包含了所有需要的东西 ptx sass
然后这些机器码被放进了host-side编译出来的东西的ELF section里面,并且nvcc在host-side里面生成专用的注册函数

原本的 kernel<<<grid, block>>>(args)变成了  cudaLaunchKernel(...) 一个普通函数来自cudart(严格说是一个符号,这个符号怎么定义是cuda内部的事情)

然后当实际运行的时候,nvcc 生成的注册代码把 fatbin 注册给 cudart
cudart/driver 知道 host-side kernel stub ↔ device function 的对应关系
第一次需要时创建 CUDA context
加载合适的 cubin/PTX module，必要时 JIT
kernel launch 时传 grid/block/shared memory/stream/args
driver 把 launch 命令提交给 GPU


最后就是我们看到的效果



从这里我们可以看到,cuda叫compute unified device architechture不是白叫的,人家确实配得上unified
因为我们完全可以使用不cuda的方式去干cuda的活,比如直接调用驱动层的kernel lanch,然后把机器+参数传进去

fatbin 嵌入 host ELF
优点
编译期类型检查好；部署简单；host/device 版本天然匹配；C++ 模型自然；静态库和模板更方便
缺点
解耦弱；不方便热更新；kernel 资源藏在 host binary 里


外置 fatbin/cubin/PTX + Driver API
优点
解耦强；可插件化；可运行时选择/替换；适合框架和 JIT
缺点
需要手动管理符号、参数 ABI、版本、路径、加载、错误处理

这种外置的方案已经类似opencl的实现方式了


3.multidimensional grids and data
本章主要讲解多维结构的grid

3.1 multidimensional grid organization

一个grid 是一个三维结构的block数组
一个block是一个三维结构的thread

gridDim和blockDim是一个内置变量,名称不可改变
gridDim的x 范围是 1~2^31 ,而y和x是1~2^`6

因为一维最常用,所以一维留的最大
CUDA 允许你在一个 kernel launch 中最多“编号”和“调度”这么多 block，而不是说这些 block 会同时存在或同时执行

但是block是内置线程上限就是1024,这个1024由blockDim的xyz贡献



一个由y行x列的矩阵
dim(x,y)的语义= pytorch tensor(y,x)=cpp mat[y,x]
因为python和cpp都强调元素的嵌套
而cuda的dim强调空间坐标轴的坐标
对于cuda来说 x是横坐标,y是纵坐标
横坐标上4列,因此x是4
纵坐标5行因此y是5

shape / dim3 / index notation 是不同的描述方式；真正的内存最终都是一维连续地址
但是对于
内存模型都是一维数组 对于5行4列的矩阵 都是4+4+4+4+4 这种排布



3.2 mapping threads to multidimnesional data

重温了一下映射关系,并且内存模型就是一维数组
因为二维数组需要在编译期知道大小,因此cuda的底层内存排布还是一维,程序员自己掌握索引变换的权力

所以引入了
row-major layout 和 column-major layout
行优先是c 编译器线性化二维数组的方式
而列优先是fortran 编译器的方式

行优先与列优先是互为转置的关系


不考虑特殊情况

在二维层面考虑 m行n列 矩阵/数组 
对应关系如下

vertical ->h->行->m->height->gridDim.y->row ->  int row=blockDim.y*blockIdx.y+threadIdx.y;

horizontal ->w->列->n->width->gridDim.x->col ->  int col=blockDim.x*blockIdx.x+threadIdx.x;



对应关系
图片 width height 宽高
矩阵 m*n   m行nlie





垂直vertical <->  height(h/高) <-> 行(m) <-> gridDim.y blockDim.y<-> row  <-> int row = blockDim.y*blockIdx.y+threadIdx.y

水平horizontal <->   width(w/宽) <-> 列(n) <-> gridDim.x blockDim.x <->col <-> int col=blockDim.x*blockIdx.x+threadIdx.x



对于三维数组的线性化访问形式未
P[plane*m*n+row*m+col]
plane 平面索引
row 行索引
col 列索引
m 每行的列数
n 每个平面的行数


3.3 image blur a more complex kernel


这一章也是cuda 入门,一个简单图像模糊算法

3.4 Matrix_multiplication

blas : Basic Linear Algebra Subprograms
线性方程组求解器（linear system solvers）
特征值分析（eigenvalue analysis）


数量级 orders of magnitude

blas分三级  
向量运算
矩阵向量运算
矩阵矩阵运算


总结
第三章基本上还是cuda教学,对于我来说是很好的复习

4.compute architecture and scheduling
cpu的思路是最小化指令执行延迟
gpu的思路是最大执行指令的吞吐量


4.1 architecture of a modern GPU

cuda-capable gpu  支持cuda的gpu
被组织成一系列高度线程化的流式多传感器(streaming multiprocessors)
每个流式传感器有几个被称为流式处理器或者cuda cores 

sm中是有独立的on-chip memory的,至于off-chip memory 通常指非常大的device memory 也叫Global Memory
老款gpu会使用图形双倍速率同步DRAM,现在都用HBM或者HBM2 high-bandwidth memory  高带宽内存


4.2 block scheduling
当一个内核被调用的时候,cuda运行时系统会启动一个线程网格(a grid of threads)来执行内核代码
线程以线程块(block)为单位分配到sm,也就是说 每个线程块中的线程都在一个sm中

因为受限数量的SMs和每个sm上只能分配限制数量的block,因此在cuda device上同时执行的block数量有限
然而kernel中设置的block数量可能会非常多
cuda内部会有一个list,来调度这些block,一批批的送到sm中去执行


因为上述这种调度方式
相同block中的threads可以进行特殊交互,比如:
1.屏障同步 barrier synchronization  对于这个有特例(不同block中),但是限制很大,比如专用api,执行时间重叠等
2.访问驻留在sm上的on chip shared memory

4.3 synchronization and transparent scalability
__syncthreads() 
这个api的作用是当一个block中线程执行到此处时会停止,直到block中所有线程都执行到了这里

__syncthreads()需要谨慎的和条件语句(if)搭配
因为必须满足一个block内触发或者不触发syncthreads行为一致
否则就会导致未定义行为或者死锁


同一个线程块内的线程不仅必须被分配到同一个sm,同时还必须同时被分配到改sm上执行

并且只有当一个线程块内的所有线程都获取到执行所需的全部资源后,才会开始执行
这保证了一个线程块内的线程时间相似性
避免__syncthreads()出现无限等待问题


block之间不支持同步,使得cuda运行时能以任何顺序执行block
提供了灵活扩展的能力
高性能设备可以同时多跑block,而低性能设备则可以少跑一些block
而不需要相互等待

在具有不同执行资源量的不同硬件上执行相同代码的能力叫做透明可扩展性



4.4 warps and simd hardware
kernel正确执行的前提不能建立在任何一种假设上:
某些线程需要同步运作,但不使用barrier synchronization

一旦block被分配至sm中,它会被划分为32线程单元(warp),注意warp的大小是基于特定实践的,只是在大多数情况下,是32-thread unit

warp是sm的线程调度单元

如果warp是32 而block是48
block中会包含两个warp ,多余的则会被进行padding with inactive threads
如果一个多维block
其中的warp可以理解成一种一维映射的方式进行填充

sm使用SIMD的模式执行一个warp中的所有线程

在任意时刻,只会fetch一条指令,并让warp中的所有线程同时执行此指令

不同的线程只是对不同的数据进行操作

因为cuda中面对的是线程,所有上述操作也叫simt
单指令多线程



一个sm会被划分多个processing block
Thread Block = 软件组织单位
Warp         = 硬件调度单位
Processing Block = 硬件执行资源

一个warp中的所有线程都会分配到一个processing block中,一个warp中的线程同时执行

一个warp中的同一时刻只能执行一条指令
warp中的所有线程同步进行
每个线程处理自己的数据

一个现实的例子
A100中sm存在64个core  ,这64个core被分成4分processing block,每个processing block有16个core


1.sm的core是什么东西?
cuda core 流处理器(sp)
基本上只是一个算数逻辑执行单元 ALU



2.64个core划分成4个processing block是硬件划分还是抽象逻辑(软件)?
processing block是硬件划分,实打实在芯片版图上的

3.一个warp32线程,而一个block只有16个core,怎么保证同时执行指令?
不能保证

因为这里要区分控制流角度和是物理执行单元角度

从控制流角度,simd 确实是只取(fetch)一条指令,也只发射了一次

但因为core只有16个,执行层面会分两个周期,先完成前16个再完成后16个

从控制流层面
相同pc
相同指令流
一次指令获取
一次指令发射

但这并不意味着32个线程一定由32个ALU在同一个时钟周期内完成运算

在控制流层面，一个 warp 在任意时刻只能拥有一个当前 PC（程序计数器），因此所有活跃线程都执行同一条指令；
至于该指令是否能在一个周期内由足够的执行单元完成，则取决于具体硬件实现


warp的执行方式是simd
但是上层程序员看到的是多线程模型,而不是向量模型
因此nvida在simd的硬件基础上提出了simt抽象
因此simt 可以理解为线程级变成模型+simd执行硬件

这也是warp产生所谓分支发散的根因
warp中需要执行不同指令路径时,硬件不得不串行执行这些路径,从而失去性能优势

真实的simd其实原生限制很多,手动处理向量会非常麻烦
因为这层simt的抽象,上层cuda才有了类似常规编程的体验

多提一嘴simd
simd是架构语义 ISA  Instruction Set Architecture（指令集架构)中看到的一行指令
它其实不关心,你内部是真的如何处理这条向量加法的  比如processing block中只有16个core,分两次完成计算,这部分属于微架构（硬件实现）


题记
warps and SIMD Hardware


4.5 contro divergence

控制发散
当一个warp中的thread采用不同的控制流路径,simd硬件将多次通过这些路径,每条路径一次

举个例子,对于 if else 控制流 如果两条路径都有线程通过
则simd会运行两次,一次对if,一次对else,只是说对于不满足条件的thread,它们不会生效

控制发散不是坏东西,它是一种妥协,它采用多次执行方法扩展了simd硬件实现cuda完整语义的能力

硬件会为一个warp中的所有线程执行相同的指令,但它会有选择的让那些属于当前执行路径的线程在对应的执行轮次中生效
这样每个线程看起来都能沿着自己的控制流路径执行


利用 SIMD 硬件低成本优势的同时，保留了线程之间的独立性

但控制分歧也会带来额外开销,每个轮次中不活跃的inactive的线程仍然会占用执行资源

一个分歧if/else 两次执行
两个独立的if/else 会有一个汇合动作,虽然不一定是4次执行,但分歧成本会增加
两个嵌套的if/else  最坏确实可能形成4条路径

要避免一个warp中线程在分支条件上出现随机分布,否则simd的性能会迅速下降



我的补充:
cuda保证暴露出的threadIdx 0~31一定是在一个warp上
但是cuda不保证warp中的线程严格锁步执行
shared[lane] = lane;
val2 = shared[lane+1];

->
shared[lane] = lane;

__syncwarp();

val2 = shared[lane+1];

这个假设依赖于 warp 内线程严格锁步执行。
Volta/A100 之后，CUDA 不再保证这一点，因此如果线程之间通过 shared memory 通信，
通常需要使用 __syncwarp()（warp 范围）或 __syncthreads()（block 范围）来显式同步。


for循环中的分歧
for (int i = 0; i < n[threadIdx.x]; i++) {
    work();
}

循环次数接近
max(count[0..31])

其实每一轮循环都带着所有线程
只是不满足的线程处于不激活状态

通过检查其决策条件,可以确定控制结构是否导致线程发散
如果决策条件是基于threadidx的是,则控制语句可以导致线程分歧


而对于一个最常见的控制分歧的例子
每个kernel选定有效线程的时候

这种行为会随着要处理的向量增加而降低warp分歧的状态
因为只有边缘会发生分歧

控制分歧一个重要的含义是
不能假设同一个warp中所有线程都具有完全相同的执行时序
因此如果需要一个warp中所有线程都必须完全某个阶段后才能进入下一个阶段
需要使用 __syncwarp() 

4.6 warp scheduling and latency tolerance

在现在较新的设计中,每个sm可以同时为少量几个warp执行指令
这是GPU 容忍（隐藏）长延迟操作（例如全局内存访问）的关键机制

当某个warp即将执行一个长延迟操作时,这个warp不会被选中,而是选择可以快速执行的warp

有点类似与协程,和流水线发射
延迟容忍
延迟隐藏

latency tolerance
latency Hiding

这种操作维持了较高的occupancy

这与长延迟操作,比如全局内存读取,分支指令,流水线浮点运算
这也是gpu和cpu不同,不需要分支预测的区别,总可以找到快速的warp进行调用

但这里需要考虑一个事情,那就是warp调度和切换的损耗

treads context-switching and zero-overhead Scheduling


一个线程包含
程序代码 memory
pc 当前正常执行的指令位置
ir 当前正在执行的指令
寄存器和内存保留的变量和数据结构的值

传统处理上下文切换是有显著开销的

gpu则有一种 zero overhead scheduling  零开销调度

gpu可以立刻让某个wrap sleep,然后激活warp,而不让计算单元产生空闲周期

根本原因是
1 cpu 需要将context保存到内存
2 从内存加载下一个要执行的线程状态
3 恢复执行

然而对于sm来说,所有分配给sm的warp的执行状态都已经保存在硬件寄存器中了
因此只需要让调度器选择另外一个warp即可

线程A运行
↓
保存寄存器到内存
↓
加载线程B寄存器
↓
线程B运行


Warp0 等待内存
↓
Scheduler选择Warp1
↓
下一时钟周期直接执行Warp1

CPU：少量线程 + 昂贵切换 + 尽量减少切换
GPU：大量 Warp + 几乎零成本切换 + 利用切换隐藏延迟

所有才引入协程这一概念,在一个线程内切换,而不是切换线程,只发生在用户态,成本低

GPU 能够同时管理成百上千个线程，并有效隐藏数百个时钟周期内存访问延迟的根本原因

这里还有一个有趣的点
为了让上述容忍延迟有效,分配给sm的线程数量应该比执行资源多的多
这一才能最大限度的提高在任何时刻都能找到准备执行的warp的机会

SM
├── Warp Scheduler
├── Register File
├── Shared Memory
├── CUDA Cores
└── Warp States

sm调度的最小单位的warp,分配给sm的最小单位是block
SM 需要同时驻留多个 Block，而不是一个巨大的 Block。

256的block大小就是一个甜点区
可以灵活分配
而不是直接吃满


4.7 resource partitioning and occupancy


位于隐藏长延迟操作,所以最好给一个sm分配尽可能多的warp

然后实际情况是不总能达到sm所支持的warp数量

占用率 occupancy 定义

分配给某个sm的warp数量 除以  该sm所支持的最大warp数量

sm的执行资源包括
寄存器
共享内存
线程块槽位
线程槽位

这些资源是动态划分的

以a100为例,最多支持
1.32个线程块
2.64个warp
3.每个block最多1024线程


影响occupancy的资源主要有
1.线程数限制
每个sm最多2048
2.block数限制
每个sm最多32block
3.寄存器限制
a100 65536个寄存器每sm

4.共享内存限制

这里要注意的是,上面四点不是并列关系
这里引入一个重要的性能悬崖概念
performacne cliff

举一个大概的例子
512 threads/block
31 registers/thread
能容纳4个block,这样能基本吃满
如果新增加了两个寄存器
导致限制一个sm只能放3个block,占有率会出现骤降

总结
小block会受block数量限制
奇怪的block大小会浪费线程槽位
寄存器使用稍微增加会导致occupancy下降
高occupation不代表高性能   单独补充一下它
Occupancy 已经足够隐藏延迟
为了提高 Occupancy 而减少寄存器,导致需要到memory去读取加载寄存器
共享内存冲突,为了提高Occupancy,不使用共享内存

30%~60% Occupancy 就已经能达到最佳性能,Occupancy 是一种“手段”，不是“目标”。


4.8 query device properties
略
4.9 summary
Grid → Block → Warp → Thread
grid分为block
block分配给sm
block分为warp

2.block是调度单位
3,warp是执行单位

4.occupancy用于隐藏延迟
5.occupancy受限于资源


5.memory architecure and data locality

5.1 importance of memory access efficiency

引入一个重要概念
计算与全局内存访问比
compute-to-gobal-memory-access ratio

以标准矩阵运算为例
在for循环中 计算行与列的点积
将两个元素相乘,然后累加至pvalue

这里面是一次浮点乘法,一次浮点加法.从全局内存中提取8字节(两个浮点数)
因此

访问比就是  2FLOP / 8 B =0.25 FLOP/B

这个数值有什么用呢
可以用来估算性能上限
比如 a100 的峰值全局内存带宽为 1555GB/s
而该矩阵乘法的的计算强度只有0.25  因此能达到的 浮点运算吞吐量限制为

1555GB/s * 0.25 FLOP/B =388.75 GFLOPS   这只有a100峰值计算能力 19500GFLOPS的2%
如果将Tensor Core 也算进来
这只有峰值性能的0.25%

核心问题是 内存传输到gpu计算核心的速度太慢 

这种就是典型的memory-bound programs 内存受限程序

引入一个概念

roofline model
x轴是计算强度
y轴是计算吞吐量

图中一个点代表一个一个程序
x表示计算强度,y代码实际达到的计算吞吐量

它的形状大概是一条正比例函数然后接一条平行于x轴的水平线

这两条线的交点表示从该值处,应用程序从内存受限转为计算受限 


1.理论上的吞吐量  应就是峰值带宽*计算强度
也就说那个正比例斜线
但是gpu又峰值吞吐量
所以那条水平线是能达到的上限

峰值带宽
峰值吞吐量
计算强度


对于a1 它的利用率已经很高了,接近理论吞吐量
优化它只能去提高计算强度,也就是将它向右移动
为什么a1被称为内存受限?它不应该是计算强度受限,也就说计算受限吗

这里更正一个错误理解
计算强度说的就是访问主存一字节内存,能完成多少次计算
a1 a2都有一个低计算强度,这说明它们本身的算法决定了访问了太多内存了
因此是内存受限
因为a1接近当前计算强度下的理论峰值,因此,a1的优化方案只有提升计算强度,也就说减少内存访问
也就是说当前a1是被带宽限制的
而a2连当前计算强度下的理论峰值都未靠近,它本身在内存使用上就有缺陷,因此它有两条优化方案

而a3的计算强度已经很高的,但它依然没达到峰值,计算强度高意味访问一次内存就能做很多运算
当前的带宽已经满足要求,因此它的问题就是计算受限,计算单元利用率不足



memory-bound 不是说它的内存访问和处理一定有问题,而是说在当前情况下提升内存带宽,可以提升吞吐量
compute-bound也不是它是计算单元利用一定有问题,而是说在当前情况下,提升计算能力,可以提升性能

a1a2由于计算强度低,因此性能上限受内存带宽限制,属于memory-bound

a3具有较高计算强度,其性能上限已经有计算峰值决定而非内存带宽,因此属于compute-bound
但此时它仍然表现不佳,说明计算单元利用率不足 ,优化方向是提升计算单元利用率
(假如单元利用率已经无法提升,那就只能增加计算单元数量了,所以得名compute-bound)

5.2 cuda memory types

global memory
全局内存 可以被host 和device端读写,最慢
constant memory
低延迟,高带宽,可以被host读写,但是只能被device读

local memory 
就是全局内存的一部分,但是不能跨线程分享,这是留给线程专用的部分
用来处理分配数组,寄存器溢出和其他线程调用栈中的元素(可以理解为就是栈空间)

然后是寄存器和共享内存
寄存器是线程独享的,并且可以动态调节每个线程使用的寄存器数量
共享内存是一个block中共同使用的,一个block中的线程都可以使用

插入一个cpu和gpu架构的差异
cpu上希望切换会将离开线程的寄存器内容保存到内存,并且从内存中恢复进入的线程寄存器数据

而gpu则是将所有processing block中的线程寄存器都保存在该处理单元的寄存器文件中,因此实现了0开销调度
(因为不用保存任何信息)


并且gpu寄存器的数量是动态划分的
多线程少寄存器或者少线程多寄存器  这也是cuda编程中的寄存器压力的根本原因 


寄存器  共享内存 全局内存

其中最快的是寄存器
显而易见,寄存器相比于全局内存,在指令层面不需要load指令(毕竟操作内存,最后计算也还是在寄存器上完成的)
并且寄存器更节能,通常比全局内存读取低一个数量级
但也是没代价的,如果一个线程占用了太多寄存器,整体线程的占有率就会降低

共享内存
访问共享内存也需要一次load操作
也就是说它比寄存器差
但是它毕竟作为片上内存,具有远高于全局内存的带宽,和远低于全局内存的延迟
并且一个block上的线程还能共享(寄存器是完全私有)

全局内存就不说了  一个字 大


标量默认进寄存器，数组默认进Local；__shared__供Block共享，__constant__供全局只读共享，__device__提供全局可读写存储。

声明方式	存储位置	作用域	生命周期
int x;	Register	Thread	Grid
float a[64];	Local Memory	Thread	Grid
__shared__ int x;	Shared Memory	Block	Grid
__device__ int x;	Global Memory	All Grids	Application
__constant__ int x;	Constant Memory	All Grids	Application

标量一般都是自动进寄存器
但是注意标量不要用太多

自动数组变量 local memory  
访问延迟高,可能发生访问堵塞(毕竟实际就是global memory)
kernel中很少使用 local memory


shared Memory

Constant Memory,虽然在全局内存,但是有专用缓存,所以很快,但大小不能超高64k

global 最大,最慢,但是所有人都能访问
cuda没有简单的方法可以实现Block0 等待 Block1或者block看到一致数据
除非使用原子操作或者拆分kernel
所以global variable经常用来在不同kernel之间传递数据

5.3 Tiling for reduced memory traffic
tiling 分片技术
我的理解就是将数据结构进行合理的划分
将重复load的数据载入share memory ,然后后续block的其他线程就不需要再次从global中读取
从这里这也能看到这项优化技术的特点
1.这是block层级的优化,因此block越大,能复用load的次数就越多
2.对每个Tile的计算必须能够独立完成，而不依赖其他Tile。
3.并不是所有数据结构和算法都能够被任意划分为Tile。


对于书中2*2的tile,使用分片技术减少的访问次数是2
对于n*n的tile,使用分片技术减少的访问次数是n
但是对于m*n的tile,使用分片技术减少的访问测试
对于Atile(m*n) 是n 倍,对于Btile(n*m)是m倍


而gpu的同步因为warp切换损耗极低,所以使用多次同步来换取全局访问次数的成倍降低很值得
5.4 A tiled matrix multiplication kernel
具体见代码 learn_cuda tiling2
核心注释说明
    // 当前线程所在的block
    // 后续需要matA的第y行上所有block和matB第x列上的所有block

    // 这里来解释一些怎么来的
    /*
    正如前面所说,计算一个matC的结果tile也就是mat的xy block
    需要matA的第y行上所有block和matB第x列上的所有block
    对于matA来说这y行的所有block的row都是不变的,都和matc 结果tile的row相同
    对于matB来说这x列的所有block的col都是不变的,都和matc 结果tile的col相同

    然后是tcol和trow
    它俩是block内部的线程坐标block是threadIdx

    所以当前开始填充__shared__的时候
    我们首先要知道Atile和Btile的具体位置,也就是第i行j列
    接着是从matA和matB中获取对应位置的数据
    matA
    行由两部分组成 1.block自身所在行的thread起始行,也就是brow  2.block中线程的纵向偏移,也就是trow
    列也由两部部分组成 1.当前此行上所有block的循环的起始行,也就是bk*BX 2.bk下线程的横向偏移,也就是tcol

    matB 同理 行两部分 1.
    当前此列上所有block的循环也就是bk*BY  2.bk下线程的纵向偏移 也就是trow
    列两部分  1.不变的bcol列  2.col列中的横向线程偏移

    最后,补齐约束限制
	*/
	
	
这里的两个__syncthreads()  前一个叫写后读依赖,后一个叫读后写依赖
read after write dependence 真依赖 
write after read dependence  假依赖  叫它假依赖,是因为它复用了相同位置导致,如果没有相同问题,就不存在依赖

strip-mining(条带挖掘) 可以理解为“把一个大循环切成一段一段的小循环来做”。
就是代码中那个bk循环里面套着点积计算的东西
原本点积计算是一个单独的长循环
而strip-mining将其转化为一个bk循环,里面包含部分点积循环


5.5 boundary checks
见我自己写的代码


5.6 impact of memory usage on occupancy
内存使用对占有率的影响

最大化占有率的意义是容忍长延迟操作(warp调度需要大量的准备warp作为前提)


shared memory可以在kernel启动的时候指定
但是我没想到竟然是以这么丑的方式
还真是申请一个一维数组出来

内部就只变成了,extern __shared__ char  Mds_Nds[]

原文
extern __shared__ char Mds_Nds[];

float *Mds = (float *) Mds_Nds;
float *Nds = (float *) Mds_Nds + Mds_sz;

这里写的有问题

5.7 总结


共享内存使用超出限制后,sm上同时运行的threads数量就会降低
这会同时影响两个方面
1.计算吞吐量降低
2.容忍延迟的能力降低

但是这不一定意味着整体性能的下降
如果算法本身对全局内存访问的需求就是很大,低占有率的版本可能反而比高占有率版本跑的快

bank conflict补充

bank是sm上share memory的硬件结构
bank conflict是以warp为单位发生判断的

bank conflict是针对一个warp的同一条shared memory指令而言的

完整定义:
bank conflict 是指同一个warp中多个线程同时访问共享内存中同一个bank的不同地址,导致原本并行的共享内存访问串行化,从而降低性能

bank 正如其名
32个bank想象成32个银行窗口
32个人去32个不同窗口,最快
2个人去同一个窗口办不同业务,排队 bank conflict
10个人去同一个窗口拿同一份材料,窗口之间复制/广播 不需要排队

bank conflict 读写差异

相同bank的相同地址 读方式会触发广播机制
写的时候就不叫conflict  这是竞争,说明代码有问题

为什么要搞出bank,并且采用交错的方式进行
warp会在同一条指令中同时访问shared memory
如果shared memory只是一个单口存储器,这就是需要排队
因此bank就设计成了一个交错排列的形式
想象一个m*32的二维数组
每一列都是一个独立的bank
最最常见的一种用法,一个warp一次读取一个长度为32的数组
每个线程独立使用一个bank
如果按列访问,就会出现严重冲突
此时需要给数组添加padding,让原始数组的列错开
从bank的视角看来,就又回到了独立访问的状态

顺便提一句
全局内存对靠近的数据会采用memory coalescing的方式来提高访存效率
如果地址都是分散的,全局内存访问会更慢



6.performance considerations
片外内存架构

一种重要优化类型  线程粒度粗化

介绍了一些核心思想
就是具体问题具体分析的将受限因素向非受限因素摊平
比如设备的显存大,计算孱弱,那就可以用空间换时间.

6.1 memory coalescing

cuda内核最核心的因素之一就是对全局内存中数据的访问
全局内存带宽却是有限的

章节5讨论了平铺技术,本章讨论内存结合技术
通常两者结合使用

额外冷知识
为什么dram这么慢
数据存在dram单元中,这些单元是很小的电容
里面有微小的电荷.
从dram读取数据时,需要这个小电容利用微小电荷驱动一条高电容线路
将信号发送给传感器,触发传感器的检测机制,以判断电容器中是否有足够的电荷可以被认定为1
现代dram中这一过程通常需要几十纳秒,而且现代计算设备的时钟周期通常低于1纳秒

为啥dram这么慢
1.译码器是一种电子电路,它和上千个存储单元输出门的线路完全充放电到所需电平,可能需要很久时间
2.更困难的就是上述提到的检测机制
严谨的说存储单元驱动通向感应放大器的垂直电路,并使感应放大器能检测其中内容
这一过程是电荷共享.
栅门释放存储在该单元中的极少量电荷,如果该存储单元的的内容是1
那么极少数电荷需要将长位线的大电容电势拉高到足够高的水平,从而触发感应放大器
用个比喻,就是一个人用咖啡的香味去识别咖啡的味道

按照一个正常的思路是 增加咖啡的香味,也就是更大更强的存储单元电容
但是drma的发展方向相反,为了在芯片中存储更多的位,每个存储单元的电容器尺寸在不断下降

说起来还是局部性
访问dram某个位置的时候,实际会访问一段包含所请位置
dram有多个传感器,可以并行操作,每个传感器都会感知连续位置的内存

而这些连续位置数据被传输到处理器的行为叫做dram bursts

cuda也可以利用这种机制
warp中执行的都是相同指令,当所有线程执行一条加载指令时,硬件会检查它们访问的是否为连续的全局内存位置
最理想的情况
一个warp中都是访问的都是连续的全局内存位置,硬件会对这种操作执行聚合操作
成为一次对连续dram位置的统一访问


出乎我意料的事
矩阵乘法中第二个矩阵的内存访问是天然合并的
数组M的索引是k*width+col  
因为对于过一个warp,变量k和width在warp上具有相同的值
而col的定义是 blockIdx.x*blockDim.x+threadIdx.x
连续线程具有连续的col,所以对M的访问是连续的

补充说明
对于矩阵乘法的第一个矩阵
它不是合并也不是不合并,它访问的是相同数据
也就说一个warp使用的是一个数据
A[row * Width + k]
对于一个一个warp中,因为连续性往往计算的都是统一行数据
所以它们的row通常都是相同的




对于不适合内存合并的访问,有多种策略可以优化
1.重新安排映射
2.重新安排数据本身排布
3.以合并访问的方式,将数据从全局内存加载到共享内存,然后在共享内存中执行不利于合并的模式


其中转角优化就是用3的方式
全局内存里怎么读，和共享内存里怎么用，可以不是同一个方向。
从全局内存读取时，让连续线程访问连续地址；读进 shared memory 后，再按计算需要的方向访问

6.2 隐藏内存延迟 hiding memory latency

bursting 不足与满足处理器的内容访问带宽要求

除此之外还有 banks 和 channel

DDR的意思是每个时钟周期进行两次数据传输,一次是时钟周期上升,一次是时钟周期是下降

对于64位宽  时钟周期位1GHz 的DDR总线
是8B*2*1GHz=16 GB/s


channel是通道
一个处理器内存处理器可能有很多通道
因为处理器对数据传输的要求很高
每个通道连接着多个bank
至于一个channel能连接多少bank 
取决于 bank 自身一次访问后的恢复/准备时间 和 channel 的数据传输速率 之间的关系。
,原因后面会说

而bank则是一组dram单元,一个访问这些单元的感应放大器,一个向总线也就是channel发送数据的接口

bank发送数据不是连续不断的,而是脉冲式的
bank内部访问dram cell的过程比较慢,但是一旦某一行数据被激活并送到感应放大器后就能向channel连续输出一段数据
这段连续输出就是burst


准备数据,激活行,读出,感应放大,组织burst
然后才同那个channel传输一小段连续数据

连接多个bank可以让不同bank发送数据的阶段错开
比如bank 0在准备数据  channel空闲  此时bank1就能传输数据

多bank的核心目标是提高channel利用率


bus概念对channel的抽象
实际上每个channel都有一条总线

关于burst 的"一小段连续内存"
通常是几十个字节 典型值可以按照 32B 64B 128B
这个东西和catch line填充有点关系但不绝对
如果不进行特别细的研究可以理解为一次填充缓存行

实际上,访问延迟要比数据传输时间长的多 

如果访问延迟和数据传输的比率 是20:1
那么一个channel理论上要挂21个bank
但是因为bank conflict 通常会有更多bank挂在上面

另外一个原因就是需要平衡访问延迟和制造可行性
因此这限制了bank能够提供的存储单元数量.为了支持内存容量,本身就需要很多bank

这就是为啥要最大化occupancy
只有足够多的线程访问,才能产生足够多的内存访问请求,用来隐藏dram的内存访问延迟
为了最佳带宽利用率这些内存还要均匀分布到不同的channel和bank上,并且对每个bank的访问也得是合并的


补充信息,这里我希望弄明白dram bank相关的信息

dram有很多bank,每个bank都是一个完全独立的存储单元阵列
这些bank里面有很多紧密排布的晶体管和对应的电路
这些晶体管在物理世界中以二维结构排布,类似一个矩阵

然后memory controller 将连续的物理地址(pa 页级)根据bit划分到不同的bank 的不同row不同colum

os/mmu 将这些物理页表以不连续的状态映射到虚拟页表中
然后呈现到程序中的就是连续的虚拟地址

当我们在程序中遍历一个长数组的时候
一个虚拟地址有对应虚拟页表
然后虚拟页表到物理页表
然后物理页表中根据物理地址,去找到对应的channel bank row col

局部性的战场在缓存,而不是dram 
上述讲到的所有知识是当你不得不使用dram的时候应该注意什么
或者说 当使用dram时,发生了什么

这种排布规则 叫做交错排布   interleaved data distribution


coalesced load 是指各个线程发出的零散load store请求,被组合成一个少数几次连续的内存事务

1.同一个warp
2.访问同一 cache line / memory segment
3.连续或规律连续




候选人偏训练优化（训练框架层开发、RL框架、为业务适配算法等）、推理优化（支持业务型、框架侧开发如开发一些并行）、这类研发，不会太问算子，不过会问一些基本的GPU的基础知识、roffline模型、利用率、性能优化思路、SM、cuda graph、nccl、各种并行的应用（尤其是各种sp、结合不同的拓扑等）、tensor core、基础算子的一些基本原理，nsight profile的一些基础知识，核心无论是训练还是推理，你能定位其性能瓶颈、从GPU的利用率曲线、GPU的温度情况等，到去profile，最终找出瓶颈，并从底层GPU计算、显存、通信、数据读取等等解释它，从而知道从哪个角度去优化。对于更底层的框架开发者（推理算子开发、训练算子优化），会问更多的一些算子和并行相关的细节，比如怎么去实现一个投机采样领域的tree attention，支持batch size大于1、每个batch之间变长、tree类型的投机采样；社区这些算子如flash attention库、flashifner、xformers这些是否实现，实现的情况有缺点；这种attention如何支持cuda graph。再比如，w4a16这种的实现细节。不同gemm的实现方式，stream k、split k。再问一些cutlass相关的技术点，结合算子融合类型的通信计算overlap，探讨一下不同架构是如何实现的。另外不同架构下不同的实现，也很有意思，针对工作中用的最多的架构（ampere或hopper），探讨工作涉及的算子，如何在这些架构下实现以及优化的。




6.3 thread coarsening
线程粗化

本章的大概意思是说,在并行化改造中有些不得不付出的代价
如果程序有足够的并行性,并且硬件支持并行运行,不退回顺序执行
那么通常这些代价是可以接受的
比如矩阵tile乘法中,两个output tile会载入相同的input矩阵行tile

在这种情况下可以考虑复用这些重复的input tile
正常情况下一个线程负责一个输出元素
而此时可以改造成一个线程负责多个输出元素
线程粗化是一种强大的手段,但也要注意陷阱


1.线程粗化的意义是降低并行化的代价,如果没有额外代价,那么粗话没有任何意义,比如向量加法
2.不要过度粗化以至于硬件资源无法重复利用
3.避免资源消耗到损害占有率的情况


6.4 a checklist of optimizations
---
最大化利用率
通过调整sm资源使用,使其可以最大化利用率
好处 更多工作隐藏计算核心的管线延迟,有足够多是warp调换
更多的并行隐藏对dram的访问


---
合并全局内存访问
这个的核心思路是利用dram的burst/cacheline,读取某个字节的时候会读取附近字节
1.调试线程数据映射方式
2.调整数据排布
3.以合并的方式将数据从global传递的到share,然后以非coalesced的方式读取(典型方案转角)

好处 减少了计算核心等待  减少了全局显存访问次数,充分利用缓存行
---
最小化控制分歧
因为控制分歧在gpu上表现和cpu不同
无论多少条路,对于cpu都是一趟,而gpu的特性导致同一时刻一个warp中的线程执行相同指令
当分歧出现是,gpu会反复执行,一次跑成立,一次跑不成立的线程

方案是重新调整线程工作的数据
调整数据排布
好处是高simd性能

---
分片 tile
将需要充分使用的数据提前加载的到share上
好处基本上同合并全局内存访问

-----------

线程粗化
将多个工作单元分配到一个线程,这样做的好处是降低并行化带来的冗余

表 6.1 中的第一项优化是最大化 SM 上线程的占用率。这个优化在第 4 章“计算架构与调度”中已经介绍过，当时强调了让线程数量远多于核心数量的重要性，因为这样可以提供足够多的工作来隐藏核心流水线中的长延迟操作。为了最大化占用率，程序员可以调整 kernel 的资源使用情况，确保每个 SM 允许的最大线程块数量或寄存器数量不会限制能够同时分配到该 SM 上的线程数量。在第 5 章“内存架构与数据局部性”中，共享内存也被介绍为另一种需要仔细调优的资源，以避免它限制占用率。在本章中，最大化占用率的重要性被进一步讨论：它不仅可以隐藏核心流水线延迟，也可以隐藏内存延迟。让大量线程同时执行，可以确保产生足够多的内存访问，从而充分利用内存带宽。

表 6.1 中的第二项优化是使用合并的全局内存访问，也就是确保同一个 warp 中的线程访问相邻的内存位置。这个优化是在本章中介绍的，其中强调了硬件能够将对相邻内存位置的访问合并成一次内存请求，从而减少全局内存流量，并提高 DRAM burst 的利用率。到目前为止，本书这一部分中我们看到的 kernel 都天然表现出了合并访问。然而，在本书第二部分和第三部分中，我们会看到许多例子，其中内存访问模式更加不规则，因此需要更多努力才能实现合并访问。

对于访问模式不规则的应用，有多种策略可以用来实现合并访问。一种策略是以合并的方式将数据从全局内存加载到共享内存中，然后在共享内存中执行不规则访问。我们在本章已经见过这种策略的一个例子，也就是 corner turning。我们还会在第 12 章“归并”中看到这种策略的另一个例子，该章讨论 merge 模式。在这种模式中，同一个线程块中的线程需要在同一个数组中执行二分搜索，因此它们会协作地以合并访问的方式将该数组从全局内存加载到共享内存中，然后每个线程在共享内存中执行二分搜索。我们还会在第 13 章“排序”中看到这种策略的一个例子，该章讨论 sort 模式。在这种模式中，线程会以分散的方式将结果写入数组，因此它们可以协作地先在共享内存中完成这些分散访问，然后在将结果从共享内存写回全局内存时，使目标位置相近的元素获得更好的合并访问效果。

对于访问模式不规则的应用，另一种实现合并访问的策略是重新安排线程到数据元素的映射方式。我们会在第 10 章“归约与最小化分支发散”中看到这种策略的一个例子，该章讨论 reduction 模式。还有一种实现合并访问的策略是重新安排数据本身的布局。我们会在第 14 章“稀疏矩阵计算”中看到这种策略的一个例子，该章讨论稀疏矩阵计算和存储格式，尤其是在讨论 ELL 和 JDS 格式时。

表 6.1 中的第三项优化是最小化控制发散。控制发散在第 4 章“计算架构与调度”中已经介绍过，当时强调了同一个 warp 中的线程走相同控制路径的重要性，因为这样可以确保在 SIMD 执行期间所有核心都能被有效利用。到目前为止，本书这一部分中我们看到的 kernel 基本没有表现出控制发散，除了边界条件处不可避免的发散。然而，在本书第二部分和第三部分中，我们会看到许多例子，其中控制发散可能会严重损害性能。

有多种策略可以用来最小化控制发散。一种策略是重新安排工作和/或数据在线程之间的分配方式，确保一个 warp 中的线程全部被使用之后，才使用其他 warp 中的线程。我们会在第 10 章“归约与最小化发散”中看到这种策略的一个例子，该章讨论 reduction 模式；也会在第 11 章“前缀和（扫描）”中看到这种策略的例子，该章讨论 scan 模式。重新安排工作和/或数据在线程之间分配方式的策略，也可以用于确保同一个 warp 中的线程具有相似的工作量。我们会在第 15 章“图遍历”中看到这种例子，该章讨论 graph traversal，并会讨论以顶点为中心和以边为中心这两种并行化方案之间的权衡。另一种最小化控制发散的策略是重新安排数据布局，确保同一个 warp 中处理相邻数据的线程具有相似的工作量。我们会在第 14 章“稀疏矩阵计算”中看到这种策略的例子，该章讨论稀疏矩阵计算和存储格式，尤其是在讨论 JDS 格式时。

表 6.1 中的第四项优化是对在线程块内会被复用的数据进行 tiling，也就是将这些数据放入共享内存或寄存器中，并从那里反复访问，使它们只需要在全局内存和 SM 之间传输一次。Tiling 在第 5 章“内存架构与数据局部性”中已经介绍过，当时是在矩阵乘法的语境下讨论的：处理同一个输出 tile 的线程会协作地将对应的输入 tile 加载到共享内存中，然后反复从共享内存中访问这些输入 tile。我们会在第二部分和第三部分的大多数并行模式中再次看到这个优化。我们还会观察到，当输入 tile 和输出 tile 的维度不同时，应用 tiling 会面临一些挑战。这个挑战会出现在第 7 章“卷积”中，该章讨论 convolution 模式；也会出现在第 8 章“Stencil”中，该章讨论 stencil 模式。我们还会观察到，tile 数据不仅可以存储在共享内存中，也可以存储在寄存器中。这一点在第 8 章“Stencil”中表现得最明显。除此之外，我们还会看到，tiling 不仅适用于被重复访问的输入数据，也适用于被重复访问的输出数据。

表 6.1 中的第五项优化是私有化。这个优化前面还没有介绍过，但为了完整性，这里先提到它。私有化涉及这样一种情况：多个线程或线程块需要更新同一个全局输出。为了避免并发更新同一数据带来的开销，可以创建该数据的私有副本，并对私有副本进行部分更新，完成后再从私有副本对全局副本进行最终更新。我们会在第 9 章“并行直方图”中看到这个优化的一个例子，该章讨论 histogram 模式，其中多个线程需要更新相同的直方图计数器。我们还会在第 15 章“图遍历”中看到这个优化的一个例子，其中多个线程需要向同一个队列中添加条目。

表 6.1 中的第六项优化是线程粗化，也就是将多个并行单元分配给单个线程，以便在硬件本来就会将这些线程串行化执行的情况下，降低并行化所带来的代价。线程粗化是在本章的 tiled 矩阵乘法语境中介绍的，其中并行化的代价是：多个处理相邻输出 tile 的线程块会重复加载相同的输入 tile。在这种情况下，让一个线程块处理多个相邻的输出 tile，就可以使输入 tile 只被加载一次，然后供所有这些输出 tile 使用。在本书第二部分和第三部分中，我们会在不同语境下看到线程粗化的应用，并且每次对应的并行化代价也不相同。在第 8 章“Stencil”中，线程粗化被用来减少输入数据的重复加载，就像本章一样。在第 9 章“并行直方图”中，线程粗化有助于减少在私有化优化中需要提交到全局副本的私有副本数量。在第 10 章“归约与最小化发散”和第 11 章“前缀和（扫描）”中，线程粗化被用来减少同步和控制发散带来的开销。此外，在第 11 章“前缀和（扫描）”中，线程粗化还有助于减少并行算法相对于顺序算法所执行的冗余工作。在第 12 章“归并”中，线程粗化减少了为了识别每个线程的输入段而需要执行的二分搜索操作数量。在第 13 章“排序”中，线程粗化有助于改善内存合并访问。

再次强调，表 6.1 中的检查清单并不是一个穷尽式清单，但它包含了在不同计算模式中常见的主要优化类型。这些优化会出现在本书第二部分和第三部分的多个章节中。我们还会看到一些只出现在特定章节中的其他优化。例如，在第 7 章“卷积”中，我们会介绍常量内存的使用。在第 10 章“归约与最小化发散”中，我们会介绍双缓冲优化。


在决定对某个具体计算应用哪种优化时，首先要理解限制该计算性能的资源是什么。

### 6.5 了解你的计算瓶颈

限制某个计算性能的资源，通常被称为性能瓶颈。优化通常是通过使用更多某一种资源，来减轻另一种资源的负担。如果所应用的优化没有针对瓶颈资源，那么这种优化可能不会带来任何收益。更糟的是，这种优化尝试甚至可能损害性能。

例如，共享内存 tiling 会增加共享内存的使用，以降低对全局内存带宽的压力。当瓶颈资源是全局内存带宽，并且被加载的数据会被复用时，这种优化非常有效。然而，如果性能受限于占用率，而占用率又已经因为共享内存使用过多而受到限制，那么继续应用共享内存 tiling 很可能会让情况变得更糟。

为了理解限制某个计算性能的资源是什么，GPU 计算平台通常会提供各种性能分析工具。关于如何使用性能分析工具识别计算的性能瓶颈，我们建议读者参考 CUDA 文档获取更多信息。性能瓶颈可能与具体硬件有关，也就是说，同一个计算在不同设备上可能会遇到不同的瓶颈。因此，识别性能瓶颈并应用性能优化的过程，需要对 GPU 架构以及不同 GPU 设备之间的架构差异有较好的理解。
