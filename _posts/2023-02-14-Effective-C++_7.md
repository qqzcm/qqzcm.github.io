
---
title: 读书笔记 —— Effective C++(7)
authors: fanventory
date: 2023-02-14 16:51:00 +0800
categories: [Reading Notes,Effective C++]
tags: [C++, Reading Notes]
---

> 本节我们专注于类内成员的一些设计细节。首先我们论证为什么不用public修饰成员变量，而是将成员变量声明为private。其中最重要的一点是这样做可以保证类的封装性，为我们以后修改或扩展代码带来方便。接下来我们讨论了为什么要用non-member函数替换member函数。其中很重要的一点原因也是因为保证类的封装性，可见封装性的重要性。接着我们展示了non-member函数的实现。最后我们还是将目光放在non-member函数，发现在一些参数需要类型转换的函数中，non-member函数是我们唯一的选择。

<br>
<br>

# 成员变量声明为private

我们学习C++时，一般都会把成员变量声明为private，你知道这是为什么吗？为什么成员变量选择private，而不是public和protected类型？  
接下来我们从两方面探讨用private修饰成员变量的好处以及必要性： 
首先我们论证为什么不用public修饰成员变量，然后我们再论证为什么不用protected修饰成员变量，最后我们得出结论，成员变量要声明为private类型。 

## 为什么不用public

为什么不用public，我们给出四点理由：  

1. 语法一致性

如果成员变量是public，意味着当我们使用点操作符(比如person.age)的时候，你会不清楚这里的age是成员变量还是成员函数，如果是函数，我们需要写成person.age()，在后面加上括号。  
虽然现在的IDE可以智能提示哪些是成员变量，哪些是成员函数，但是总有一些需要用到原始编辑器的地方（比如生产环境中使用vim）。这时我们查看类的定义去判断它是成员变量还是成员函数，这显得非常不方便。  
相反，如果成员变量都用private修饰，那我们只能通过成员函数去访问这些变量，可以省下很多时间，这就是语法的一致性。

2. 控制成员变量的读写权限

上面这个理由可能不能令你满意，那我们来看看其他好处。令变量声明为private，意味着我们可以控制成员变量的读写权限。  
举个例子，我们有三个成员变量a,b,c。其中a变量是可读可写的，b变量是只读的，c变量的只写的。如果我们用public修饰变量a，b，c，思考一下要怎么控制这三者的访问权限呢？  
我猜你想了半天，最后告诉我好像C++没有这样的关键词修饰读写权限，也就是说实现不了这样的功能。  
确实，public将所有的变量访问和修改权限放开了，导致我们不能精确地控制成员变量的读写权限。反过来，只要我们将所有成员变量改为private，收回访问和修改的权限，就能通过成员函数来控制读写权限。就像下面这样：  
```c++
class Access{
public:
    ...
    int getReadWrite() const { return a; } // 读a
    void setReadWrite(int value) { a = value; } // 写a
    int getReadOnly() const { return b; } // 只读b
    void setReadOnly(int value) { c变量的只写的 = value; } // 只写c
private:
    int a;  //  可读可写
    int b;  //  只读
    int c;  //  只写
};
```

3. 封装

第三个建议成员变量不要使用public的原因是：private能够完成类的封装。封装是什么意思呢？让我们来想象一个场景：  
我们现在有一个自动测速程序，当汽车通过时，其速度会被记录。自动测试程序类中有一个计算平均速度的函数：  
```c++
class SpeedDataCollection{
public:
    void addValue(int speed);   //  记录速度
    double averageSoFar() const;    //  返回平均速度
    ...
};
```

现在averageSoFar()方法有两种实现：

1. 每次记录速度，就自动计算最新的平均速度，然后存放在一个队列中。
2. 记录速度到一个队列中，当我们需要计算平均速度的时候，才调用该方法计算平均值。

这两种方法各有优劣，第一种节省了计算时间，当我们需要查询平均速度的时候，可以在O(1)时间能查出，适合查询比较频繁的场合。当然，缺点就是每次计算的平均速度都需要用一个队列存储，空间损耗比较大。第二种方法则相反，空间损耗比较小，调用averageSoFar()方法的适合才计算平均值，但是它的时间花销比较大，适合于数据量较小或者查询次数比较少的场合。  

这两种方法有各自适用的场合，在我们程序刚开始运行的适合，数据量较小，内存比较吃紧，可能会采用第二种方法。但当我们程序运行了很长一段时间，临时计算平均值所带来的时间开销以及无法忍受了，而且随着机器硬件的扩容，我们可能会转换第一种实现方法。  

<br>

这时候封装的好处就体现出来了，我们只需要修改类内对应函数的逻辑实现，就可以完成方法的转换。试想一下，如果我们的成员变量（比如该例子中记录速度的列表）声明为public，那客户可能外部代码中使用了记录速度的列表，当我们修改averageSoFar()的实现时，可能对应的数据结构也发生了改变，导致外部代码的那一部分也要发生修改，增加了程序的耦合性。  
所以成员变量声明为private可以增强代码的封装性，而封装性越强越有利于后续代码的扩展和修改。

4. 保证约束，提供弹性

将成员变量声明private意味着将变量隐藏在函数接口后面，这样我们可以通过函数接口实现一些约束条件，比如判断int类型的变量是否为负数。而反过来，将成员变量声明public，用户则可以直接调用该变量，使我们的约束条件失效。由于用private声明成员变量时，只有成员函数才能影响变量，所以我们的约束条件总能得到维护，还保留了日后修改这些条件的权利。  


除此之外，将成员变量声明private还可以让程序实现更具弹性。比如：  
1. 读写成员变量的时候，可以生成日志或通知其他对象
2. 读写成员变量的时候，可以验证函数前提或事后状态，根据状态动态修改变量值
3. 在多线程环境中同步控制环境变量

## 为什么不用protected

为什么不用protected？和上面所述不用public声明成员变量一样，上面的几点理由同样适用于protected数据：  

1. 语法一致性
2. 控制成员变量的读写权限
3. 封装
4. 保证约束，提供弹性

看到封装可能我们会有个疑问？我们知道protected修饰的变量只能被派生类访问，不能被其他外部类访问，那protected的封装性是否大于public呢？  
答案是：并非如此。

<br>

封装性与移出该成员变量时被破坏的代码数量成反比。假设我们有一个public成员变量，并取消了它，所有直接使用它的成员函数以及外部代码都会被破坏。那我们假设有一个protected成员变量，同样取消了它，所有使用它的派生类都会被破坏。这两者对代码数量的破坏都是`不可预估的`，他们都不具备封装性。如果我们在编写代码的时候，使用了public成员变量或protected成员变量，就会很难改变这个变量涉及的一切代码，因为你需要大量的工作进行重写，重新测试，重写编写文档，重新编译。

## 总结
> + 成员变量应该声明为private，这有利于实现语法一致性，控制成员变量的读写权限，保证约束条件，为class实现提供弹性
> + protected并不比public更具封装性

# 用non-member函数替换member函数
## 什么是member函数？
什么是member函数？什么是non-member函数？我们先来看一个例子：  
我们有个class表示浏览器，其中有这三个函数，分别是清理缓存，清理访问过的URL历史记录，清理所有的cookies:
```c++
class WebBrower{
public:
    ...
    void clearCache();      //  清理缓存
    void clearHistory();    //  清理访问过的URL历史记录
    void removeCookies();   //  清理所有的cookies
    ...
};
```

现在我们考虑用一个函数集成这三种功能，即清理系统所有缓存信息，我们有以下两种做法：  

1. 第一种，我们可以再写一个成员函数，该成员函数调用这三个清理函数。这种就是member函数（成员函数）。

```c++
class WebBrower{
public:
    ...
    void clearEverything(){
        this->clearCache();
        this->clearHistory();
        this->removeCookies();
    };
    ...
};
```

2. 第二种，我们可以用一个外部函数通过对象调用这三个清理函数。这种就是non-member函数（非成员函数）。
```c++
void clearEverything(WebBrower& wb){
    wb.clearCache();
    wb.clearHistory();
    wb.removeCookies();
}
```

这两种方法实现的功能一样，看起来也没太大区别，那有没有想过哪种方法会更好呢？  
我们先给出结论，用non-member函数替换member函数更好。现在我们从封装性的角度进行探讨：  

## 为什么non-member函数更好？

封装性是把类中的一些数据隐藏，让客户看不见。前面我们说过，越多的东西被封装，我们改变这些东西的能力就越大，我们改变时影响的东西就越有限。那反过来，我们封装的数据是固定的，我们编写的成员函数越多，意味着封装的数据有更多的途径能被改变。那我们修改封装数据的时候，需要修改的成员函数就越多，这就意味着封装性越差。  
所以我们得出一个结论，越多的函数可以访问封装数据，封装性就越低。从这个角度讲，当然是non-member函数更好啦，它减少了一个可以修改封装数据的入口！

这里有几个小细节需要我们注意：  
+ 封装的不止privat数据，还包括private函数、enums、typedefs等等
+ friend函数也可以访问private数据，所以我们也要用non-friend函数去替代friend函数
+ 这个建议并不是说集成函数一定不是非成员函数，它也可以是其他class的member函数，因为这不会影响原来类的封装性

## 怎么实现non-member函数？
在C++中，一个比较自然的做法就是将clearEverything声明为一个non-member函数，并放置在WebBrower类所在的同一个namespace中。
```c++
namespace WebBrowerStuff{
    class WebBrower{
        ...
    };
    void clearEverything(WebBrower& wb);
}
```

我们将clearEverything()函数放到namespace中，可以带来许多好处：
1. namespace和class不同，前者可以跨越多个源码文件，但后者不能
2. clearEverything()函数只是一个提供便利的函数，它是可有可无的（可以通过调用三个清理函数实现），所以它并没用对WebBrower类有什么特殊访问的权力，它不应该成为一个member函数
3. 将clearEverything()函数放到namespace中有利于扩展，降低编译依存性

我们举个例子，现实生活中WebBrower类有大量的便利函数，有些是关于书签的，有些是关于cookie的。假设我们当前场景需要完成一些关于书签的工作，其他关于cookie的便利函数并不是我们想要的。这时候我们可以将不同的函数分离到不同的头文件。还记得namespace可以跨越多个源码文件吗？这些函数哪怕分离到不同的头文件，它们依然在同一个namespace下面。

```c++
//  头文件webBrower.h 存放webBrower类和一些核心函数
namespace WebBrowerStuff{
    class WebBrower{...};
    ... //  核心函数，所有客户都需要的
}

//  头文件webBrowerBookmarks.h 存放书签相关的便利函数
namespace WebBrowerStuff{
    ... //  存放书签相关的便利函数
}

//  头文件webBrowerCookies.h 存放cookie相关的便利函数
namespace WebBrowerStuff{
    ... //  存放cookie相关的便利函数
}
```

> 在c++标准程序库中也是采用同样的做法，每个头文件（如<vector>,<algorithm>)声明std的某些机能，当我们想要某些功能时，只要引入相关的头文件即可。这允许客户只对他们所用的那一小部分系统形成编译相依。

将多个便利函数分离到不同的头文件，使我们可以轻松地扩展功能。如果需要增加播放器相关的便利函数，只要在WebBrowerStuff命名空间下面建立一个新的头文件，然后完成函数声明即可。这是class所不具备的，因为class必须整体定义，不能被分割成多个片段。这样看，用non-member函数相比member函数还有利于扩展的优点。

<br>

或许你会有一个小小的疑问，class也有扩展能力呀！那就是通过继承派生出新的类，从而获得新的功能。  
确实，class也有扩展能力，但它的扩展能力也有缺陷：    

1. 派生类无法访问基类中被封装的成员，也没有为类提供新的变化，这样的拓展并不符合继承思想的初衷
2. 并非所有的class都是被设计为基类的

## 总结
> + 用non-member函数替换member函数。这样做可以增加封装性，扩展性

# non-member函数解决参数类型转换问题

我们用有理数乘法来举一个例子，说明non-member函数解决参数类型需要转换的问题。
现在我们有一个有理数类Rational：  
```c++
class Rational{
public:
    Rational(int numerator = 0, int denominator = 1);   //  这里不使用explicit，
                                                        //      允许int隐式转换为Rational类型
    int getNumerator() const;
    int getDenominator() const;
    const Rational operator* (const Rational& rhs) const;
    ...
private:
    int numerator;
    int denominator;
};
```

这个类实现了一个简单的相乘功能，可以将两个有理数相乘。这时候我们提出一个需求，让有理数和整数相乘（这很合理），让我们来看看运行结果：  
```c++
Rational r1(1,8);
Rational result = r1 * 2; // ok
result = 2 * r1; // error
```

我们发现第二个乘法式子报错了，这和我们的逻辑不符，乘法应该满足交换律才对！  
我们先来探讨一下为什么第一个式子可以正常运行，而第二个式子不行。  
我们把这两个式子的函数调用展开：  
```c++
Rational result = r1.operator*(2); // ok
result = 2.operator*(r1); // error
```

我们可以看到，第一个式子中，r1调用了重载乘法运算符函数，实参为2。实参传入后发生了隐式类型转换，相对于这个这样：  
```
Rational tmp(2);    //  这里的2按顺序初始化给了numerator变量
Rational result = r1.operator*(tmp); // ok
```

而第二个式子中，整型数2调用了重载运算符operator*，2怎么可能有重载这个运算符嘛，当然报错了。  
为了解决这个问题，我们想到`2 * r1`这种写法，编译器会尝试寻找对应的non-member operator*函数，将函数转换成这种形式：  
```c++
result=operator*(2,r1);
```

然后2可以隐式转化为Rational对象，那问题就简单了，只要我们编写一个non-member operator*函数就可以了。我们在global作用域或者命名空间中插入non-member operator*函数：
```c++
namespace RationalStuff{
	class Rational{...};
    //  non-member operator*函数
	const Rational operator* (const Rational& lhs,const Rational& rhs) {
		return Rational(lhs.getNumerator() * rhs.getNumerator(), lhs.getDenominator() * rhs.getDenominator());
	}
}
```

然后我们再来编译运行上面的代码：  
```c++
Rational r1(1,8);
Rational result = r1 * 2; // ok
result = 2 * r1; // ok
```

问题就顺利解决了！但是还有一个小疑问：operator*声明成一个friend函数呢？  
首先声明为friend函数是可行的，但我们并不支持这种做法，因为friend函数会破坏类的封装性（哪怕只破坏了一点点）。  
friend函数设计的初衷是使得普通函数直接访问类的私有数据，避免了类成员函数的频繁调用，从而节约处理器开销，提高程序的效率。但在现在cpu速度越来越快的今天，这点开销已经微乎其微了。相反，破坏封装性带来的危害更大。很多C++程序员认为如果一个与某个class相关的函数不该成为member函数，那就设计为friend函数，这是不对的。我们应该能不用friend函数就不用friend函数。

## 总结
> + 如果你需要为某个函数的所有参数进行类型转换，这个函数必须是non-member
> + 我们应该能不用friend函数就不用friend函数

# Reference
[1] <<Effective C++>>  
[2] <<C++ Primer>>  
[3] [C++中的friend函数详细解析（二）](https://www.cnblogs.com/sggggr/p/15693581.html)  