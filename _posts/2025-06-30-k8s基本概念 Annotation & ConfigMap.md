---
title: kubernetes —— k8s基本概念 Annotation & ConfigMap
authors: fanventory
date: 2025-06-30 18:14:00 +0800
categories: [kubernetes]
tags: [kubernetes]
---

# k8s基本概念 Annotation & ConfigMap
> 介绍k8s中的基础概念 Annotation 和 ConfigMap。

<br>
<br>

## Annotation

Annotation(注解)使用key/value键值对的形式进行定义，它用来定义k8s资源对象的元数据。通常，Kubernetes的模块自身会通过Annotation标记资源对象的一些特殊信息。

Annotation的使用场景:
+ 记录build信息、release信息、Docker镜像信息等(如时间戳，release ID，镜像Hash值)
+ 日志库、监控库、分析库等库文件的地址信息
+ 程序调试工具信息，例如工具名称、版本号等
+ 团队的联系信息

Annotation的定义文件:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  annotations:
    description: "这是一个测试pod"
    build-version: "1.0.0"
    sidecar.istio.io/inject: "false"
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
```

## ConfigMap

Docker将程序、依赖库、数据及配置文件“打包固化”到一个不变的镜像文件中，但是这种做法使容器在运行期间难以修改配置文件(比如我们需要在启动容器前修改配置文件)。为了解决这个问题，Docker提供了两种方式:
+ 在运行时通过容器的环境变量来传递参数
+ 通过Docker Volume将容器外的配置文件映射到容器内

大多数应用采用第二种方式，但是由于大多数应用需要读取多个配置文件，必须得现在目标主机上创建好对应的配置文件，才能映射到容器中，十分不方便，特别是在分布式环境中，难以维护。

针对上述问题，Kubernetes给出了一个很巧妙的设计实现:
+ 先把所有的配置项都当作key-value字符串
+ 这些配置项保存到Map表中，被持久化到k8s的Etcd数据库中
+ 然后k8s提供API给Kubernetes相关组件或客户应用CRUD操作这些数据

上述专门用来保存配置参数的Map就是Kubernetes ConfigMap资源对象。

接下来，Kubernetes提供了一种内建机制，将存储在etcd中的ConfigMap通过Volume映射的方式变成目标Pod内的配置文件，不管目标Pod被调度到哪台服务器上，都会完成自动映射。如果ConfigMap中的key-value数据被修改，则映射到Pod中的“配置文件”也会随之自动更新。

![图片1](image/k8s基本概念 Annotation & ConfigMap_pic1.png)

## 参考文献

[1] Kubernetes权威指南 第4版
