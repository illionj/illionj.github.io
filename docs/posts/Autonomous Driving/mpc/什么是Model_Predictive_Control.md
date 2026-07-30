---
title: "什么是Model Predictive Control(mpc)"
date:
  created: 2025-12-07
  updated: 2026-02-22
slug: what-is-model-predictive-control
categories:
  - Autonomous Driving
tags:
  - Autonomous Driving
  - MPC
  - Control Theory

description: "用直观示例理解 Model Predictive Control"
---

# 什么是Model Predictive Control

本文旨在用最简单的例子与定义准确描述Model Predictive Control算法。

<!-- more -->

## 1. 例子

设想一个场景，一个工人被要求使用阀门调节仓库的温度。

这个阀门配有一个说明书：

- 阀门旋转角度限制：[-60,60]度
- 逆时针(左)旋转30度，每秒温度下降1摄氏度；顺时针(右)旋转30度，每秒温度上升1摄氏度
- 阀门旋转角度与温度变化遵循线性关系

仓库的状态如下：

- 仓库当前温度为10摄氏度

温度调节要求：

- 在40秒的时间内，让仓库温度从20摄氏度平稳增加到60摄氏度
- 阀门一旦开始调节，立刻计时

## 2. 分析

仓库当前温度为10摄氏度，但是要求中的起始温度是20摄氏度，并且接触阀门即开始40秒倒计时。
这意味着工人需求先尽快追上20摄氏度的起始要求，再根据当时的情况平稳增加仓库的温度到60摄氏度。整个工作在40秒内完成。

让我们抛开所有的数字，只凭感觉代替工人来操纵这个阀门。

- 先画出理想温度图像，比如第1秒应该是21摄氏度，第2秒应该是22摄氏度…
- 向右将阀门打到底，让温度快速上升,检查仓库温度
- 当仓库温度即将追上理想温度图像时，向左调整阀门
- 当仓库温度与理想温度相等时，控制阀门到一个合适角度使仓库温度按照理想温度增长速度进行增长

大致就是如下情况：
<figure>
  <img src="/assets/images/mpc/animation.gif" alt="white" style="width:100%">
  <figcaption style="text-align: center;">温度变化</figcaption>
</figure>

**其实以上就是Model Predictive Control的核心思想**：

- **基于模型的预测**  
  阀门说明书就是模型，它揭示了调节手段（旋转阀门）和调节目标（仓库温度）之间的关系。即“旋转一定角度，温度产生一定变化”。

- **时域滚动优化**  
  人为的观察仓库温度，就是所谓的时域滚动优化。当工人旋转阀门调节温度时，他的参考只是未来几秒（比如未来5秒内）的理想温度曲线。一旦完成了此时一秒的调节，未来5秒这个时间区间也会向前推进一秒。

- **仅执行第一步控制输入**  
  工人旋转阀门的判断是根据未来5秒的理想温度曲线得到的。按理说应该得到未来5秒内的5次调节方案。但因为第一秒的调节方案实施后，未来5秒的状态也发生了变化，所以只有第一次的方案重新实施，之后的方案都需要根据新的未来5秒来进行计算。

- **实时性与反馈修正**  
  这里要增加一个额外信息，以上提到的阀门或者仓库都是理想状态。然而现实中是存在误差的。仓库的保温不够好，阀门的机械机构存在问题，工人旋转角度错误等等情况下，通过模型预测的结果就与现实存在偏差。  
  比如我此时希望温度上升1摄氏度，然而温度只上升了0.9摄氏度。当计算下一次旋转阀门角度时，就要以只上升0.9摄氏度的现实温度作为起始温度。意味着下一次旋转会补偿上次因为误差缺少的旋转角度。  
  在这种情况下，即使现实存在偏差，也可以利用不断纠偏来达到理想温度。

## 3. 实现

下面给出一个简单Python实现。
```python
N = 5  # 预测时域
K = 40 # 总控制步数(40秒的工作时间)
lambda_reg = 1.0  # 控制力权重
u_min, u_max = -2, 2  # 控制输入限制(阀门调节能力上下限)
r = np.linspace(20, 60, K)  # 理想温度变化 (在40秒的时间内，让仓库温度从20摄氏度平稳增加到60摄氏度)

# 初始化
x = np.zeros(K)  
x[0]=10 #仓库当前温度为10摄氏度
u = np.zeros(K)  

# MPC控制循环

# 每秒都要计算,所以外层一个循环
for k in range(K):
    # 代价最小值 
    cost_best = float('inf')
    # 这里使用穷举法来找到最优阀门角度(求最优解才是mpc最困难的步骤)
    # 从[-2,2]分100步挨个计算代价
    for ui in np.linspace(u_min, u_max, 100):
        # 预测未来 N 步或直到结束
        future_x = x[k]
        future_costs = 0
        # 计算一个预测时域内的代价
        for j in range(min(N, K-k)):  
            future_x += ui
            future_costs += (future_x - r[k+j])**2 + lambda_reg * (ui**2)
        # 找最小代价
        if future_costs < cost_best:
            cost_best = future_costs
            u[k] = ui
    
    # 找到之后更新状态
    if k < K - 1:
        x[k + 1] = x[k] + u[k]
```
## 4. 解释

因为例子中的情况都是1维，并且求最优解采用穷举法，而且还没有误差,所以MPC的公式可以写得非常简单。如果条件允许，我是一个公式也不想写。只是这个公式非常简单，并且能体现MPC的思想，还是值得一写的。

### 1. 优化目标函数

在每个控制时刻 \( k \)，MPC 的目标是最小化预测时域内的代价函数：

$$
J(k) = \sum_{j=0}^{N-1} \left( x(k+j+1) - r(k+j) \right)^2 + \lambda_{\text{reg}} \cdot u(k)^2
$$

```python

# 代码对应
future_costs += (future_x - r[k+j])**2 + lambda_reg * (ui**2)
# N就是预测时域 
# 前者(future_x - r[k+j])**2表示预估值与理想值的方差
# 后者 lambda_reg * (ui**2) 表示旋转阀门的代价(旋转角度越大越费力,符合常识)
```
### 2. 系统动力学约束

系统状态的更新方程为：

$$
x(k+j+1) = x(k+j) + u(k)
$$

```
这就是阀门说明书中的
- 逆时针(右)旋转30度,每秒温度下降1摄氏度;顺时针(左)旋转30度,每秒温度上升1摄氏度
- 阀门旋转角度与温度变化遵循线性关系
```
### 3. 控制输入约束

控制输入满足：

$$
u_{\text{min}} \leq u(k) \leq u_{\text{max}}
$$

```
这就是阀门说明书中的
- 阀门旋转角度限制:[-60,60]度
```
### 4. 完整的优化问题

$$
\begin{aligned}
\min_{u(k)} \quad & J(k) = \sum_{j=0}^{N-1} \left( x(k+j+1) - r(k+j) \right)^2 + \lambda_{\text{reg}} \cdot u(k)^2 \\
\text{subject to} \quad & x(k+j+1) = x(k+j) + u(k), \quad j = 0, 1, \dots, N-1 \\
& u_{\text{min}} \leq u(k) \leq u_{\text{max}}
\end{aligned}
$$

<figure>
  <img src="/assets/images/mpc/trace.jpg" alt="white" style="width:100%">
  <figcaption style="text-align: center;">温度变化</figcaption>
</figure>

<figure>
  <img src="/assets/images/mpc/control.jpg" alt="white" style="width:100%">
  <figcaption style="text-align: center;">阀门旋转</figcaption>
</figure>

## 5. 困难

既然Model Predictive Control的核心思想如此简洁明了，为什么它一直被视为复杂算法？随便搜索一下都是满屏的矩阵和公式。

最困难的部分被上述例子简化了。

1. **MPC依赖于系统的数学模型来预测未来的行为。**

    如果模型与实际系统存在显著偏差，控制性能将受到严重影响，甚至可能导致系统不稳定。此外，系统参数的不确定性和外部扰动也会影响控制效果。

    从阀门说明书 -> 车辆动力学模型

2. **MPC在每个控制时刻需要实时求解一个包含多个决策变量和约束条件的优化问题。**

    这对于计算资源有限或对响应时间要求极高的系统来说，可能导致计算延迟，难以满足实时控制需求。

    从简单的

    $$
    \sum_{j=0}^{N-1} \left( x(k+j+1) - r(k+j) \right)^2 + \lambda_{\text{reg}} \cdot u(k)^2
    $$

    -> 复杂的

    $$
    Q_f \left( z_{T,\text{ref}} - z_T \right)^2 + Q \sum_{t=0}^{T} \left( z_{t,\text{ref}} - z_t \right)^2 + R \sum_{t=0}^{T} u_t^2 + R_d \sum_{t=0}^{T-1} \left( u_{t+1} - u_t \right)^2
    $$

3. **MPC能够有效地处理输入和状态的约束，但在实际应用中，如何设计和管理这些约束以确保系统在所有操作条件下的稳定性和可行性是一大挑战。**

    此外，确保闭环系统的稳定性需要在优化过程中加入额外的稳定性约束或终端条件。











