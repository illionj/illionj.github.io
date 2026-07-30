---
title: "勒让德变换 Legendre transformation"
date:
  created: 2024-09-22
  updated: 2024-10-13
slug: legendre-transformation
categories:
  - Mathematics
tags:
  - Mathematics
  - Legendre Transform
description: "勒让德变换学习笔记"
draft: true
---

# 勒让德变换 Legendre transformation

<!-- more -->

勒让德变换

借用reddit的回答
It's a way of swapping variables. Normally you can describe a curve by its x,y coordinates, but a curve is the sum of its tangents. If you knew the tangent at every point to the curve, you should be able to reconstruct the curve entirely. And knowing the tangent means knowing a straight line, i.e, know the y-intercept, and the gradient of each tangent line of the curve. Then the curve can be thought of as specifying the y-intercept of its tangents as a function of the gradient at that point, rather than y as a function of x. The Legendre transform is a systematic way of finding that function.

So say you have f(x). Let p be the gradient of f(x) at point x*. The tangent line is then given by y = p(x- x*) + f(x*). The y intercept is y_c = f(x*) -px*. Now, Define the function F(x) = f(x) - px. This is the tangent at x*, but shifted so that strikes f at f(x) instead. F(x) is then the y-intercept of such a line.

A requirement for the transform to exist is that f(x) is convex. If you draw a convex graph, it's easy to see that any straight line crossing f has to cross it at least twice unless it is tangent at the crossing point. The graph also tells yo that, if it is tangent, then the line has to start off as low as possible while still intersecting f, i.e the y-intercept of that line must be as small as can be. Alternatively, you can find the extremum of F(x), set F'(x*) = 0 = f'(x) - p so that p= f'(x) at the extremum. I.e, p is the gradient of the tangent at x.

Thus the y intercept of a tangent line to f(x) is min(f(x) - px), and this is in fact how the transform is defined in some math circles. Of course, min(f(x) - px) is actually the max of (px - f(x)) since it's the negative of the former. And now you can define H(p) = max(px - f(x)), H the y-intercept of the tangent to f(x) at x, and p the gradient of that tangent to curve at x.

If you have a multivariable function like L(q,q',t) you fix q,t, and take the Legendre transform in q'. You can do Legendre transforms sequentially, one for q', one for q, and so on, but it's not very useful. It's done more in thermodynamics. Define the internal energy U(S,V) and then you can take a Legendre transform in S, or one in V, or one in S, and then another in V to get three other thermodynamic potentials. You'd do that because it is easier to measure those quantities. For example the conjugate of S is T and temperature is easier to measure than entropy.


尤其是第一段写的最为精髓

已知x y 就可以刻画一条曲线
但也可以使用另一种方式刻画曲线,使用曲线每个点处的切线,也可以刻画曲线
而切线由斜率和截距定义,也就是说知道每条切线的斜率和截距,同样达到了xy的效果

而勒让德变换就是找到每条切线截距与斜率映射关系的方法

已知f(x) 在x* 处的斜率就是p=f(x*)
得到G(x)=px-f(x)
G'(x)=p-f'(x)
因为p就f(x)在x*处的导数,所以G(x)在x*处取极值

因为勒让德变换的前置要求是f(x)为convex.,所以G(x)中因为由-f(x),自动为concave
极值就是极大值

这个极值为什么重要,因为这个极值反映了截距
设
直线l :y=px+b  p还是f(x)在x*处的导数
如果想要l成为f(x)的切线
至少要保证 l在f(x)的下方(上方直接俩切点,f(x)是convex)
所以px+b<=f(x)
b<=f(x)-px 对所以的x成立
所以最大的b就是min_x{f(x)-px}

对照G(x)
G(x)的的最大值 -b=max_x{px-f(x)}

因为
min_x{f(x)-px}=-max_x{px-f(x)}

G(x)的最大值取负,就是直线的截距


以上就是勒让德变换的含义
它的一般就是就是
H(p)=max_x{px-f(x)}
将f(x)转化为斜率与截距的映射

而且勒让德变换具有自反性
双重变换等于不变

在线性代数中勒让德变换可逆性的根本原因是对偶空间的映射
具体我也看不懂了
