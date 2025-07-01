---
title: kubernetes —— k8s基本概念 Job & Namespace
authors: fanventory
date: 2025-06-30 18:34:00 +0800
categories: [kubernetes]
tags: [kubernetes]
---

# k8s简单例子
> 介绍k8s中的基础概念 Job 和 Namespace。

<br>
<br>

## Job

Job控制一组Pod容器，实现批处理任务。

Job具有以下特点:
+ Job所控制的Pod副本是短暂运行的，。当Job控制的所有Pod副本都运行结束时，对应的Job也就结束了
+ Job生成的Pod副本是不能自动重启的，对应Pod副本的RestartPoliy都被设置为Never
+ Job所控制的Pod副本的工作模式能够多实例并行计算

> Kubernetes在1.5版本之后又提供了类似crontab的定时任务——CronJob

## Namespace

在k8s中，通过将资源对象分配到不同的Namespace(命名空间)，实现多租户的资源隔离，在逻辑上实现分组，便于管理。

Namespace的使用场景:
+ 实现多租户的资源隔离
+ 限定不同租户能占用的资源

Kubernetes集群在启动后会创建一个名为default的Namespace，如果不特别指明Namespace，则用户创建的Pod、RC、Service都将创建到default的Namespace中。

Namespace的定义文件:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
```

查看Namespace:

```
kubectl get namespace
```

![图片1](image/k8s基本概念 Job & Namespace_pic1.png)

查看HPA对象:

```
kubectl get hpa
```

![图片2](image/k8s基本概念 HorizontalPodAutoscaler & StatefulSet_pic2.png)

## SatefulSet

在k8s中，Pod的管理对象RC、Deployment、DaemonSet 和Job都面向无状态的服务，而现实中有很多服务是有状态的，这些服务存在以下相同点: 
+ 每个节点都有固定的身份ID，通过这个ID，集群中的成员可以相互发现并通信
+ 集群的规模是比较固定的，不会随意变动
+ 集群中的每个节点都是有状态的
+ 通常会持久化数据到永久存储中，如果磁盘损坏，则集群里的某个节点无法正常运行，集群功能受损

如果通过RC或Deployment控制Pod副本数量来实现上述有状态的集群，因为Pod名称是随机的，而且Pod的IP在运行期间才能确定，所以无法为每个Pod确定一个唯一不变的ID。

为了解决这个问题，k8s提出了StatefulSet，具备以下特性:
+ StatefulSet里的每个Pod都有稳定、唯一的网络标识，可以用来发现集群内的其他成员
+ StatefulSet控制的Pod副本的启停顺序是受控的，操作第n个Pod 时，前n-1个Pod已经是运行且准备好的状态
+ StatefulSet里的Pod采用稳定的持久化存储卷，通过PV或PVC来实现，删除Pod时默认不会删除与StatefulSet相关的存储卷

StatefulSet需要与Headless Service配合使用。Headless Service与普通Service的关键区别在于，Headless Service没有Cluster IP。如果解析Headless Service的DNS域名，则返回Headless Service对应的全部Pod的Endpoint列表。

StatefulSet在Headless Service的基础上又为StatefulSet每个Pod实例都创建了一个DNS域名:

```
$(podname).$(headless service name)
```

例如，一个StatefulSet名称为kafka，对应的Headless Service名称为kafka，则对应的3个Pod的DNS名称为kafka-0.kafka、kafka-1.kafka、kafka-2.kafka。这些DNS的名称可以直接在k8s的配置文件中固定下来。


## 参考文献

[1] Kubernetes权威指南 第4版
