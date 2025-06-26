---
title: 读书笔记 —— Effective C++(1)
authors: fanventory
date: 2022-11-30 10:53:00 +0800
categories: [Reading Notes,Effective C++]
tags: [C++, Reading Notes]
---

> 我们建议程序编写中用const代替#define定义常量，用inline函数代替#define宏定义函数，并讨论了这样做的必要性。最后再介绍了const修饰成员函数，说明了const修饰在成员函数上的含义，并为相同的const函数重载提出一个去除重复的解决方案。

<br>
<br>

# 用const代替#define定义常量
## 建议
我们平时定义一个常量可能会采取这样的方式：
```c++
#define Pi 3.14
```
书中建议我们应该采取这样的写法
```c++
const double Pi 3.14;
```
我们通过两者之间的区别来给出理由。
1. #define，宏定义，是一条预编译指令。编译器会在预编译阶段将它从移出并替换为指定内容，这意味着Pi不会进入记号表(symbol table)，而被单纯的替换、移走。而const则会在编译运行阶段进行编译。    
采用#define定义常量容易导致编译时引起意想不到的结果，例如你获得一个报错消息，但这个消息提到了3.14而不是Pi。更甚的是，这个宏被你定义在某个头文件，甚至你不知道3.14从何而来，从而花费时间去追踪。  
所以我们给出的第一个理由是，采用const定义常量更容易在编译过程中追踪报错内容。 
  
2. #define定义的常量在程序中会替代为立即数，每一个立即数都会在寄存器中有一份拷贝。而const定义的变量在内存中分配一个寄存器，使用时只引用这一份拷贝。  
这就导致了#define定义常量的做法产生了多个3.14，而改为const定义常量则不会出现这种情况。  
所以我们给出的第二个理由是，采用const定义常量更有益于提高空间利用率，在一些长字符串常量的情况下，提升效果会更加明显。
  
3. #define的作用域是从#define开始到#undef（如果没有#undef那就是到文件末尾）。而const定义的变量根据定义所在的位置有明确的作用域。  
试想一个场景，当我们需要创建一个class的类内变量时，#define无法做到。它不能实现只在类内替换，也不能支持任何封装性，也就是说没有所谓的private #define这种用法，而const定义类内变量没有任何问题。  
所以我们给出的第三个理由是，采用const定义常量作用域更明确，更支持类语法，且不会造成命名污染。

4. #define定义的常量不需要指定类型，也不会做类型检查。而const定义常量需要指定类型，而且在编译阶段会做类型检查。
#define中被替换的常数可能在程序运行过程中出现类型错误，产生bug。
所以我们给出的第四个理由是，采用const定义常量作用域更能保证类型安全。

## 一些特殊情况
1. 常量指针和指针常量
> 常量指针：   

+ 定义：指针是变量，而指向的地址是常量，而地址所指的值是变量。常量指针指向的对象不能通过这个指针来修改，但可以通过原来的声明修改（见下面例子）。  
+ 表示形式：
```c++
int const* p1;  
const int* p1;
```
+ 例子:
```c++
const int *p1 = &a; a = 200; // OK,可以通过原来的声明修改
*p1 = 13; // Error,*p1是const int的，常量指针不可修改其指向地址
p1 = &b; // OK,指针还可以指向别处，因为指针只是个变量
```

> 指针常量：  

+ 定义：指针是常量，而指向的地址是变量，而地址所指的值也是变量。指针指向的值不可以改变，然而指针所指向的地址的值可以修改（见下面例子）。  
+ 表示形式：
```c++
int* const p1;
```
+ 例子:
```c++
int* const p2 = &a; a = 200; // OK,可以通过原来的声明修改
*p2 = 900; // OK,指针是常量,但是指向的地址所对应的值是变量，可以修改
p2 = &b; // Error,因为p2是const*指针，因此不能改变p2指向的地址
```
> 补充：

+ 如果需要在头文件中，定义一些指向常量的常量指针，需要加两次const（如下）
```c++
const int* const p3 = &a;
const char* const name="Fanventory";
```
+ 当然，更好的写法是使用string对象（如下）
```c++
const std::string name("Fanventory");
```

2. 定义class类内常量  
如果需要在class类内声明一个常量，，由于常量的作用域限制在class内，必须确保该常量至多只有一份实体，也就是说我们必须声明为static。
```c++
class GamePlayer{
private:
    static const int NumTurns=5;
    int scores[NumTurns];
};
```

3. class类内常量完成in-class初值设定  
在某些旧式编译器中，class中如果存在数组，编译期间必须得知道数组大小，上述的`scores[NumTurns];`可能会报错。我们可以采用`“the enum hack”`的补偿做法。具体实现如下：
```c++
class GamePlayer{
private:
    enum { NumTurns=5 }; // 令NumTurns成为一个记号名称
    int scores[NumTurns];
};
```

> enum与const也有区别，const常量的地址是合法的，而取enum的地址是不合法的，也如取#define定义的常量地址也是不合法的。  

## 总结
> + const定义的常量更容易在编译过程中追踪报错内容。
> + const定义的常量空间利用率更高。
> + const定义的常量作用域更明确，更支持类语法，且不会造成命名污染。
> + const定义的常量更能保证类型安全。

# 用inline函数代替#define宏定义函数
## 建议
我们在平时写代码时，可能会遇到以下的写法：
```c++
#define CALL_WITH_MAX(a,b) f((a) > (b) ? (a) : (b))
```

这种宏(macros)看起来像是函数，且不会由于函数调用而带来额外开销。但它也有很多缺点，比如以下场景：
```c++
int a=5,b=0;
CALL_WITH_MAX(++a,b); // 累加了一次
CALL_WITH_MAX(++a,b+10); // 累加了两次
```

后一次调用累加了两次，这明显是不对的。那有没有方法既能享受类似宏带来的效率，又能使函数的行为可预料，且参数类型能够安全检查呢？我们可以使用template inline函数：
```c++
template<typename T>
inline void CALL_WITH_MAX(const T& a, const T& b){
    f(a > b ? a : b);
}
```

该方法定义的CALL_WITH_MAX是一个真正的函数，遵守作用域和访问规则。甚至可以写出一个类内的private inline函数，而#define却无法完成此事。当然，#define的需求依然存在，但为了程序的安全性和正确性，我们应该更谨慎地使用他们。
## 总结  
> + 对于形似函数的宏，最好改用inline函数代替。

# cosnt成员函数
const可以作用在类内的成员函数上，这样做有两个好处：
1. 清楚地知道哪个函数可以改动对象内容，而哪个函数不行
2. 如上面`用const代替#define定义常量`所说，以reference-to-const方式传参，可以提高编程效率
在展开说明const修饰成员函数之前，我们先提出一个冷知识：
> 两个成员函数如果只是常量性(constness)不同，它们是可以被重载的（例子如下）

```c++
class TextBlock{
public:
    ...
    const char& operator[] (std::size_t position) const // 重载
    { return text[position];}
    char& operator[] (std::size_t position) // 重载
    { return text[position];}
private:
    std::string text;
};
```

下面我们来运行这两个重载方法，并观察其区别
```c++
TextBlock tb("Hello");
const TextBlock ctb("world");
std::cout<<tb[0]; // ok，读non-const TextBlock
tb[0]='x'; // ok，写non-const TextBlock
std::cout<<ctb[0]; // ok，读const TextBlock
ctb[0]='x'; // no，写const TextBlock；重载方法的返回值用const修饰，并不可改
```

介绍这个冷知识，是为了接下来我们通过const成员函数和non-const成员函数的对比，来阐述const修饰成员函数的含义。
## const成员函数的含义
const修饰成员函数意味着什么？曾经有两种流行的概念：bitwise constness（或physical constness）和logical constness。
1. bitwise constness
根据const的定义，bitwise constness阵营的人认为，`成员函数只有在不改变对象中的任何成员变量时，才可以说是const`，即const成员函数不可以更改对象内任何non-static成员变量。  
这个概念简单易懂，但存在一些BUG。我们看下面的一个例子：
```c++
class CTextBlock{
public:
    ...
    char& operator[] (std::size_t position) const // bitwise声明
    { return text[position];}
private:
    char* pText;
};
```

这个函数并没有修改对象中的任何值，但它却返回了一个reference，指向对象的内部值。编译器认为它是bitwise constness的。但如果我们很快发现，通过返回的reference，我们可以修改类中的值：
```c++
const CTextBlock cctb("Hello");
char *pc=&cctb[0];
*pc='J'; // 此时cctb的内容变成了Jello
```

这显然是错误的，因为我们声明了一个const对象，又只调用const方法，但最终我们还是能改变它的值。  
基于这种情况，出现了另一派：logical constness。
2. logical constness
logical constness这一派认为，`一个const成员函数可以修改它所处理对象内的某些bits，但只有在客户端侦测不出的情况下才得如此`。我们举一个例子来说明：
```c++
class CTextBlock{
public:
    ...
    std::size_t length() const;
private:
    char* pText;
    std::size_t textLength; // 最近一次计算的文本块长度
    bool lengthIsValid; // 目前长度是否有效
};
std::size_t CTextBlock::length() const
{
    if(!lengthIsValid){
        textLength = std::strlen(pText);
        lengthIsValid = true;
    }
    return lengthIsValid;
}
```

这个例子中，我们修改了textLength和lengthIsValid的值，但客户端并不知情，对客户端可见的内容仍然是不可修改的。根据logical constness的定义，我们认为它是const的。  
但我们很快又发现，根据bitwise constness的观点，const成员函数内不能修改对象内non-static成员变量的值，而textLength和lengthIsValid却被修改了，这不符合bitwise constness，当然也通不过编译器。  
为了解决这个问题，我们给这两个变量添加`mutable`（可变的），释放bitwise constness的约束，这样问题就迎刃而解了。具体代码如下：
```c++
class CTextBlock{
public:
    ...
    std::size_t length() const;
private:
    char* pText;
    mutable std::size_t textLength; // 最近一次计算的文本块长度
    mutable bool lengthIsValid; // 目前长度是否有效
};
std::size_t CTextBlock::length() const
{
    if(!lengthIsValid){
        textLength = std::strlen(pText);
        lengthIsValid = true;
    }
    return lengthIsValid;
}
```

## 避免cosnt和non-const重载成员函数中的重复
现实需求中，我们重载[]操作符的方法可能更加复杂，可能会涉及到一些诸如边界检验（bound checking）、日志访问消息（logged access info）、数据完善性检验（verify data integrity）等功能。如果我们把这些代码都放入const和non-const的重载成员函数中，代码将会有很多的重复内容。这会使得代码臃肿，难以维护，还会增加编译时间。就像下面代码这样：
```c++
class TextBlock{
public:
    ...
    const char& operator[] (std::size_t position) const // 重载
    { 
        ...     // 边界检验
        ...     // 日志数据访问
        ...     // 检验数据完善性
        return text[position];
    }
    char& operator[] (std::size_t position) // 重载
    { 
        ...     // 边界检验
        ...     // 日志数据访问
        ...     // 检验数据完善性
        return text[position];
    }
private:
    std::string text;
};
```

为了解决这个问题，我们可以使用常量性转型（casting away constness）。
> 注意：我们需要谨慎对待转型，因为不安全的转型将会给程序带来错误。

我们的想法是这样的，首先实现const operator[]的方法。然后当我们需要non-const operator[]的方法时，将对象转化为const类型，然后调用const operator[]的方法，最后再消除返回值中const的约束。
> 注意：如果我们没有将对象转化为const类型，那它就会递归调用non-const operator[]的方法，直到系统栈崩溃。

我们实现的代码如下：
```c++
class TextBlock{
public:
    ...
    const char& operator[] (std::size_t position) const // 重载
    { 
        ...     // 边界检验
        ...     // 日志数据访问
        ...     // 检验数据完善性
        return text[position];
    }
    char& operator[] (std::size_t position) // 重载
    { 
        // const_cast<>(a)的作用是将a的值消除cosnt
        // static_cast<>(b)的作用是将b转换为某种类型
        // 通过*this完成对象调用自身的const operator[]方法
        return const_cast<char&>(
            static_cast<const TextBlock&>(*this)[position]
        );
    }
private:
    std::string text;
};
```

最后我们来探讨一个问题，在上述代码中我们实现了const operator[]的方法，然后在non-const operator[]的方法中调用它，那反过来行不行呢？  
答案是不行的！  
因为在const operator[]方法中调用non-const operator[]的方法，那我们就违反了const的定义——不能在const函数中改动non-static成员变量的值。而反过来，non-const operator[]方法没有这样的限制，所以调用一个const成员函数并没有什么风险。所以我们在这里强调，要谨慎使用转型，要保证我们的转型代码是安全的。  
## 总结
> + 编译器强制执行bitwise constness
> + const和non-const成员函数有相同的实现时，可以令non-const版本调用const版本来避免重复

# Reference
[1] <<Effective C++>>  
[2] [用const代替#define定义常量](https://blog.csdn.net/weixin_43866978/article/details/120903523)  
[3] [常量指针、指针常量的区别](https://blog.csdn.net/weixin_52011465/article/details/114446650)