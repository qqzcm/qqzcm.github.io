---
title: 读书笔记 —— Effective C++(2)
authors: fanventory
date: 2022-12-03 11:05:00 +0800
categories: [Reading Notes,Effective C++]
tags: [C++, Reading Notes]
---

> 众所周知，对象使用之前应该先被初始化，针对自定义类的初始化，我们通过赋值和初始化的差别，给出了构造函数初始化过程的建议写法。而对于跨编译单元，non-local static对象的初始化顺序不能明确确定，所幸我们通过一些简单的技巧可以解决这个问题。

<br>
<br>

# 对象使用之前已被初始化
## 建议
众所周知，对象使用之前最好先初始化，这是因为C++读未初始化的变量时，会读入一些随机的bits，导致程序产生莫名的错误。关于初始化的重要性，我们不需要做过多阐述，我们将初始化的变量类型分为两类，以对照的方式深入研究初始化过程中的一些细节。
1. C++内置类型初始化，如int，double，int*等
2. C++自定义类的对象初始化，通过构造函数完成初始化

## 总结
> + 永远在使用对象之前先将它初始化
> + 确保每一个构造函数都将每一个成员初始化

# 初始化与赋值
我们先来看下面一段代码：
```c++
class PhoneNumber{...};
class ABEntry{
public:
    ABEntry(const std::string& name,const std::string& address,
            const std::list<PhoneNumber> &phones);
private:
    std::string theName;
    std::string theAddress;
    std::list<PhoneNumber> thePhones;
    int numTimesConsulted;
};
ABEntry::ABEntry(const std::string& name,const std::string& address,
                 const std::list<PhoneNumber> &phones)
{
    theName=name;
    theAddress=address;
    thePhones=phones;
    numTimesConsulted=0;
}
```

问题：上面的构造函数是完成初始化吗？  
你可以会想：当然，构造函数不就是来完成对象初始化的吗？  
实际上，这个构造函数并不真的是对象初始化，而是赋值！那初始化和赋值有什么区别呢？我们从更底层的程序运行机制来探讨这个问题：  
首先，string和list类型并不是C++的基本类型，而是一个类。而类的初始化过程是在构造函数中完成的。所以上述`ABEntry`类的构造过程是这样的：  
1. 首先`ABEntry`调用构造函数
2. name、address、phones变量调用各自的default（无参）构造函数创建成员对象
3. 在构造函数体中，对刚刚创建的对象完成赋值操作

> C++ 规定对象的成员变量（如name、address）的初始化动作发生在进入构造函数本体（即ABEntry）之前。

既然赋值和初始化得到的结果是一样的，那我们有必要深究他们之间的区别？  
有的！成员对象default构造函数完成之后，立即赋予新值，那default构造函数所做的一切就没有意义了。也就是说，初始化的效率要高于赋值。当我们构造一个及其复杂的对象时，这些小的细节能带来巨大的速度优化！  
> 对了，我们注意到numTimesConsulted是int类型，它是内置的基本类型，它没有构造函数，那它赋值和初始化在效率上有差别吗？
> 既然没有构造函数，也就是说，其初始化和赋值的成本几乎是相同的。

那既然这种构造函数的写法不是初始化，那自定义类的初始化过程该怎么写呢？
```c++
ABEntry::ABEntry(const std::string& name,const std::string& address,
                 const std::list<PhoneNumber> &phones)
                 :theName(name),theAddress(address),thePhones(phones),numTimesConsulted(0)
{ }
```

> 虽然我们上面说内置类型的初始化和赋值过程是相同的，但为了统一和美观，我们把numTimesConsulted变量也采用初始化的写法

当然如果我们想要构造一个无参构造函数，也可以采用初始化的写法，只用参数指定为空即可。
```c++
ABEntry::ABEntry():theName(),theAddress(),thePhones(),numTimesConsulted(0)
{ }
```

> 《Effective C++》中建议在构造函数中，即使某些成员变量不需要传参，也把它们全部列出来。这样做的好处是可以一目了然看出什么成员变量需要赋予初始值，而什么变量不需要赋初值，而且不会遗漏需要初始化，但又没有赋初值的变量。

## 特殊情况
如果成员变量是const或者references，它们就一定要用初值初始化，而不能被赋值。  
为了避免记住成员变量什么时候一定要初始化，什么时候不需要，一个简单的做法是：总是采用初始化写法！这样不仅安全，而且相比赋值更高效！

## 消除重复
如果我们有多个构造函数，某些构造函数的初始化过程是一样的，就会导致不受欢迎的重复和无聊的复制。这种情况下我们可以做出一些折中，把一些内置类型（因为它们的初始化成本和赋值成本相同）的初始化抽离出来，单独形成一个函数，然后供所有的构造函数调用。当然，对于程序而言，最高效的做法还是把所有成员变量采用初值列的方式初始化。  

## 总结
1. 内置类型初始化和赋值成本相同，而自定义类型初始化比赋值更高效
2. 如果成员变量是const或者references，一定要用初值初始化，不能被赋值
3. 建议把所有成员变量都采用初值列的方式初始化，这种做法安全且高效

# 初始化顺序
类在初始化时，先初始化base classes（基类），再初始化derived classes（派生类）。在同一个类中的成员变量，按照声明顺序进行初始化。  
这里给出一个建议，初值列中最好以声明的顺序列出各个成员，这样的写法有两个好处：
1. 统一，一目了然，减少阅读者的迷惑
2. 防止一些隐晦的错误，比如两个成员变量的初始化顺序有要求（初始化时array需要指定大小，指定大小的成员变量需要先完成初始化）

同一个文件的初始化过程我们已经了解清楚了，只要我们按照建议，就能将出错的概率降到最小。但是不同文件的情况呢？  
> 一个编译单元指产出单一目标文件，即一个.cpp文件加上它的头文件。

接下来我们深入探讨不同编译单元的初始化顺序。在这之前，我们先介绍一个概念——non-local static对象，因为它是多文件编译时，最容易出问题的一类对象。

## non-local static对象
首先先明确一点，non-local static不是指static关键字定义的对象。这里是static是全局的意思，即内存在data段和bss段中的对象。既然是全局变量，至少可以排除那些内存是在堆中和栈中的对象了，因为它们会随着函数的出栈等改变当前作用域的情况，结束自己的生命周期。non-local static对象在整个程序的生命周期内都是存在的，除非程序结束否则会一直存在。  
如果是在函数内部定义的static对象，那么这种static对象被称为local static对象，除此之外的都是non-local static对象，包括以下几种：
1. global对象
2. 定义于namespace的对象
3. class作用域内使用static关键字声明的对象
4. file作用域内使用static关键字声明的对象

## 问题
因为C++对定义于不同编译单元内的non-local static对象的初始化次序并无明确定义，所以存在这样一种情况：  
如果编译单元A的non-local static对象初始化过程中，调用了另一个编译单元B的non-local static对象，而编译单元的non-local static对象可能还没完成初始化。  
下面我们用一个例子说明这个问题：  
我们假设构建一个FileSystem的类，这个类封装了操作网络文件的各种方法，让你使用起来像在操作单机文件。假设该类中有一个readDist方法，读取本机的磁盘数量，该数量在构造函数中初始化。  
`FileSystem.cpp文件`  
```c++
#include <iostream>
#include "common.h"
FileSystem fs; // 操作文件类
```

同时我们构建一个Directory的类，这个类调用FileSystem的方法，创建一个临时目录。  
`Directory.cpp文件`  
```c++
#include <iostream>
#include "common.h"
Directory dt; // 目录类，用于创建一个临时目录
```

程序入口main方法，这里我们主要观察FileSystem和Directory类的初始化顺序，所以main方法的内容并不重要。  
`main.cpp文件`  
```c++
#include <iostream>
#include "common.h"
using namespace std;
int main()
{
    cout << "example" << endl;
    return 0;
}
```

common.h文件包括了FileSystem和Directory类的具体实现，并把FileSystem类接口暴露出来。  
`common.h文件`
```c++
#ifndef _LIB_H_
#define _LIB_H_

#include <iostream>
using namespace std;
class FileSystem;
extern FileSystem fs;

class FileSystem
{
public:
    FileSystem()
    {
        value = 100; // 假设初始化值为100
        cout << "fs construct" << endl;
    }

    void readDist()
    {
        cout << "fs readDist: " << "value=" << value << endl;
    }
private:
    int value;
};

class Directory
{
    public:
        Directory()
        {
            cout << "Temp Directory construct" << endl;
            fs.readDist();
        }
};
#endif
```

接下来我们来编译这三个类，编译过程如下：  
```c++
//  编译文件
g++ -c -o Directory.o Directory.cpp 
g++ -c -o FileSystem.o FileSystem.cpp 
g++ -c -o main.o main.cpp

g++ Directory.o FileSystem.o main.o 
./a.out
fs construct
Temp Directory construct
fs readDist: value=100
example

g++ FileSystem.o Directory.o main.o 
./a.out
Temp Directory construct
fs readDist: value=0
fs construct
example
```

从实验结果我们可以看到，第二次运行程序的时候，value的值为0，说明在FileSystem类初始化之前，它就被调用了。在实际工程中，未初始化先调用很容易引起意想不到的错误，所以我们得确保FileSystem类被调用之前先初始化。那怎么能够确定它调用之前初始化呢？  
答案是：`无法确定`。因为确定它们的初始化顺序非常非常困难，甚至会无解。特别在`隐式模板具体化`（implicit template instantiations）编译得到的non-local static对象不但不可能得到正确的初始化顺序，甚至不值得去找“正确顺序”的特殊情况。  

> 隐式模板具体化指类或函数模板只有当使用模板时，编译器才根据模板定义生成相应类型的实例。而non-local static对象在调用之前，不知道初始化成什么模板类型，导致无法先完成初始化动作。

## 解决方案
既然如此，那这个问题无解了吗？不，我们给出一个简单的解决方案：  
将这些non-local static对象放置在自己的专属函数中（对象在此函数声明为static），然后返回一个reference指向该对象。当用户需要这些对象时，调用该函数，而不是直接使用该对象。换句话说non-local static对象被替换为local static对象。也就是我们熟悉的，`单例模式`。  
改造后的代码如下：  
`FileSystem.cpp文件`
```c++
FileSystem& getFileSystem()
{
    static FileSystem fs;
    return fs;
}
```

`common.h文件` 
```c++
#ifndef _LIB_H_
#define _LIB_H_

#include <iostream>
using namespace std;
class FileSystem;
FileSystem& getFileSystem();

class FileSystem
{
public:
    FileSystem():value(100) // static不能用赋值方式初始化
    {
        // value = 100; // 假设初始化值为100
        cout << "fs construct" << endl;
    }

    void readDist()
    {
        cout << "fs readDist: " << "value=" << value << endl;
    }
private:
    int value;
};


class Directory
{
    public:
        Directory()
        {
            cout << "Temp Directory construct" << endl;
            getFileSystem().readDist(); //改成通过返回来获取fs的引用
        }
};
#endif
```

这样修改成功的原因在于，C++保证local static对象会在该函数首次被调用期间，才完成初始化。如果没调用，则不会出发构造函数。

## 特殊情况
当然这种方法也有麻烦，即内含static对象在多线程系统中有不确定性。无论是non-local static还是local static对象，由于多线程顺序是不确定的，导致存在初始化顺序不确定的情况。  
我们给出了一种简单的处理方法，在程序开始运行时，先采用单线程的方法手动调用所有的单例构造函数，这可以消除与初始化有关的竞速形势（race conditions）。  
当然，这需要我们手动确定初始化顺序，对开发者而言依然是个麻烦事。

## 总结  
> + 为避免“跨编译单元的初始化顺序”问题，建议用单例模式将所有的non-local static对象替换为local static对象

# Reference
[1] <<Effective C++>>  
[2] [non-local static对象初始化顺序](https://blog.csdn.net/zhangyifei216/article/details/50549703)  
[3] [模板显式、隐式实例化和（偏）特化、具体化的详细分析](https://blog.csdn.net/gettogetto/article/details/72824756)