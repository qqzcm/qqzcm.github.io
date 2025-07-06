---
title: kubernetes —— k8s基本概念 HorizontalPodAutoscaler & StatefulSet
authors: fanventory
date: 2025-06-30 19:22:00 +0800
categories: [kubernetes]
tags: [kubernetes]
---

# k8s基本概念 HorizontalPodAutoscaler & StatefulSet
> 介绍k8s中的基础概念 HorizontalPodAutoscaler 和 StatefulSet。

<br>
<br>

## HorizontalPodAutoscaler

虽然通过手工执行kubectl scale命令，可以实现Pod扩容或缩容，但是线上环境中，负载的变化是不可预料的，所以我们希望分布式系统能够根据当前负载的变化自动触发水平扩容或缩容。

HorizontalPodAutoscaler(HPA)也是k8s的资源对象。通过追踪分析指定RC的所有Pod负载变化情况，确定是否需要针对性调整目标Pod的副本数量。

HPA的度量指标: 
+ CPU Utilization Percentage
+ 应用程序自定义的度量指标(比如服务每秒请求数)

CPU Utilization Percentage是所有Pod副本的CPU利用率的平均值。一个Pod的CPU利用率等于该Pod当前 CPU 的使用量除以 Pod Request的值。如果某一时刻CPU Utilization Percentage的值超过80%，则意味着当前Pod副本数量很可能不足以支撑接下来更多的请求，需要进行动态扩容。请求高峰时段过去后，Pod的CPU利用率会降下来，此时Pod副本数会自动减少到一个合理的水平。

如果目标Pod没有定义PodRequest的值，则无法使用CPU Utilization Percentage实现Pod横向自动扩容。

HPA的定义文件示例: 

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache                      # 控制的Pod对象
  namespace: default
spec:
  maxReplicas: 10                       # 扩容/缩容约束条件
  minReplicas: 1
  scaleTargetRef:
    kind: Deployment
    name: php-apache
  targetCPUUtilizationPercentage: 90    # 触发自动扩容的阈值
```

创建HPA对象:

```
kubectl create -f hpa.yaml
```

![图片1](image/k8s基本概念 HorizontalPodAutoscaler & StatefulSet_pic1.png)

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
