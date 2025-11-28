---
title: "剑法篇"
date: 2025-11-28
description: "Java 核心知识单选题练习"
lead: "以考促学，查漏补缺"
disable_comments: false # Optional, disable Disqus comments if true
authorbox: true # Optional, enable authorbox for specific post
toc: true # Optional, enable Table of Contents for specific post
mathjax: true # Optional, enable MathJax for specific post
categories:
  - "编程语言"
tags:
  - "java"
  - "面试题"
draft: true
---

[◀ 返回](/编程语言/编程语言-剑法篇/)

> 单选题（每题 1 分），请在四个选项中选择 **1 个最符合题意** 的答案。

## 核心语法与运行时

1. **Local Variable 的描述，哪项正确？**  
   A. 局部变量可以使用 `public/private` 修饰。  
   B. 局部变量存储在堆（Heap）。  
   C. 局部变量在定义时必须初始化，否则编译失败。  
   D. 局部变量具有默认值，例如引用类型默认为 `null`。

2. **`try-catch-finally` 中执行 `System.exit(0)`，`finally` 会执行吗？**  
   A. 不会，`System.exit(0)` 直接终止 JVM，`finally` 被跳过。  
   B. 只有 `try` 未抛异常才执行。  
   C. 会，`finally` 总会执行。  
   D. 取决于 `catch` 是否捕获 `RuntimeException`。

## 并发与集合

3. **以下哪一个集合在并发场景下性能优于 `Hashtable`？**  
   A. `TreeMap`  
   B. `ConcurrentHashMap`  
   C. `Hashtable`  
   D. `LinkedHashMap`

4. **创建并启动线程，推荐方式是？**  
   A. 实现 `Runnable` 接口。  
   B. 实现 `Callable` 接口。  
   C. 继承 `Thread` 类。  
   D. 实现 `Serializable` 接口。

5. **JDBC 中优先使用 `PreparedStatement` 的主要原因是？**  
   A. 执行效率永远高于 `Statement`。  
   B. 内置参数转义，可有效防止 SQL 注入。  
   C. 可以动态生成 SQL，`Statement` 不行。  
   D. 不需要手动关闭连接。

6. **关于 Spring IOC 容器，正确描述是？**  
   A. `Scope` 需要运行时手动控制。  
   B. 只创建对象，不管依赖。  
   C. 通过 IOC，业务逻辑与对象创建/依赖/生命周期解耦。  
   D. IOC 容器本身就是 Spring AOP 的核心实现。

## 代码规范与集合对比

7. **下列命名方式中，最不符合 Java 核心约定的是？**  
   A. 方法/变量使用 camelCase。  
   B. 方法参数名使用下划线，如 `user_id`。  
   C. 常量名使用全大写+下划线，如 `MAX_BUFFER_SIZE`。  
   D. 类名使用 PascalCase，如 `UserAccountService`。

8. **关于 `ArrayList` 与 `LinkedList`，哪项说法错误？**  
   A. `LinkedList` 基于双向链表，实现高效插入/删除。  
   B. 在相同元素数量下，`LinkedList` 比 `ArrayList` 更节省内存。  
   C. `ArrayList` 基于动态数组，随机访问效率高。  
   D. 二者默认均为非线程安全。

## 并发与持久层

9. **`synchronized` 修饰静态方法时，锁定对象是？**  
   A. 该类的所有实例。  
   B. 当前实例 (`this`)。  
   C. JVM 自动创建的匿名锁对象。  
   D. 该类对应的 `Class` 对象。

10. **MyBatis 批量插入的推荐实践是？**  
    A. 循环调用 `Mapper.insert`，逐条写入。  
    B. 在 XML 中用 `<foreach>` 拼成一条 SQL，再提交。  
    C. 使用 `ExecutorType.BATCH`，循环执行后统一提交。  
    D. 只能通过存储过程实现。

---

## 参考答案（示例）

| 题号 | 答案 | 题号 | 答案 |
| :--: | :--: | :--: | :--: |
| 1 | C | 6 | C |
| 2 | A | 7 | B |
| 3 | B | 8 | B |
| 4 | A | 9 | D |
| 5 | B | 10 | B |

[◀ 返回](/编程语言/编程语言-剑法篇/)