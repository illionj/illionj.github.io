---
title: "四元数理解"
date:
  created: 2026-04-29
  updated: 2026-04-29
slug: quaternion
categories:
  - Mathematics
tags:
  - Mathematics
  - Quaternion
  - Rotation
description: "从反射、复数旋转与几何代数出发, 直观理解四元数及其旋转夹乘形式."
---

# 四元数理解

## 1. 引言

最好的四元数科普教程: [Understanding Quaternions](https://www.3dgep.com/understanding-quaternions/)

如果只从形式与用法上来看, 四元数不存在门槛.
比如四元数

$$
\mathbf{q}=[w,x,y,z],\qquad w,x,y,z\in \mathbb{R}
$$

$$
\mathbf{p}'=\mathbf{q}\mathbf{p}\mathbf{q}^{-1},
\qquad
q\in\mathbb{H},\ p\in\mathbb{R}^{3}
\quad\text{(旋转)}
$$

经过我这段时间的学习, 真正造成四元数理解困难的地方是:
- **四元数可以描述旋转 (夹乘形式), 但常规四元数 $\mathbf{qp}$ 乘法没有三维含义**
- **复数旋转概念先入为主**

所以下面我会从四元数自身含义与复数乘法旋转开始推演. 由于自身水平有限, 本文无法给出严谨论述, 只能建立直观印象.

<!-- more -->

---

## 2. 历史背景

我认为理解四元数的第一步是要理解四元数诞生时的年代背景.
- 1775 年欧拉给出欧拉旋转定理, 这个定理蕴含一个深刻的认识:**旋转可以看成依次对经过该轴的两条对称面作镜像反射**

<div align="center">
  <figure>
    <img src="/assets/images/quaternion/geogebra-export.png" alt="旋转等价于两次反射的几何示意图" width="400">
    <figcaption>旋转等价于两次反射的几何示意图</figcaption>
  </figure>
</div>

- 四元数诞生于 1843 年
- 1773 年拉格朗日引入 **点积叉积** 概念, 但 **内积 (inner product)** 这个名称 1844 才提出, **叉积** 就更晚, 当然大伙是知道 $\mathbf{a} \cdot \mathbf{b} = \|\mathbf{a}\| \, \|\mathbf{b}\| \cos\theta$ 有这么回事的.
- 罗德里格于 1840 年发表了给定旋转角度和旋转轴的 **罗德里格旋转公式**

$$
    \mathbf{v}_{\text{rot}}=
    \mathbf{v} \cos\theta
    +(\mathbf{k} \times \mathbf{v} \sin\theta
    +\mathbf{k} (\mathbf{k} \cdot \mathbf{v}) (1-\cos\theta)) 
$$

- 根据维基百科介绍, 四元数诞生之后大家发现太好用了, 尤其是麦克斯韦在四元数基础上建立了著名的麦克斯韦电磁方程. 但四元数的四个变量混合标量矢量大伙用起来实在难受. 最后大伙把四元数乘法从原始的 ijk 变成了点积叉积形式 $\mathbf{q} = \mathbf{u} \mathbf{v}= (-\mathbf{u} \cdot \mathbf{v},\ \mathbf{u} \times \mathbf{v})$

## 3. 复数旋转
在开始四元数之前, 还有必要提一下 **二维正交矩阵** 和 **复数**.
二维旋转和反射矩阵都是 **正交矩阵**,
- 旋转矩阵行列式为 1
- 反射矩阵行列式为-1
正交这个属性可了不得:

$$
Q^T Q = I
\quad\text{(也等价于)}\quad Q^{-1} = Q^T
$$

矩阵世界中的巨大难题, 逆矩阵直接就是它的转置矩阵.

### 3.1 二维旋转矩阵
一个标准的二维旋转矩阵如下

$$
R(\theta) =
\begin{bmatrix}
\cos\theta & -\sin\theta \\
\sin\theta & \cos\theta
\end{bmatrix}
$$

无论旋转角度 $\theta$ 为多少, 它的行列式永远都是 1. 它的行列式如下:

$$
\det(R(\theta)) =
\cos\theta \cdot \cos\theta + \sin\theta \cdot \sin\theta = \cos^2\theta + \sin^2\theta = 1
$$

它对应一个复数:

$$
\mathbf{r} = \cos\theta + i\sin\theta = e^{i\theta}
$$

### 3.2 二维反射矩阵

矩阵与行列式如下:

$$
M_{\text{reflect-2D}} =
\begin{bmatrix}
\cos(2\theta) & \sin(2\theta) \\
\sin(2\theta) & -\cos(2\theta)
\end{bmatrix}
$$

$$
\det(M) =
\cos(2\theta) \cdot (-\cos(2\theta)) - \sin(2\theta) \cdot \sin(2\theta) = -\cos^2(2\theta) - \sin^2(2\theta) = -1
$$

奇怪的地方来了, 没有与之对应的复数
怎么会没复数呢? 我明明可以用复数方式去计算正确的反射结果, 因为有反射公式如下:

$$
z' = e^{i 2\theta} \, \bar{z}
$$

### 3.3 复数与线性变换
所以一个精准表达是:
**二维中的任意旋转都可以被一个复数表示, 但不是所有二维反射矩阵都能由一个复数 (乘法或共轭) 来表示**
不过欧拉旋转定理告诉我们,**一个旋转可以被拆分成两个反射**

无论 **反射** 还是 **旋转** 都隶属 **线性变换**, 必须满足以下条件:

-**加法保持**:

$$
T(\mathbf{v}_1 + \mathbf{v}_2) = T(\mathbf{v}_1) + T(\mathbf{v}_2)
$$

-**数乘保持 (齐次性)**:

$$
T(c\,\mathbf{v}) = c\,T(\mathbf{v})
$$

**线性变换** 分类如下:

| **变换类型** | **说明** | **二维矩阵示例** |
| --- | --- | --- |
| **缩放 (Scaling)** | 按比例放大或缩小向量 | $\begin{bmatrix} s_x & 0 \\ 0 & s_y \end{bmatrix}$ |
| **旋转 (Rotation)** | 围绕原点旋转一个角度 | $\begin{bmatrix} \cos\theta & -\sin\theta \\ \sin\theta & \cos\theta \end{bmatrix}$ |
| **反射 (Reflection)** | 关于某条直线镜像对称 | 如关于 $x$ 轴: $\begin{bmatrix} 1 & 0 \\ 0 & -1 \end{bmatrix}$ |
| **剪切 (Shear)** | 沿某方向拉伸, 使图形变"斜" | 如 $x$ 轴剪切: $\begin{bmatrix} 1 & k \\ 0 & 1 \end{bmatrix}$ |
| **投影 (Projection)** | 映射到某一子空间 | 如投影到 $x$ 轴: $\begin{bmatrix} 1 & 0 \\ 0 & 0 \end{bmatrix}$ |
| **恒等变换 (Identity)** | 保持不变 | $\begin{bmatrix} 1 & 0 \\ 0 & 1 \end{bmatrix}$ |
| **零变换 (Zero map)** | 所有向量映为零向量 | $\begin{bmatrix} 0 & 0 \\ 0 & 0 \end{bmatrix}$ |

总结一下:
- 所有 **线性变换** 可以被 **线性代数 (矩阵)** 表示, 而 **复数 / 四元数** 是 **结构化代数系统**.
- **线性代数** 是 **结构化代数系统** 的一个基础子集, 而 **结构化代数系统** 是对线性代数的扩展与深化.
- **复数 / 四元数** 是一种结构化很强的代数系统, 它们牺牲了 **"表达一切线性变换"** 的能力, 换来了更强的几何结构一致性.

白话解释就是一个 2x2 矩阵存在四个元素, 因为四个元素可以解决二维平面上的一切线性变换. 可有时我们不关心其他变换, 只想要旋转.
所以发明了一种更加精巧的代数系统, 只表示旋转. 这样省下空间, 也提高了运算速度.

---

## 4. 从反射出发

### 4.1 反射公式
回想一下咱们的依仗,**旋转可以被分解为两次反射**, 它有一个更加强力的表述:
**在任意欧几里得空间 $\mathbb{R}$ 中, 任意一个正交变换 (保持长度的线性变换) 可以分解为一系列反射.**
特别的:
**任意旋转可以表示为两次反射的复合.**

那不妨让我们好好观察一下反射:
设 $\mathbf{n}$ 为单位法向量, 则关于 $\mathbf{n}$ 的反射为:

$$
R_{\mathbf{n}}(\mathbf{v})=\mathbf{v} -2(\mathbf{v} \cdot \mathbf{n}) \mathbf{n}
$$

设 $\mathbf{m}, \mathbf{n}$ 为两个单位法向量, $\theta = \angle(\mathbf{m}, \mathbf{n})$ 为它们之间的夹角.
<div align="center">
  <figure>
    <img src="/assets/images/quaternion/geogebra-export1.png" alt="反射公式示意图" width="400">
    <figcaption>反射公式示意图</figcaption>
  </figure>
</div>

### 4.2 两次反射推导旋转
我们对任意向量 $\mathbf{v}$ 先后进行两次反射:

$$
\begin{aligned}
\mathbf{v}_1 &= \mathbf{v}-2(\mathbf{v}\!\cdot\!\mathbf{m})\,\mathbf{m},\\[4pt]
\mathbf{v}_2 &= \mathbf{v}_1-2(\mathbf{v}_1\!\cdot\!\mathbf{n})\,\mathbf{n}\\
        &= \mathbf{v}-2(\mathbf{v}\!\cdot\!\mathbf{m})\,\mathbf{m}-2(\mathbf{v}\!\cdot\!\mathbf{n})\,\mathbf{n}
           +4(\mathbf{v}\!\cdot\!\mathbf{m})(\mathbf{m}\!\cdot\!\mathbf{n})\,\mathbf{n}. 
\end{aligned}
$$

将第二次反射展开:

令

$$
\mathbf{k} = \mathbf{m} \times \mathbf{n},\qquad
c = \mathbf{m} \!\cdot\! \mathbf{n},\qquad
\text{注意：}\times\text{ 不满足交换律，}\cdot\text{ 满足交换律}
$$

利用

$$
\mathbf{k}\times\mathbf{v}
   =(\mathbf{m}\times\mathbf{n})\times\mathbf{v}
   =\mathbf{n}(\mathbf{m}\!\cdot\!\mathbf{v})-\mathbf{m}(\mathbf{n}\!\cdot\!\mathbf{v}) 
$$

$$
\mathbf{k}\times(\mathbf{k}\times\mathbf{v})=\mathbf{k}(\mathbf{k}\!\cdot\!\mathbf{v})-|\mathbf{k}|^{2}\mathbf{v} 
$$

$$
|\mathbf{k}|^{2}=1-c^{2}
$$

$$
\boxed{\;
\mathbf{v}_2=\mathbf{v}+2c\,\mathbf{k}\times\mathbf{v}+2\,\mathbf{k}\times(\mathbf{k}\times\mathbf{v})
\;}
\tag{旋转的罗德里格形式}
$$

### 4.3 旋转公式与 $(c,\mathbf{k})$ 表示
从旋转公式中我们知道, 描述一次旋转, 真正有用的量只有两个

$$
\begin{aligned}
\mathbf{k} &= \mathbf{m}\times\mathbf{n}=(x,y,z) &\qquad& \text{两次反射法向量的叉积,也是旋转轴}\\[4pt]
c      &= \mathbf{m}\!\cdot\!\mathbf{n} && \text{两次反射法向量的点积,也就是两个法向量余弦值}
\end{aligned}
$$

既然如此, 我要表达一个旋转操作, 就直接记为:

$$
    (c,\mathbf{k})=(\mathbf{m}\!\cdot\!\mathbf{n},\mathbf{m}\times\mathbf{n})=(w,x,y,z)
$$

$$
\boxed{\,|\mathbf{m}\times\mathbf{n}| = |\mathbf{m}|\,|\mathbf{n}|\,\sin\frac{\theta}{2}},
\qquad
\boxed{\,\mathbf{m}\!\cdot\!\mathbf{n} = |\mathbf{m}|\,|\mathbf{n}|\,\cos\frac{\theta}{2}}.
$$

$$
q \;=\; \cos\frac{\theta}{2} \;+\; \mathbf u\,\sin\frac{\theta}{2},
\qquad
(|\mathbf u|=1)
$$

从反射的角度出发, 半角的出现就合情合理, 因为反射过去对称轴的另一侧也有一个半角.

$$
q \;=\; 
(\,\cos\tfrac{\theta}{2},\; \mathbf u\sin\tfrac{\theta}{2})
\;=\;
\begin{bmatrix}
\cos\tfrac{\theta}{2}\\[4pt]
u_x \sin\tfrac{\theta}{2}\\
u_y \sin\tfrac{\theta}{2}\\
u_z \sin\tfrac{\theta}{2}
\end{bmatrix}.
$$

但是这里有一个问题:
$(c,\mathbf{k})$ 是没有含义的, 它只是一个记法, 因为旋转公式需要用到 $c$ 和 $\mathbf{k}$ , 所以我就把这两个放在一起了.

$$
(c,\mathbf{k})=(\mathbf{m}\!  \cdot \!\mathbf{n},\mathbf{m} \times \mathbf{n})=(w,x,y,z)
$$

而在前文中我写下的标准四元数乘法是:

$$
 \mathbf{m}\mathbf{n}=(-\mathbf{m}\! \cdot \mathbf{n},\mathbf{m} \times \mathbf{n}))
$$

相差一个负号??这问题就很严重了, 推理过程不怕南辕北辙, 就怕差个正负.
实际上如果从几何角度出发, 通过 $\mathbf{m}$ 所在镜面反射, 再通过 $\mathbf{n}$ 所在镜面反射, 乘法计算中 $\mathbf{m}$ 应该在右, 而 $\mathbf{n}$ 在左, 正确的四元数乘法过程如下:

$$
\begin{aligned}
\mathbf{n}\mathbf{m}
  &= (-\mathbf{n}\!\cdot\!\mathbf{m},\,\mathbf{n}\times\mathbf{m})\\
  &= (-\mathbf{m}\!\cdot\!\mathbf{n},\,-\mathbf{m}\times\mathbf{n})\\
  &= (-c,\,-\mathbf{k})\\
  &= (-\cos\tfrac{\theta}{2},\,-\mathbf{u}\sin\tfrac{\theta}{2})\\
  &= (\cos(\tfrac{\theta}{2}+\pi),\,\mathbf{u}\sin(\tfrac{\theta}{2}+\pi))\\
  &= (\cos\tfrac{\theta}{2},\,\mathbf{u}\sin\frac{\theta}{2})\\
  &= (c,\,\mathbf{k}).
\end{aligned}
$$

注意此处等号是建立在几何含义之上的. 半角增加 $\pi$ , 全角当然增加 $2\pi$ . 旋转 $2\pi$ 只是多转一圈, 实际没有区别.
这下松了一口气, 通过从形式上出发, 没有矛盾.
由此我们也得出一个新结论, 对于四元数整体添加负号, 不会影响旋转结果

$$
\begin{aligned}
  (\cos(\tfrac{\theta}{2}+\pi),\,\mathbf{u}\sin(\tfrac{\theta}{2}+\pi))
  &= (\cos\tfrac{\theta}{2},\,\mathbf{u}\sin\frac{\theta}{2})\\
\end{aligned}
$$

### 4.4 差异
可是还记得 $(c,\mathbf{k})=(\mathbf{m}\!  \cdot \!\mathbf{n},\mathbf{m} \times \mathbf{n})=(w,x,y,z)$ 是什么?
什么都不是, 它只是我定义的一个记号, 打个比方就是番茄炒蛋 (**旋转**) 中的材料, 生番茄 ( $\mathbf{m}\!  \cdot \!\mathbf{n}$ ) 与生鸡蛋 ( $\mathbf{m} \times \mathbf{n}$ )
生番茄和生鸡蛋放一起没有任何含义, 甚至不能吃.
如果按照我的方法制作番茄炒蛋 (**旋转**), 我得把材料拿着 ( $(c,\mathbf{k})$ ), 到了厨房按照菜谱 (**旋转的罗德里格形式**), 把材料放进去, 最后才能得到番茄炒蛋 (**旋转**).
而 $\mathbf{nm}=(c,\mathbf{k})$ 表示四元数, 四元数就像是预制菜, 包装上画了鸡蛋和番茄, 配料表写了鸡蛋和番茄还有科技狠活. 四元数乘法是定义好的, 打开包装放锅里热热就是一盘番茄炒蛋.
上面的证明只是说番茄炒蛋需要番茄和鸡蛋, 但没说番茄和鸡蛋只能做番茄炒蛋, 这它俩出锅够还一样吗? 因此需要搞清楚如果从四元数出发, 能否回到 **旋转的罗德里格形式**.

## 5. 四元数视角
> 注意: 以下使用 $\mathbf{mnv}$ 等使用四元数定义

任意四元数可以写为

$$
q=(s,\mathbf{w}),\qquad q\in\mathbb{H},\ s\in\mathbb{R},\ \mathbf{w}\in\mathbb{R}^{3}
$$

设 $\mathbf{m}=(0,\mathbf{m}), \mathbf{n}=(0,\mathbf{n})$ 为两个单位法向量, $\theta = \angle(\mathbf{m}, \mathbf{n})$ 为它们之间的夹角.

对于任意四元数乘法有

$$
(a,\mathbf u)\,(b,\mathbf v)
    =\bigl(a b - \mathbf u\!\cdot\!\mathbf v,\;
           a\,\mathbf v + b\,\mathbf u + \mathbf u\times\mathbf v\bigr).  \tag{标准四元数乘法}
$$

### 5.1 两次反射推导旋转
我们对任意向量 $\mathbf{v}=(0,\mathbf{v})$ 先后进行两次反射:

$$
\begin{aligned}
\mathbf{k} &= \mathbf{m}\times\mathbf{n}=(x,y,z) &\qquad& \text{两次反射法向量的叉积,也是旋转轴}\\[4pt]
c      &= \mathbf{m}\!\cdot\!\mathbf{n} && \text{两次反射法向量的点积,也就是两个法向量余弦值}
\end{aligned}
$$

定义转子与其共轭

$$
\begin{aligned}
R &= \mathbf n\,\mathbf m
   = (c,\mathbf k), &
R^{-1} &= \overline R = (c,-\mathbf k)
\end{aligned}
$$

四元数旋转公式:

$$
    \mathbf{v_{rot}}=R\mathbf{v}R^{-1}
$$

接下来分两步计算:

$$
 P= R\mathbf v = (-\mathbf k\!\cdot\!\mathbf v,c\,\mathbf v + \mathbf k\times\mathbf v)
$$

根据四元数记法, 令:

$$
\begin{aligned}
s &= -\mathbf k\!\cdot\!\mathbf v, &
\mathbf w &= c\,\mathbf v + \mathbf k\times\mathbf v;
\\[8pt]
\end{aligned}
$$

左边算完算右边:

$$
\begin{aligned}
\mathbf v_{rot} &= P R^{-1} \\
        &= (s,\mathbf w)\,(c,-\mathbf k) \\
        &= \bigl(sc + \mathbf w\!\cdot\!\mathbf k,\;
                -s\,\mathbf k + c\,\mathbf w - \mathbf w\times\mathbf k \bigr) \\[4pt]
        &= \mathbf v
           + 2c\,\mathbf k\times\mathbf v
           + 2\,\mathbf k\times(\mathbf k\times\mathbf v).
           \qquad\text{旋转的罗德里格形式}
\end{aligned}
$$

这下真相大白, 四元数夹乘也是 **罗德里格旋转公式**.
但夹乘究竟是什么东西?
为什么复数左乘就可以, 而四元数就变夹乘了?

现在让我们更加深入, 再次审视复数.

## 6. 回到复数

复数比四元数更早出现, 它们都是由 **需求** 催生出来, 因此复数与四元数具有一个共同特征:

*都是各自维度旋转的最小封装*——只有最简洁、最贴合几何直觉的表示方式, 才能在数学与工程实践中被长期沿用.

> **复数** 是"2-D 旋转的最小封装": 它牺牲了实数的全序性, 却换来了对二维平面旋转的完美描述.
>
> **四元数** 把这一思想推广到 3-D; 为了获得完整的空间旋转表达力, 它进一步舍弃了交换律.

事实上, 复数与四元数都可以视为 **几何代数 (Clifford Algebra)** 中的一个"切片"; 在统一的几何代数框架下, 它们不过是同一种旋转机制在不同维度下的快捷用法.

---

### 6.1 几何代数如何表达旋转
设欧氏空间 $\mathbb R^{n}$ 的正交基为 $\{\mathbf e_1,\dots,\mathbf e_n\}$. 在其克里福德代数 $\mathrm{Cl}_{n,0}$ 中, 引入 **几何乘积**

$$
    \mathbf a\,\mathbf b \;=\; \mathbf a\!\cdot\!\mathbf b \,\,+\,\, \mathbf a\!\wedge\!\mathbf b,
$$

其对称部分给出点积, 反对称部分给出外积 (bivector).
#### (a) 反射写成一次夹乘

设单位法向量

$$
\mathbf n\in\mathbb R^{n},\qquad \mathbf n^2 = 1.
$$

1. **向量分解**

$$
   \mathbf v = \underbrace{(\mathbf v\cdot\mathbf n)\,\mathbf n}_{\displaystyle \mathbf v_\parallel}
            + \underbrace{\bigl(\mathbf v-\mathbf v_\parallel\bigr)}_{\displaystyle \mathbf v_\perp}.
$$

2. **几何乘积与正交分量的关系**

   * 在几何代数里

$$
     \mathbf n\,\mathbf v
     = \mathbf n\!\cdot\!\mathbf v + \mathbf n\!\wedge\!\mathbf v
     = (\mathbf v\cdot\mathbf n) + \mathbf n\!\wedge\!\mathbf v.
$$

   * 右再乘 $\mathbf n$ 并利用 $\mathbf n^2=1$:

$$
     (\mathbf n\,\mathbf v)\,\mathbf n
     = (\mathbf v\cdot\mathbf n)\,\underbrace{\mathbf n^2}_{1}
     \;+\; (\mathbf n\!\wedge\!\mathbf v)\,\mathbf n
     = (\mathbf v\cdot\mathbf n)\,\mathbf n- \mathbf n\!\wedge\!\mathbf v\,\mathbf n. 
$$

3. **简化外积项**

   * $\mathbf n\!\wedge\!\mathbf v$ 与 $\mathbf n$ 同时出现 => 只剩下 $\mathbf v_\perp$ 的符号翻转

$$
     \mathbf n\!\wedge\!\mathbf v\,\mathbf n=-\,\mathbf v_\perp.
$$

4. **得到反射公式**

$$
   \boxed{\;
     \mathbf v' = -\,\mathbf n\,\mathbf v\,\mathbf n
   \;}
   \tag{Reflection}
$$

   这一步称为 **一次"左右夹乘"** (sandwich). 效果:

   * 平行分量 $\mathbf v_\parallel$ 保持方向
   * 垂直分量 $\mathbf v_\perp$ 翻转符号

#### (b) 旋转 = 两次反射

取同一二维平面内的两条单位法向量 $\mathbf u,,\mathbf v$. 夹角为 $\tfrac{\theta}{2}$.

### 1. 依次反射

1. **第一次反射**

$$
   \mathbf x_1 \;=\; -\,\mathbf v\,\mathbf x\,\mathbf v.
$$

2. **第二次反射**

$$
   \mathbf x_2 \;=\; -\,\mathbf u\,\mathbf x_1\,\mathbf u.
$$

### 2. 合并为一次夹乘

两次负号抵消. 整理得

$$
\boxed{\;
  \mathbf x_2
  \;=\;
  R\,\mathbf x\,\widetilde R,
  \quad
  R := \mathbf v\,\mathbf u,
  \quad
  \widetilde R := \mathbf u\,\mathbf v
\;}
\tag{Sandwich Rotation}
$$

* $R$ 称为 **转子** (rotor). 是 **偶元素**. 满足 $R\widetilde R=1$.
* 几何意义: 在 $\mathbf u\wedge\mathbf v$ 所张平面内把向量旋转角度

$$
    \theta = 2\,\angle(\mathbf u,\mathbf v).
$$

### 3. 指数形式 (可选)

$$
R
=\exp\!\bigl(-\tfrac{\theta}{2}B\bigr),
\quad
B:=\mathbf u\,\mathbf v,\; B^2=-1.
$$

<details markdown="1">
<summary>旋转的发生器 —— 单位双向量 (bivector)</summary>

给定单位向量对 $\mathbf u,\mathbf v$($\mathbf u\!\cdot\!\mathbf v = 0$), 定义单位双向量

$$
    B \;:=\; \mathbf u\,\mathbf v, \qquad B^2 = -1.
$$

</details>

> **Rotor (旋转子)**: $R = e^{-\tfrac{\theta}{2}B} = \cos\tfrac{\theta}{2} - B\,\sin\tfrac{\theta}{2}$.

对任意向量 $\mathbf x \in \mathbb R^{n}$, 旋转由 **夹乘** 给出

$$
    \boxed{\; \mathbf x' = R\,\mathbf x\,R^{-1} \;}
$$

其中 $R^{-1} = \widetilde{R}$ 为反向 (将乘积次序反转). 该公式自动满足
$|R| = 1,\quad R \widetilde{R}=1,\quad \det R = 1.$

### 6.2 二维情形: 退化为复数

在平面 $\mathbb R^{2}$ 中, 仅有基向量 $\mathbf e_1,\mathbf e_2$. 其单位双向量

$$
    i := \mathbf e_1 \mathbf e_2, \qquad i^2 = -1.
$$

因此
$\mathrm{Cl}_{2,0}^{\;*} \cong \mathbb C, \quad \mathbf x = x_1\mathbf e_1 + x_2\mathbf e_2 \longleftrightarrow z = x_1 + i x_2.$

旋转子退化为

$$
    R = e^{-\tfrac{\theta}{2} i} = \cos\tfrac{\theta}{2} - i\sin\tfrac{\theta}{2},
$$

而夹乘简化为复数乘法:

$$
    \mathbf x' = R\,\mathbf x\,R^{-1}
    \;\longleftrightarrow\;
    z' = e^{i\theta}\,z.
$$

这正是熟悉的 **欧拉公式** $e^{i\theta} = \cos\theta + i\sin\theta$.

---

### 6.3 三维情形: 与四元数的对应

在 $n=3$ 时, $\mathrm{Cl}_{3,0}$ 的 **偶子代数** (仅含标量与双向量部分) 与四元数 $\mathbb H$ 等同. 具体地, 取

$$
    \{\mathbf e_{23},\mathbf e_{31},\mathbf e_{12}\} \;\longleftrightarrow\; \{\mathbf i,\mathbf j,\mathbf k\}
$$

即可得到四元数单位 $\mathbf i,\mathbf j,\mathbf k$ 的乘法表. 于是四元数旋转公式

$$
    \mathbf v' = q\,\mathbf v\,q^{-1}
$$

只是三维几何代数夹乘公式的再现.

---

### 6.4 统一视角下的比较

|  维度  | 代数切片                                       | 旋转子形式                      | 夹乘动作                              |
| :--: | :----------------------------------------- | :------------------------- | :-------------------------------- |
|  2D  | $\mathrm{Cl}_{2,0}^{\;*} \cong \mathbb C$  | $e^{-\tfrac{\theta}{2} i}$ | $z' = e^{i\theta} z$              |
|  3D  | 偶子 $\mathrm{Cl}_{3,0}^{+} \cong \mathbb H$ | $e^{-\tfrac{\theta}{2} B}$ | $\mathbf v' = q\mathbf v q^{-1}$  |
| *n*D | $\mathrm{Cl}_{n,0}$                        | $e^{-\tfrac{\theta}{2} B}$ | $\mathbf x' = R \mathbf x R^{-1}$ |

* **共同点**: 旋转均由指数化的单位双向量 (或其等价物) 产生, 通过夹乘作用于向量.
* **差异**: 维度越高, 封装旋转所需牺牲的代数性质 (交换律、全序性等) 越多, 但本质框架一致.

---

### 6.5 小结

* 克劳福德代数提供了一个维度无关、结构统一的旋转表达式;
* 复数和平面几何代数等价, 是 2-D 旋转的最简封装;
* 四元数则是 3-D 旋转的最简封装, 对应 $\mathrm{Cl}_{3,0}^{+}$.

> 从"复数 → 四元数 → $\mathrm{Cl}_{n,0}$"的链条可以看出:
>
> *旋转表达的力量来自双向量与夹乘, 而各种代数只是这一几何机制在不同维度下的投影.*

## 7. Cayley-Dickson 序列
写不动了
