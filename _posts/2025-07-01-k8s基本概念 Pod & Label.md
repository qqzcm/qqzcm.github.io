---
title: kubernetes —— k8s基本概念 Pod & Label
authors: fanventory
date: 2025-07-01 16:12:00 +0800
categories: [kubernetes]
tags: [kubernetes]
---

# k8s基本概念 Pod & Label
> 介绍k8s中的基础概念 Pod & Label。

<br>
<br>

## Pod

Pod组成结构如下图所示，其中Pause容器是Pod的根容器，此外还包含一个或多个紧密相关的用户业务容器。

![图片1](image/k8s基本概念 Pod & Label_pic1.png)

Pod组成结构的设计理念:
+ 一组容器作为一个pod单元，那如何判断这个容器的整体状态是个难题。比如所有容器down了，pod才算down；或者N/M得出死亡率，死亡率高于某个值，pod才算down。为了解决这个问题，可以引入一个和业务无关的根容器Pause，以Pause的状态作为整个pod的状态。
+ Pod里的多个业务容器共享Pause容器的IP和挂载的Volume，这样可以简化容器之间的通信问题和文件共享问题。

Pod的类型:
+ 普通Pod
+ 静态Pod

两者的区别是，静态Pod的信息不会被存放到etcd中，而且被存放到Node的某一个具体文件中，且只能在该Node上启动、运行。而普通的Pod一旦被创建，就会被放入etcd中，随后被Master调度到某个具体的Node上并进行绑定，被kubelet进程实例化成一组相关的Docker容器。

Pod和容器的关系:
一个Pod有多个容器，默认情况下，如果某个Pod的容器停止了，k8s会检测到这个问题，并重启Pod的所有容器。

![图片2](image/k8s基本概念 Pod & Label_pic2.png)

Pod的文件定义:

Kubernetes里的所有资源对象都可以采用YAML或者JSON格式的文件来定义或描述。

```yaml
apiVersion: v1
kind: Pod                         # 资源类型: Pod
metadata:
  name: myweb                     # Pod名称
  labels:
    name: myweb                   # 标签名称
spec:
  containers:
  - name: myweb                   # 容器名称
    image: kubeguide/tomcat-app:v1
    ports:
    - containerPort: 8080
    env:
    - name: MYSQL_SERVICE_HOST
      value: 'mysql'
    - name: MYSQL_SERVICE_PORT
      value: '3306'
```

Pod的IP和端口号(containerPort)组成了Endpoint，表示该Pod内的一个进程对外通信的地址。一个Pod可以有多个Endpoint。

> Pod和Node都有Event属性，这个属性记录了事件的最早发生时间、最后出现时间、重复次数、操作者、类型、原因等信息，用于排查故障。可以通过kubectl describe pod <pod_name>来查看描述信息，定位问题根因。

Pod的限额:

Pod可以为服务器上的计算资源设置限额，当容器使用超过限额值的资源时，k8s可能就会杀掉并重启该容器。当前支持的计算资源有CPU和Memory两种。

在k8s中，通常以1/1000的CPU为最小单位，用m来表示。通常一个容器的CPU限额为100-300m，即占0.1-0.3个CPU。而Memory的限额单位是字节数。

为计算资源限额时，需要设置两个参数：
+ Requests: 资源的最小申请量
+ Limits: 资源允许使用的最大量

例子如下：

```yaml
spec:
  containers:
    -name: db
    image: mysql
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

## Label

Label是一个key=value的键值对，其中key和value由用户指定。Label可以被附加在任何资源上(如Node、Pod、Service)，每个资源可以定义任意数量的Label。定义Label后，k8s可以通过Selector查询和筛选对应的资源对象。

Label的作用：

我们可以通过为指定的资源对象定义一个或多个不同的Label来实现多个维度的资源分组管理。例如，以版本为Label，部署到不同的环境中；以Pod类型为Label，实现资源监控。

一些常用的Label示例：

+ 版本标签: "release": "stable", "release": "canary"
+ 环境标签: "environment": "dev", "environment": "qa", "environment": "production"
+ 架构标签: "tier": "frontend", "tier": "backend", "tier": "middleware"

示例:

Label被定义在Pod的metadata中: 

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myweb
  labels:
    app: myweb
```

通过RC或Service的Selector字段匹配对应Label的Pod: 

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myweb
spec:
  elector: 
    app: myweb
...
```

管理对象Deployment、ReplicaSet、DaemonSet、Job可以在Selector中定义基于集合的筛选条件，如下所示: 

```yaml
selector:
  matchLabels:
    app: myweb
  matchExpressions:
    - {key: tier, operator: In, values: [frontend]}
    - {key: environment, operator: NotIn, values: [dev]}
```

+ matchLabels定义一组Label，与直接写在Selector中效果相同
+ matchExpressions定义一组基于集合的筛选条件，运算符有In、NotIn、Exists、DoesNotExist

> 如果matchLabels和matchExpressions同时存在，则两组条件为And关系，即需要满足所有条件才能通过Selector的筛选。

Label Selector的使用场景:
+ kube-controller通过RC上定义的Selector，筛选需要监控的Pod副本数量，实现副本数量的管理
+ kube-proxy通过Service的Selector来选择对应的Pod，并自动建立每个Service对应的Pod的请求转发路由表，实现负载均衡
+ kube-scheduler可以通过Pod中定义的NodeSelector，实现Pod的定向调度

## 参考文献

[1] Kubernetes权威指南 第4版
