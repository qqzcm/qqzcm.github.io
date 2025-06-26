---
title: C++ —— close on exec
authors: fanventory
date: 2023-04-12 11:03:00 +0800
categories: [other, C++]
tags: [C++, FD_CLOSEXEC]
---

# close on exec
> 由于子进程会继承父进程的文件描述符，但是子进程执行exec系统调用时，子进程对应的堆栈、上下文等数据会被替换，这时候没有关闭的文件描述符可能会带来严重的危害。fcntl调用提供了close on exec属性来解决这个问题，使目标文件描述符在exec调用之前自动被关闭。随着内核版本的升级，open和socket等相同调用也提供了类似的字段实现相同的功能。

<br>
<br>

## 问题场景 

场景1：有一个进程A，监控进程B，进程B监控进程C。其中进程C是进程B通过fork调用创建的子进程，然后子进程C再通过exec执行新的程序。进程B和进程C在一台计算机上，进程A在另一台计算机上，通过json rpc远程调用来实现通信。  
假设B监听了8888端口，A通过这个端口与B通信。当进程B被kill掉时，理论上8888端口无人监听，A向8888端口执行rpc调用会报异常，且连接会断掉。  
但实际上，A执行rpc调用会阻塞，因为子进程C在fork时继承了打开的文件描述符，并且占据了监听权。

场景2：在Webserver中，首先以root权限启动，以此打开root权限才能打开的端口、日志等文件。然后降权到普通用户，fork出一些worker进程，这些进程中再进行解析脚本、写日志、输出结果等进一步操作。但是由于子进程继承了父进程的文件描述符，所以子进程通过exec运行的脚本时，可能会越权操作这些文件，而有些文件是root用户才能操作。

场景3：父进程fork创建出子进程，这时由于写时复制策略，父进程和子进程的文件描述符会指向系统文件表中的同一项。但子进程调用exec执行新的程序，子进程的上下文、数据、堆栈等都会被替换掉。而文件描述符当然也不存在了，这时子进程无法关闭无用的文件描述符。

## 解决方法

上述场景说明了子进程继承父进程无用的文件描述符后，子进程再调用exec系统调用带来的危害，包括不限于占据socket、越权操作root文件、丢失文件句柄导致资源泄露。  
解决这个问题的方法也很简单，就是fork子进程之后，调用exec之前，关闭无用的文件描述符就行了。但实际开发中，我们不知道父进程打开了多少文件描述符，而且逐一清理这些文件描述符也会使代码繁杂，逻辑混乱。   
所以fcntl调用提供了close-on-exec属性。该属性的作用是：当fork创建子进程后，执行exec时会关闭带有close-on-exec属性的文件描述符。

用法如下：  

```c++
int flags = fcntl(fd, F_GETFD);
flags |= FD_CLOEXEC;
fcntl(fd, F_SETFD, flags);
```

## O_CLOEXEC/SOCK_CLOEXEC

自linux 2.6.23内核版本起，open系统调用支持参数O_CLOEXEC，通过按位或的方式传入flags参数中，实现相同的功能。  

自linux 2.6.27内核版本起，socket也可以在type字段通过按位或的方式传入SOCK_CLOEXEC参数，实现相同的功能。  
用法如下：  

```c++
socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, 0);
```

## 总结
> + 子进程继承父进程无用的文件描述符后，子进程再调用exec系统调用会带来严重的危害，包括不限于占据socket、越权操作root文件、丢失文件句柄导致资源泄露
> + fcntl调用提供了close-on-exec属性。该属性的作用是：当fork创建子进程后，执行exec时会关闭带有close-on-exec属性的文件描述符
> + 自linux 2.6.23内核版本起，open系统调用支持参数O_CLOEXEC，通过按位或的方式传入flags参数中，实现相同的功能
> + 自linux 2.6.27内核版本起，socket也可以在type字段通过按位或的方式传入SOCK_CLOEXEC参数，，实现相同的功能


# Reference
[1] [关于fd的close on exec（非常重要）](https://blog.csdn.net/justmeloo/article/details/40184039?spm=1001.2101.3001.6661.1&utm_medium=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-40184039-blog-88283771.235%5Ev38%5Epc_relevant_default_base&depth_1-utm_source=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-40184039-blog-88283771.235%5Ev38%5Epc_relevant_default_base&utm_relevant_index=1)  