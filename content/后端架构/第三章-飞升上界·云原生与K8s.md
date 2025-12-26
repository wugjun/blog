---
title: "第三章：飞升上界 · 云原生与K8s"
date: 2025-12-24
description: "从分布式到云原生，韩立如何掌握Kubernetes，实现服务的自动调度和管理"
lead: "韩门已成气候，需飞升云上仙境，领悟Kubernetes的天道意志"
disable_comments: false
authorbox: true
toc: true
categories:
  - "后端架构"
tags:
  - "Kubernetes"
  - "云原生"
  - "容器编排"
  - "架构修仙"
---

## 楔子：韩门的困境

建立韩门后，韩立在源界中声名鹊起。他的微服务架构稳定可靠，能够处理大量的业务请求，赢得了众多客户的信任。

然而，随着业务规模的不断扩大，韩立发现了一个严重的问题：服务的管理和运维变得越来越困难。

每当流量增加时，韩立需要手动增加服务器，部署新的服务实例。这个过程需要：
1. 购买或申请新的服务器
2. 安装操作系统和依赖
3. 部署Docker和配置网络
4. 部署服务并配置监控
5. 更新负载均衡配置

整个过程需要数小时甚至数天，响应速度太慢。而且，当流量减少时，服务器资源闲置，造成巨大的浪费。

更糟糕的是，当某个服务实例崩溃时，需要人工介入才能恢复。如果是在深夜，可能几个小时都无法恢复，严重影响业务。

"这样下去不行..."韩立看着运维团队疲惫的身影，心中涌起一股无力感。

他听说，在源界的高层，有一个叫做"云上仙境"的地方。那里有一种叫做"Kubernetes"的天道意志，可以自动调度资源、管理服务、实现扩缩容和自愈。

"我一定要飞升上界，掌握Kubernetes！"韩立下定了决心。

---

## 第一节：初入云上仙境

经过数月的准备，韩立终于踏上了飞升之路。他带着韩门的所有服务，来到了云上仙境。

云上仙境，是一个由无数服务器组成的巨大集群。这里的服务器被称为"节点"（Node），分为两种：
- **Master节点**：控制节点，负责整个集群的管理和调度
- **Worker节点**：工作节点，负责运行实际的业务服务

韩立刚进入云上仙境，就感受到了一股强大的意志——这就是**Kubernetes**，云上仙境的天道意志。

Kubernetes（简称K8s）是一个容器编排系统，它的核心思想是"声明式API"——你只需要告诉它你想要的状态，它会自动帮你实现。

比如，你想要3个用户服务的实例运行，你只需要声明：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 3  # 我想要3个实例
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: user-service:1.0.0
        ports:
        - containerPort: 8080
```

Kubernetes会自动：
1. 检查当前有多少个实例在运行
2. 如果少于3个，创建新的实例
3. 如果多于3个，删除多余的实例
4. 如果某个实例崩溃，自动重启或创建新的实例

这就是"言出法随"——你只需要声明想要的状态，Kubernetes会自动帮你达成。

---

## 第二节：洞天法宝——Pod

在Kubernetes中，最小的部署单元是**Pod**。Pod就像源界中的"洞天法宝"，是一个独立的运行环境，可以包含一个或多个容器。

韩立创建了他的第一个Pod：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: user-service-pod
spec:
  containers:
  - name: user-service
    image: user-service:1.0.0
    ports:
    - containerPort: 8080
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

Pod的特点：
- **资源共享**：Pod内的容器共享网络和存储
- **生命周期**：Pod是短暂的，可能会被创建、删除、重启
- **调度**：Kubernetes会自动将Pod调度到合适的节点上

但直接创建Pod有一个问题：如果Pod崩溃，Kubernetes不会自动重启它。所以，通常使用**Deployment**来管理Pod。

---

## 第三节：化身万千——Deployment

Deployment是Kubernetes中管理Pod的主要方式。它就像"化身万千"的神通，可以创建多个相同的Pod实例，并自动管理它们的生命周期。

韩立创建了一个Deployment：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 3  # 3个实例
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: user-service:1.0.0
        ports:
        - containerPort: 8080
        livenessProbe:    # 存活探针
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:   # 就绪探针
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

Deployment的功能：
1. **副本管理**：自动维护指定数量的Pod实例
2. **滚动更新**：更新时，逐步替换旧Pod，实现无损更新
3. **回滚**：如果新版本有问题，可以快速回滚到旧版本
4. **自愈**：如果Pod崩溃，自动重启或创建新的Pod

当需要更新服务时，韩立只需要修改镜像版本：

```yaml
spec:
  template:
    spec:
      containers:
      - name: user-service
        image: user-service:1.1.0  # 新版本
```

Kubernetes会自动执行滚动更新：
1. 创建新版本的Pod
2. 等待新Pod就绪
3. 将流量切换到新Pod
4. 删除旧Pod

整个过程平滑无感，不会中断服务。这就是"道统的无损更迭"。

---

## 第四节：南天门与接引仙使——Service与Ingress

Pod是动态的，可能会被创建、删除、重启，IP地址也会变化。那么，其他服务如何访问它呢？

这就是**Service**的作用。Service就像"南天门"，为Pod提供稳定的访问入口。

韩立创建了一个Service：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service  # 选择标签为app=user-service的Pod
  ports:
  - protocol: TCP
    port: 80          # Service的端口
    targetPort: 8080   # Pod的端口
  type: ClusterIP      # 集群内部访问
```

Service的工作原理：
1. **标签选择器**：通过标签选择要代理的Pod
2. **负载均衡**：将请求分发到多个Pod实例
3. **服务发现**：通过DNS名称访问，如`user-service.default.svc.cluster.local`

但Service只能在集群内部访问。如果要从外部访问，需要使用**Ingress**。

Ingress就像"接引仙使"，负责将外部请求路由到集群内部的服务。

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: user-service-ingress
spec:
  rules:
  - host: user.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80
```

Ingress需要配合Ingress Controller（如Nginx、Traefik）使用，它会：
1. 监听80/443端口
2. 根据域名和路径路由到对应的Service
3. 支持SSL/TLS终止
4. 支持负载均衡和限流

这样，外部用户就可以通过`https://user.example.com`访问用户服务了。

---

## 第五节：宗门传承玉简——Helm Chart

随着服务的增多，韩立发现管理Kubernetes资源变得越来越复杂。每个服务都需要创建Deployment、Service、ConfigMap、Secret等多个资源，而且配置繁琐。

韩立想起了源界中的"宗门传承玉简"——**Helm Chart**。

Helm是Kubernetes的包管理工具，可以将一组相关的Kubernetes资源打包成一个Chart，实现一键部署。

韩立创建了他的第一个Chart：

```
user-service/
├── Chart.yaml          # Chart的元数据
├── values.yaml         # 默认配置值
└── templates/          # 模板文件
    ├── deployment.yaml
    ├── service.yaml
    └── configmap.yaml
```

Chart.yaml：
```yaml
apiVersion: v2
name: user-service
description: 用户服务Chart
version: 1.0.0
```

values.yaml：
```yaml
replicaCount: 3
image:
  repository: user-service
  tag: "1.0.0"
service:
  type: ClusterIP
  port: 80
```

templates/deployment.yaml：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.name }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
      - name: {{ .Values.name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

使用Helm部署：
```bash
# 安装
helm install user-service ./user-service

# 升级
helm upgrade user-service ./user-service

# 回滚
helm rollback user-service 1

# 卸载
helm uninstall user-service
```

这样，韩立就可以将整个"韩门"打包成多个Chart，实现"道统"的标准化传播。无论是部署到新环境，还是分享给其他宗门，都变得非常简单。

---

## 第六节：自动扩缩容——HPA

在云上仙境中，韩立还掌握了一个强大的神通——**自动扩缩容**（HPA，Horizontal Pod Autoscaler）。

HPA可以根据CPU、内存等指标，自动调整Pod的数量。当负载增加时，自动增加Pod；当负载减少时，自动减少Pod。

韩立创建了一个HPA：

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  minReplicas: 3      # 最少3个实例
  maxReplicas: 10     # 最多10个实例
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # CPU使用率超过70%时扩容
```

HPA的工作原理：
1. **监控指标**：定期收集Pod的CPU、内存等指标
2. **计算目标**：根据目标使用率计算需要的Pod数量
3. **调整副本**：自动调整Deployment的replicas数量

当流量突然增加，CPU使用率超过70%时，HPA会自动增加Pod数量，最高到10个。当流量减少，CPU使用率降低时，HPA会自动减少Pod数量，最低到3个。

这样，韩立就不需要手动管理服务的扩缩容了，系统会根据实际负载自动调整。

---

## 第七节：配置与密钥管理——ConfigMap与Secret

在Kubernetes中，配置和密钥的管理有专门的方式：**ConfigMap**和**Secret**。

**ConfigMap**：存储非敏感的配置数据

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
data:
  database.host: "mysql-service"
  database.port: "3306"
  cache.expireTime: "3600"
```

在Pod中使用：
```yaml
spec:
  containers:
  - name: user-service
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: user-service-config
          key: database.host
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: user-service-config
```

**Secret**：存储敏感数据，如密码、密钥等

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: user-service-secret
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # base64编码
```

在Pod中使用：
```yaml
spec:
  containers:
  - name: user-service
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: user-service-secret
          key: password
```

这样，配置和密钥就与代码分离了，可以独立管理和更新，无需重新构建镜像。

---

## 第八节：存储管理——PV与PVC

在Kubernetes中，Pod是短暂的，可能会被删除和重建。那么，数据如何持久化呢？

这就是**PersistentVolume（PV）**和**PersistentVolumeClaim（PVC）**的作用。

PV是集群中的存储资源，由管理员创建：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: fast-ssd
  hostPath:
    path: /data/mysql
```

PVC是Pod对存储的请求：

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd
```

在Pod中使用：
```yaml
spec:
  containers:
  - name: mysql
    volumeMounts:
    - name: mysql-storage
      mountPath: /var/lib/mysql
  volumes:
  - name: mysql-storage
    persistentVolumeClaim:
      claimName: mysql-pvc
```

这样，即使Pod被删除，数据也会保留在PV中。当新的Pod创建时，可以挂载同一个PV，继续使用之前的数据。

---

## 第九节：命名空间与资源配额

随着韩门在云上仙境中的发展，韩立发现需要更好的资源管理方式。他创建了**命名空间**（Namespace）来隔离不同的环境：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
```

然后，他为每个命名空间设置了**资源配额**（ResourceQuota）：

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
    pods: "50"
```

这样，生产环境和开发环境就被隔离了，每个环境都有独立的资源限制，不会相互影响。

---

## 第十节：监控与日志——Prometheus与ELK

在云上仙境中，监控和日志收集也是必不可少的。韩立集成了**Prometheus**和**ELK**：

**Prometheus**：指标收集和告警

```yaml
apiVersion: v1
kind: ServiceMonitor
metadata:
  name: user-service-monitor
spec:
  selector:
    matchLabels:
      app: user-service
  endpoints:
  - port: metrics
    interval: 30s
```

**ELK**：日志收集和分析

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
data:
  filebeat.yml: |
    filebeat.inputs:
    - type: container
      paths:
        - /var/log/containers/*.log
    output.elasticsearch:
      hosts: ["elasticsearch:9200"]
```

通过监控和日志，韩立可以实时了解系统的运行状态，及时发现和解决问题。

---

## 尾声：云原生的真谛

经过数月的修炼，韩立终于掌握了Kubernetes的精髓。他意识到，云原生的真谛不仅仅是容器化和编排，更是一种思想：

1. **声明式API**：描述想要的状态，而不是如何实现
2. **自动化**：让系统自动管理资源、扩缩容、自愈
3. **可观测性**：通过监控、日志、链路追踪，全面了解系统状态
4. **弹性**：根据负载自动调整，实现资源的最优利用

"云原生，我终于掌握了！"韩立看着在Kubernetes上稳定运行的韩门，心中涌起一股成就感。

但他知道，这还不是终点。在源界中，还有更高级的修炼方式——服务网格（Service Mesh），可以实现更精细化的服务治理。

"下一站，服务网格！"韩立眼中闪烁着坚定的光芒。

---

## 本章要点总结

1. **Kubernetes核心概念**：Pod、Deployment、Service、Ingress
2. **声明式API**：描述想要的状态，Kubernetes自动实现
3. **滚动更新**：实现服务的无损更新
4. **自动扩缩容**：根据负载自动调整Pod数量
5. **配置管理**：使用ConfigMap和Secret管理配置和密钥
6. **存储管理**：使用PV和PVC实现数据持久化
7. **Helm Chart**：打包和管理Kubernetes资源
8. **监控与日志**：集成Prometheus和ELK实现可观测性

下一章，韩立将学习服务网格，实现更精细化的服务治理。

