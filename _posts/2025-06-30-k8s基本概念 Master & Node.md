---
title: kubernetes —— k8s基本概念 Master & Node
authors: fanventory
date: 2025-06-30 19:12:00 +0800
categories: [kubernetes]
tags: [kubernetes]
---

# k8s基本概念 Master & Node
> 介绍k8s中的基础概念 Master & Node。

<br>
<br>

## Master

Master 是集群控制节点，负责整个集群的管理和控制，基本上所有的k8s控制命令都发给 Master来执行。Master通常会占据一个独立的服务器，如果它宕机或者不可用，那么对集群内容器应用的管理都将失效。

Master运行以下关键进程：
+ Kubernetes API Server(kube-apiserver): 提供tttp接口，是k8s所有资源增删改查的唯一入口，也是集群控制的入口进程
+ Kubernetes Controller Manager(kube-controller-manager): k8s所有资源对象的自动化控制中心
+ Kubernetes Scheduler(kube-scheduler): 负责资源调度的进程
+ etcd: 存放所有资源对象的数据

## Node

Master 之外的节点被称为Node，是k8s集群的工作负载节点。当某个Node宕机时，该Node上的工作负载(Docker容器)会被Master自动转移到其他节点上。

在k8s运行期间，Node可以通过向Master注册的方式，动态加入集群。然后kubelet会定时向Master汇报自身信息(如操作系统、Docker版本、CPU和内存、哪些pod正在运行)，然后Master根据这些信息进行资源调度。然后某个Node指定时间内不上报信息，则会标记为不可用，并转移该Node上的工作负载。


Node运行以下关键进程：
+ kubelet: 负责管理容器的创建、启停等任务，与Master协作，实现集群管理的基本功能
+ kube-proxy: 实现Service的通信和负载均衡机制
+ Docker Engine(docker): Docker引擎，负责容器创建和管理

Node的相关操作：

查看集群中的Node

```
kubectl get ndoes
```

![图片1](image/k8s基本概念 Master & Node_pic1.png)

查看某个node的详细信息

```
kubectl decribe ndoe <node_name>
```

![图片2](image/k8s基本概念 Master & Node_pic2.png)

这个命令展示了Node的以下信息:
+ Node的基本信息: 名称、标签、创建时间等
+ Node的当前运行状态: DiskPressure(磁盘空间是否不足)、MemoryPressure(内存是否不足)、NetworkUnavailable(网络是否正常)、PIDPressure(PID是否充足)。如果检查均通过，则Ready=True，表示Node处于健康状态
+ Node的主机地址和主机名
+ Node的资源数量: 包括CPU、内存数量、最大可调度pod数等
+ 主机的系统信息: 主机ID、系统UUID、linux内核版本、操作系统类型和版本、Docker版本、kubelet和kube-proxy版本等
+ 当前运行的pod概要信息
+ 已分配的资源使用概要信息
+ Node的Event信息

## 参考文献

[1] Kubernetes权威指南 第4版
