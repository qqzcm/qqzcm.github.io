---
title: 读书笔记 —— Effective C++(8)
authors: fanventory
date: 2023-02-14 16:51:00 +0800
categories: [Reading Notes,Effective C++]
tags: [C++, Reading Notes]
---

> 上节我们讨论很多类设计过程的细节，这一节中，我们将尝试写一个swap函数。我们先写出它的普通版本。普通版本通过拷贝实现，某些情况下效率低下。所以我们决定用复制指针来代替拷贝整个对象，提出第二个特化版本。最后针对模板类型，我们提出自定义命名空间中专属版本。

<br>
<br>

# 经典版本
swap相信大家并不陌生，经典的swap函数写法如下所示：  
```c++
namespace std {
    template<typename T>
    void swap(T& a,T& b)
    {
        T temp(a);
        a = b;
        b = temp;
    }
}
```

经典的版本只要类型T支持copy构造函数和copy赋值操作，就能实现swap操作。  
接下来我们要对这个swap版本进行改造，首先我们发现生成一个临时对象，再进行赋值，如果对象过大，赋值和构造的成本会很高，所以我们决定用指针来代替构造对象。

# 特化版本
pimpl(pointer to implementation)，意思是用指针指向一个对象，内含真正的数据，很多类设计时都会采用这样的思想。假如我们有一个类Widget，它的pimpl实现就会像下面这个样子：  
```c++
//  具体数据
class WidgetImpl{
public:
    ...
private:
    int a,b,c;
    vector<double> v;
    ...
};

class Widget{
public:
    Widget(const Widget& rhs);
    Widget& operator=(const Widget& rhs){
        ...
        *pImpl = *(rhs.pImpl);
    }
private:
    WidgetImpl* pImpl;
};
```

要实现Widget对象的置换，其他我们只要置换pImpl指针就可以了。但是default的swap算法并不知道这一点，而是复制了三次Widget，还复制了三次WidgetImpl，非常缺乏效率。所以针对Widget类，我们可以写出一个特化版本：  
```c++
namespace std {
    template<>
    void swap<Widget>(Widget& a,Widget& b)
    {
        swap(a.pImpl,b.pImpl);
    }
}
```

特化版本的swap算法只对Widget类生效，它交换了Widget对象的之间，避免了整个Widget类的赋值和构造，极大提升了效率。

> 这里有一点要注意：通常我们是不允许改变std命名空间内的任何东西，但允许为标准的template(如swap)创建特例化版本。

当我们运行上面那个函数的时候，发现它竟然不能通过编译！因为Widget对象的pImpl成员是私有的，不能直接交换它们。  
我们有两个解决方法：  

1. 将特例化版本声明为类的友元
2. 在类在实现一个swap，然后特例化版本调用类的swap函数

第二个方法的实现如下所示：  
```c++
//  Widget类中声明一个swap方法
class Widget{
public:
    ...
    void swap(Widget& other){
        using std::swap;    //  这个声明很有必要，在下面做解释
        swap(pImpl, other.pImpl);  //  交换指针
    }
};
//  特例化版本调用类中的swap方法
namespace std{
    template<>
    void swap<Widget>(Widget& a, Widget& b){
        a.swap(b);
    }
}
```

第二个方法的好处：
1. 不但保证了程序能够通过编译
2. 与STL容器保持一致性，即我们可以采用a.swap(b)的写法，也可以采用swap(a,b)的写法

# Widget模板版本
Widget可以设计为一个模板，而不单纯是一个类，这样我们可以模板化Widget中的数据类型。
我们将Widget声明为模板：  
```c++
template <typename T> class WidgetImpl { ... };
template <typename T> class Widget { ... };
```

然后我们修改对应的swap函数，使它能调用Widget模板：  
```c++
namespace std{
    template<typename T>
    void swap<Widget<T>>(Widget<T>& a, Widget<T>& b){
        a.swap(b);
    }
}
```

但是当我们写完代码，发现它又不能通过编译了！  
我们探究原因，发现函数模板原本的写法:  
```c++
template<typename T> void swap(T& a, T& b);
```

然后我们想将参数类型T特例化为Widget\<T>类型。于是变成这样：  
```c++
template<typename T> void swap<Widget<T>>(Widget<T>& a, Widget<T>& b);
```

这种写法叫偏特例化(partially specialize)，将参数类型T特例化为某个子类型Widget\<T>。但是C++只允许对类模板偏特例化，不允许对函数模板偏特例化。所以这段代码不能通过。

既然不能偏特化，那我们只能重载一个函数来处理参数类型为Widget/<T>的调用。因为Widget/<T>类型相比类型T更加特例化，根据模板重载的匹配规则，会优先选择模板参数类型为Widget/<T>的那个版本。  
函数模板重载实现如下：  
```c++
namespace std{
    template<typename T>
    void swap(Widget<T>& a, Widget<T>& b){  //  swap后面没有<...>
        a.swap(b);
    }
}
```

当我们觉得万无一失了，发现还是编译不过。  
原来std是个特殊的命名空间，不允许我们添加任何东西，即不能添加新的template。这是因为std的内容由C++委员会决定，标准委员会禁止我们添加已经声明好的东西。  

<br>

既然不能添加到std命名空间中，我们就添加到自定义的命名空间中。当遇到Widget\<T>类型的对象想调用swap函数，只要想办法让它调用我们自己的命名空间中的那个版本就好了。  
首先我们先在自定义命名空间中，定义这个重载函数：  
```c++
namespace WidgetStuff{
    ...
    template <typename T> class Widget { ... };
    ...
    template <typename T>   //  这里不属于std命名空间
    void swap(Widget<T>& a, Widget<T&> b){
        a.swap(b);
    }
}
```

现在只剩最后一个问题了，如果遇到Widget\<T>类型的对象想调用swap函数，我们怎么让它选择正确的版本呢？  
所幸，C++的名称查找法则（argument-dependent lookup）帮助我们解决这个问题。   
+ ADL会先查找Widget所在的命名空间内是否有专属的swap函数
+ 如果没有，则编译器会使用std命名空间中特例化的swap函数
+ 如果没有对应的特例化版本，最后编译器会选择std命名空间中的通用版本

这里有两点需要注意：  

1. 以下调用方式是错误的：  

```c++
std::swap(obj1,obj2);   //  会强制调用std中的swap版本（包括特例化版本和通用版本）
```

2. 如果没有声明使用std的命名空间，即using namespace std，要加上using std::swap语句。
```c++
//  using namespace std;    //  如果没有这句声明
using std::swap;    //  这个必须加上
swap(obj1,obj2);
```

如果没有加上using std::swap语句，编译器会在WidgetStuff命名空间中查找swap函数，而不是在std命名空间中查找。如果WidgetStuff命名空间中的swap函数不符合要求，则会出现错误。所以using std::swap语句的作用是令std命名空间中的swap方法在当前作用域生效。

## 总结
> + 如果我们提供了一个member swap，也应该提供一个non-member swap来调用前者，对于class，我们还应该特化std::swap
> + 调用swap时应该使用using声明式，即using std::swap
> + 不要在std命名空间中添加任何新的东西

# Reference
[1] <<Effective C++>>  
[2] <<C++ Primer>>  