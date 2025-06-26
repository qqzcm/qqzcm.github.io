---
title: 读书笔记 —— Effective C++(5)
authors: fanventory
date: 2023-02-07 20:12:00 +0800
categories: [Reading Notes,Effective C++]
tags: [C++, Reading Notes]
---

> 上一节中我们介绍了用智能指针来管理资源，这一节我们将再次强调资源管理的重要性。我们简单介绍一些资源管理方面容易疏忽的小细节，这些小细节可能会导致你看似使用了正确的语法，但结果却造成了资源内存泄漏。首先我们可能会遇到一些无法用智能指针的情况，这时候如果还想完成自动释放功能，需要自己手写一个类来封装原来的类。这个过程中需要注意的细节是复制行为的问题，复制过程中我们该如何处理封装类呢？这个问题的细节将在接下来做仔细探讨。接着我们讲述了实际应用中需要原始指针而不是智能指针的情况，介绍了怎么将智能指针转换成原始指针。然后我们介绍new和delete对象数组时容易造成内存泄漏的情况，要记住有\[]则\[]，无\[]则无\[]。最后我们建议用智能指针封装new出来的对象时，最好独立一行编写，否则它也有小概率造成内存泄漏。资源泄漏方面的细节有很多，需要我们在实际编写代码时处处小心，积累经验，避免犯错。

<br>
<br>

# 自定义资源管理类的复制行为
我们上一节提到用智能指针来管理类，可以在类生命周期的结束自动完成释放功能，避免内存泄漏。但是智能指针在一些情况下可能不适用，比如智能指针一般用来修饰heap-bese资源，对于静态资源，我们需要它在逻辑结束的地方完成一些指定动作。这时候我们需要自定义资源管理类。我们下面通过一个例子来说明：  
假设我们使用C API函数完成Mutex互斥器功能，共有两个函数可以使用。  
```c++
void lock(Mutex* pm);
void unlock(Mutex* pm);
```

现在我们自定义一个资源管理类将其封装起来，实现区块末尾自动解锁的功能（和自动释放类似，代码结尾我们很有可能忘记解锁Mutex对象）。我们的代码可以这么实现：  
```c++
//  Lock类实现
class Lock{
    public:
        explicit Lock(Mutex* pm):mutexPtr(pm){
            lock(mutexPtr);
        }
        ~lock(){
            unlock(mutexPtr);
        }
    private:
        Mutex mutexPtr;
}
//  Lock类使用
Mutex m;    // 声明互斥器（静态变量）
...
{
    Lock m1(&m);
    ...
    //  区块结尾，自动调用析构函数完成解锁动作
}
```

对于资源的管理我们已经了解很多了，实现起来也并不困难，但这其中有一些我们需要注意的地方，比如当Lock发生了复制，我们要怎么处理？  
这里我们总结了这四种情况：  
1. 禁止复制  

像上面例子这种情况，互斥器Mutex应该只能有一个，复制功能是不合逻辑的。这种情况下我们可以禁用复制。
```c++
class Lock: private Uncopyable{
    public:
        ...
}
```

2. 引用计数

第二种情况是我们可以对底层资源进行引用计数，每复制一次计数加1，只有计数为0才释放对象内存（和shared_ptr的复制原理相同）。我们可以借助shared_ptr来改造我们的类：  
```c++
class Lock{
    public:
        explicit Lock(Mutex* pm):mutexPtr(pm,unlock){
            lock(mutexPtr.get());
        }
    private:
        shared_ptr<Mutex> mutexPtr;
}
```

3. 复制底部资源

第三种情况就是我们将底部资源进行复制。当然这种情况我们要注意“深度拷贝”，防止复制了某个引用，导致删除原来对象的时候，复制对象的私有变量为空。

4. 转移底部资源的拥有权

这种情况和auto_ptr的做法类似，复制完成后，拥有权转移到新的对象中，而原有对象会变成一个空对象。即资源会从被复制物转移到目标物。

## 总结
> + 自定义的资源管理类常见的复制行为有：禁止复制，施行引用计数法，复制底部资源，转移底部资源的拥有权

# 访问原始资源
## 需要访问原始资源的情况
用智能指针管理资源是防止内存泄漏一个很棒的做法，我们可以通过智能指针来访问对象，从而避免直接使用原始指针。那问题来了，有没有哪一种情况我们不能使用智能指针而使用原始指针的呢？  
答案是有的。当我们创建一个对象，想调用别人的API时，却发现别人API要求的参数是原始指针，如果我们传入智能指针，会提示参数类型不匹配并报错，就像下面这样：  
```c++
//  创建一个对象，并用智能指针管理它
shared_ptr<Investment> pInv(createInvestment());
//  这时第三方提供一个API，参数要求是原始指针
int daysHeld(const Investment *pi);
//  我们无法修改第三方的API，直接调用又是不对的，所以我们只能通过智能指针访问原始资源
int day=daysHeld(pInv); //  error，参数类型匹配错误
```

## 访问原始资源的方法
假设我们要用智能指针访问原始资源，我们有两种途径：  
1. 显式转换  
智能指针提供了get()方法执行显式转换，它会返回智能指针内部的原始指针，就像下面这样：  

```c++
int day=daysHeld(pInv.get());
```

2. 隐式转换  
隐式转换指智能指针通过重载操作符的方式，允许我们访问原始资源，就像下面这样：  

```c++
int day=daysHeld(&(*pInv)); // *pInv取出Investment对象，再转换为Investment *类型
//  除此之外，还可以通过隐式转换直接调用内部方法
(*pInv).isTaxFree();
pInv->isTaxFree();
```

## 重载隐式转换
有些情况可能我们需要用自己的类来管理资源，这时候我们需要对原先的资源进行封装。同样地，为了实际需要，我们要给出它的显式转换函数，就像下面这样：  
```c++
class fontPackage{
public:
    //  这两个方法作用一致
    char *GetFont(){
        return f;
    }
    operator Font*(){
        return f;
    }
private:
    Font f; // 原生字体类
};
//  这时我们有一个需要调用内部资源的方法
void testOperatorConvert(char *pf){
    doSomething();
}
//  使用显式转换方法
fontPackage fp;
testOperatorConvert(fp.GetStr());
//  使用隐式转换方法
testOperatorConvert(fp);
```


当然，隐式转换方法虽然便利，却可能出错
```c++
fontPackage pf1(new Font);
fontPackage pf2=pf1;
// 这里原意是要复制一个fontPackage对象，但是由于发生了隐式转换，pf2复制了一个Font对象
```

> 隐式类型转换，实现的基本方法就是：operator type_name();

## 总结
> + APIs往往要求访问原始资源，所以要提供一个获取原始资源的方法
> + 对原始资源的访问有显式转换和隐式转换两种，一般来说显式转换更安全，隐式转换更便利

# new和delete相对应
我们先来看一段代码，观察这段代码是否存在问题：  
```c++
string* stringArr=new string[100];
...
delete stringArr;
```

乍看之下好像没什么问题，new了对象之后在代码的末尾也及时delete了。但是我要告诉你，这段代码发生了内存泄漏！  
在解释为什么内存泄漏前，我们先来理解一下单一对象和对象数组有什么区别：  
单一对象的内存结构只有一块。  
<kbd>|内存|</kbd>

而对象数组，结构中往往会有一个字段标识数组大小。  
<kbd>|100|</kbd><kbd>内存</kbd><kbd>内存</kbd><kbd>...</kbd><kbd>内存|</kbd>

当我们new一个对象数组时，会先分配内存，然后调用100次构造函数。同样的，当我们delete时，会调用一次或多次析构函数，然后释放内存。  
现在看出问题所在了吗？  
因为我们使用的是`delete`而不是`delete[]`，导致了对象数组只调用了一次析构函数，而后面的99个对象造成了内存泄漏。

> 如果我们new了一个单一对象，但是调用了delete[]释放内存，则系统会读取前几个字节视为数组长度，然后调用析构函数释放掉后面连续的内存空间，造成了不确定行为。

## 容易忽视的情况
如果我们用typedef修饰对象数组，那delete过程则极容易犯错！！就像下面这样：  
```c++
typedef string addressLines[4];
// new
string* pal=new addressLines;
// delete
delete pal; // error
delete[] pal; //ok
```

我们极可能看到new时没有\[]，所以在delete的时候没有加上\[]。但看清楚，我们typedef声明的时候，他就已经是个对象数组了。为了防止这种情况，我们一般建议使用vector来实现对象数组，比如vector<string>。

## 总结
> + 如果new表达式中使用了\[]，则相应的delete表达式要加上\[]。如果new表达式中没有使用\[]，则相应的delete表达式不能加上\[]

# 以独立语句将new对象置入智能指针中
我们先从一个例子入手，现在我们手上有两个方法，一个是动态定义优先级的方法，另一个是执行方法：  
```c++
int priority();
void processWidget(shared_ptr<Widget> pw,int priority);
```

接着我们来调用执行方法:  
```c++
processWidget(shared_ptr<Widget>(new Widget),priority());
```

上面这个方法用智能指针管理了Widget对象资源，乍看之下好像没什么问题，但是我要告诉你：这条简单的语句可能会发生内存泄漏！  
在调用processWidget语句之前，系统会先完成三件事：
+ 执行new Widget语句
+ 调用shared_ptr<Widget>构造函数
+ 执行priority方法

<br>

但c++编译器可能会进行优化：对这三件事的顺序进行调整，由于new Widget是shared_ptr<Widget>构造函数的参数，所以new Widget一定比shared_ptr<Widget>的构造函数先执行，但priority方法可以在任意阶段执行。  
我们来下面这种执行顺序：  
+ 执行new Widget语句
+ 执行priority方法
+ 调用shared_ptr<Widget>构造函数

如果执行priority方法的过程中发生了异常！那第一步new出来的Widget对象就没有被delete掉，也没有被shared_ptr<Widget>封装，所以Widget对象的内存就不会被释放掉，造成内存泄漏！  

<br>

为了解决这个问题，最好的方法是分离语句，就像下面这样：  
```c++
shared_ptr<Widget> pw(new Widget);
processWidget(pw,priority());
```

这样子，编译器对于跨语句的操作并不会重新排列，因为程序是按代码行顺序从上往下执行的（只有在同一个语句内才有重新排列的自由）。从而达到避免内存泄漏的目的。

## 总结
> + 以独立语句将new对象置入智能指针中，可以避免同一语句中因为异常而导致的内存泄漏

# Reference
[1] <<Effective C++>>  
[2] <<C++ Primer>>  
[3] [C++隐式类型转换 operator T](https://blog.csdn.net/micx0124/article/details/12389973)  