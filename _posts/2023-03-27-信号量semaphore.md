---
title: C++ —— 信号量semaphore
authors: fanventory
date: 2023-03-27 17:13:00 +0800
categories: [other, C++]
tags: [C++, semaphore, semaphore.h]
---

# 信号量semaphore
> 信号量（Semaphore）的概念最早由荷兰计算机科学家 Dijkstra（迪杰斯特拉）提出，有时又称“信号灯”。信号量是多线程环境下的一个全局变量，它表示最多可以有几个任务同时访问某个共享资源。

<br>
<br>

## 作用
信号量的本质是一个全局变量，可以根据实际场景设置信号量的大小（取值范围>=0）。信号量为N表示最多有N个进程或线程访问某个共享资源。  
此外，信号量支持“加1”和“减1”操作，而且修改值时是以“原子操作”的方式实现的。通过“加1”和“减1”来控制共享资源的访问线程数（信号量可用于线程或进程，为了方便，下面只用线程进行说明）。

## 规则
多线程程序中，使用信号量需遵守以下几条规则：  
1. 信号量的值不能小于 0
2. 有线程访问资源时，信号量执行“减1”操作，访问完成后再执行“加1”操作
3. 当信号量的值为0时，想访问资源的线程必须等待，直至信号量的值大于0，等待的线程才能开始访问

## 分类
1. 二进制信号量：指初始值为 1 的信号量，此类信号量只有 1 和 0 两个值，通常用来替代互斥锁实现线程同步
2. 计数信号量：指初始值大于 1 的信号量，当进程中存在多个线程，可以用计数信号量来限制同时访问资源的线程数量

## 定义
信号量相关的类定义在<semaphore.h>头文件中，定义如下：  
```c++
#include <semaphore.h>
sem_t mySem;    //  POSIX标准中，信号量用sem_t类型表示
```

## 初始化
sem_init()函数专门用来初始化信号量，语法如下：  
```c++
int sem_init(sem_t *sem, int pshared, unsigned int value);
```

其中，各个参数的含义为：  
+ sem：表示要初始化的目标信号量
+ pshared：表示该信号量是否可以和其他进程共享，值为0时表示不共享，值为1时表示共享
+ value：设置信号量的初始值
+ 返回值：初始化成功返回0，否则返回-1

## 操作信号量
```c++
//  sem_post函数：将信号量的值“加1”，同时唤醒其它等待访问资源的线程
int sem_post(sem_t* sem);
//  sem_wait函数：
//  当信号量的值大于0时，sem_wait函数会对信号量做“减1”操作；
//  当信号量的值为0时，sem_wait函数会阻塞当前线程，直至有线程执行sem_post函数，暂停的线程才会继续执行
int sem_wait(sem_t* sem);
//  sem_trywait函数：和sem_wait函数类似，但信号量的值为0时，不会阻塞当前线程，而是立即返回-1
int sem_trywait(sem_t* sem);
//  sem_destory函数：销毁信号量
int sem_destroy(sem_t* sem); 
```

上面这些函数操作成功时，返回值都为0。

## 例子
我们通过一个例子说明信号量的用法： 
假设我们有一个数据库连接池，连接池的最大连接为2。现在我们有5个请求需要操作数据库，他们需要竞争获取连接池，为了实现互斥访问连接池，我们使用信号量来实现。  
首先，我们定义5个线程表示5个数据库连接请求，因为连接池最大数量为2，所以信号量设为2。
```c++
//	信号量声明为全局变量
sem_t sem;

int main(){
	//	用5个线程表示现在有5个数据库连接正在执行
	pthread_t conn[5];
	//初始化信号量，表示连接池最大数量为2
    sem_init(&sem, 0, 2);
	//	创建5个线程，执行sql查询任务
	for (int i = 0; i < 5; i++)
    {
        int flag = pthread_create(&conn[i], NULL, doSql, &i);
        if (flag != 0)
        {
            std::throw Exception(); //  线程创建失败
        }
        cout<<"conn " << i << " 线程创建成功 "<<endl;
        usleep(1);
    }
	
	//	结束进程
	for (int j = 0; j < 5; j++)
    {
        int flag = pthread_join(conn[j], NULL);
        if (flag != 0) {
            std::throw Exception(); //  线程等待失败
        }
    }
	//	销毁信号量
    sem_destroy(&sem);
	
	return 0;
}
```

接着我们在doSql函数内，实现信号量的操作：  
```c++
void *doSql(void *arg){
	int id = *((int*)arg);
	//	用信号量限制连接池，如果连接池为空，则阻塞程序
	if (sem_wait(&sem) == 0)
    {
        //  从连接池中获取数据库连接
        cout << "---conn " << id << " 正在执行sql " <<endl;
		//	数据库执行sql并返回结果
        usleep(2);
        cout << "---conn " << id << " 正在执行sql " <<endl;
        //  将数据库连接归还连接池
        //	信号量加1，表示归还连接到连接池，同时唤醒阻塞的线程
        sem_post(&sem);
    }
    return 0;
}
```

输出结果为：  
```
# 编译: g++ semaphoreTest.cpp -o semaphoreTest  -pthread
# 执行：./semaphoreTest
# 输出：
conn 0 线程创建成功
---conn 0 正在执行sql
---conn 0 执行sql结束
conn 1 线程创建成功
---conn 1 正在执行sql
---conn 1 执行sql结束
conn 2 线程创建成功
---conn 2 正在执行sql
---conn 2 执行sql结束
conn 3 线程创建成功
---conn 3 正在执行sql
---conn 3 执行sql结束
conn 4 线程创建成功
---conn 4 正在执行sql
---conn 4 执行sql结束
```

## C++20信号量
C++20中引入了信号量，存储在头文件\<semaphore>中。  
头文件中的类分为counting semaphore和binary semaphore，对应上面的计数信号量和二进制信号量。

## 总结
> + 信号量是多线程环境下的一个全局变量，它表示最多可以有几个任务同时访问某个共享资源
> + 信号量相关的类定义在<semaphore.h>头文件中


# Reference
[1] [Linux信号量详解](http://c.biancheng.net/view/8632.html)  
[2] [C++ 多线程（七）：信号量 Semaphore 及 C++ 11 实现](https://zhuanlan.zhihu.com/p/512969481)  