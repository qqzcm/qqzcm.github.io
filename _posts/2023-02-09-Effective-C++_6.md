---
title: 读书笔记 —— Effective C++(6)
authors: fanventory
date: 2023-02-09 16:16:00 +0800
categories: [Reading Notes,Effective C++]
tags: [C++, Reading Notes]
---

> 本节我们把目光专注于设计。首先我们先讨论接口的设计，一个好的接口应该容易正确被使用，不易被误用，所以在接口的设计中我们需要避免用户造成各种各样的错误，最大程度地保证用户正确使用接口。接下来我们来讨论类的设计，针对类的设计我们提出了一些问题。当我们设计类的过程中，可以对着这些问题一一斟酌。

<br>
<br>

# 让接口容易正确被使用，不易被误用
程序中各种各样的接口，就比如c++中，我们有function接口，class接口，template接口等等。每一个接口的设计都需要细微谨慎，因为这些接口是我们与用户交互的渠道之一，我们总是希望用户能以正确的方式使用我们的接口，使程序能够正确运行。但是现实往往并不如人意，用户总能以各种方式错误使用接口，使程序出现各种各样的bug。所以接下来我们介绍一些编写接口过程中容易犯错的地方，并提出一些建议来完善接口设计。

1. 接口的参数顺序可能传递错误  

让我们先来看一个例子，我们需要设计一个日期类：  
```c++
class Date{
    public:
        Date(int month,int day,int year);
    ...
};
```

第一眼可能觉得这个接口没啥问题，我们想要生成一个日期类，只要传入相应的参数就可以了。比如圣诞节是今年12月25号，那对应代码是：  
```c++
Date d(12,25,2023);
```

但人是容易犯错的，万一用户忘记了接口参数的含义，以一个错误的顺序传入参数，看看会发生什么？  
```c++
Date d(25,12,2023); // 出现了25月份，很明显是错误的
```

为了防止用户遗忘接口参数的含义，我们可以`导入新类型`。就像下面这样：  
```c++
struct Month{
    explicit Month(int m):val(m){}
    int val;
};

struct Day{
    explicit Day(int d):val(d){}
    int val;
};

struct Year{
    explicit Year(int y):val(y){}
    int val;
};

class Date{
    public:
        Date(const Month& m,const Day& d,const Year& y);
    ...
};
```

这样用户在使用这个日期类的时候，需要这样子编写代码：  
```c++
Data d(12,25,2023);  //  错误，类型不正确
Data d(Day(25),Month(12),Year(2023));  //  错误，类型不正确
Data d(Month(12),Day(25),Year(2023));  //  ok，类型正确
```

当然，将Day，Month，Year封装成class，并进行加工完善，要比封装成struct更好。这里我们想说明引入新类型在很多场景中能避免错误，特别是这类参数顺序错误。  

2. 无效参数

继续看上面的例子，用户在输入时，可能手误按到了2旁边的3，结果输入了这么一个日期：  
```c++
Data d(Month(13),Day(25),Year(2023)); //  很明显是12月而不是13月
```

这个问题最好的解决方法就是约束对象的值，一个简单的方法就是在构造函数中加入判断语句，避免出现不合理的参数。不过这里我们还可以用另一种方法解决：就是用函数动态生成对象，从而达到限制输入值的目的，就像下面这样：  
```c++
class Month{
    public:
        static Month Jan() { return Month(1); }
        static Month Feb() { return Month(2); }
        ...
        static Month Dec() { return Month(12); }
    private:
        explicit Month(int m);  //  将构造函数私有，从而禁止生成新的月份
};
Data d(Month::Dec(), Day(30), Year(2023));
```

3. 接口不一致性  

在Java中，数组可以使用length属性获取长度，string也可以使用length类型获取长度，而对于List则要用size()方法获取长度；.NET中也引用，Arrays的长度属性是Length，而ArrayLists的长度属性则是count。这些接口的不一致性可能看起来没那么碍事，但这些不一致的地方多多少少会对开发人员和用户造成困扰和摩擦。所以我们设计接口的时候，最好要保持一致，不但接口内的相同属性保持一致，接口的前后版本之间也需要保持一致。

4. 用户遗漏某个操作

如果一个接口要求用户必须完成某个操作，则这个操作可能会忘记执行。我们举个例子来说明：  
现在我们有一个动态生成Investment对象的方法，为避免资源泄漏，要求我们在代码末尾将他delete掉：  
```c++
//  声明
Invectment* createInvestment();
//  使用
{
    Invectment* pInv=createInvestment();
    ...
    delete pInv;    //  接口要求及时delete掉资源，但用户可能忘记了
}
```

这种情况最好的解决方法是用到我们之前提到的智能指针。我们可以将对象值存储在shared_ptr中，然后返回shared_ptr<Invectment>类型，将delete的责任交给智能指针。
```c++
shared_ptr<Invectment> createInvestment();
```

这种做法也可以防止用户进行了多次delete。

5. 用户不正确删除

还是接着上面createInvestment()的例子，创建出来的对象有时候可能会提供一个接口（比如叫getRidOfInvestment）进行删除，但是用户却自作主张delete掉了，使系统造成不确定行为。比如我们用接口打开了一个数据库链接，但我们需要关闭时应该调用其close()方法，但用户却用了delete语句，造成了数据库连接一直存在，而没有被正确关闭。
```c++
Invectment* pInv=createInvestment();
...
delete pInv;    //  错误操作
getRidOfInvestment(pInv);   //  正确操作
```

这种情况下我们受到智能指针的启发，只要给智能指针传递一个删除器，就能让智能指针在代码区块的末尾自动调用我们规定的删除函数。所以我们的代码可以这样修改：  
```c++
shared_ptr<Invectment> createInvestment(){
    shared_ptr<Invectment> retVal(new Invectment(),getRidOfInvestment);
    return retVal;
}
```

同时，shared_ptr还有一个好处就是可以解决cross-DLL问题，这个问题指对象在动态链接库DLL中new出来，但是在另一个DLL中被delete掉，由于在第一个DLL中new出来的地址，在另一个DLL中并不是同一个地址块，就会造成系统不确定行为。但是如果我们使用了shared_ptr，new出来的对象就会追踪到原来的DLL中，然后在原来的DLL释放内存。

> 解决跨DLL问题最好的方法就是设置为虚函数，因为设置成虚函数之后，类中会保存一个虚函数指针，这个指针是指向调用方法的指针，这样该对象释放时，虚析构函数就会沿着该指针找到原来DLL的代码区域，完成释放操作。std::shared_ptr的源代码中处理delete的函数就是个虚函数。

## 总结
> + 好的接口应该被正确使用，不容易被误用
> + 防止接口误用有建立新类型，约束对象值，保持接口一致性，消除客户的资源管理责任等方法
> + shared_ptr可以防范跨DLL问题

# class设计
类的设计是一个很重要的话题，一个好的类应该语法直观，实现高效。所以在类的设计中，我们提出以下一些问题，这些问题将协助你完成类的设计。当我们在设计类时，围绕着这些问题细细思索，就能避免生成一些不良的类。

`1. 对象应该如何被创建和销毁？`

设计类的构造函数、析构函数以及内存分配函数和释放函数至关重要。

`2. 类的初始化和赋值应该有什么差别？`

类的初始化和赋值是不同的，所以设计过程中构造函数的正确实现可以使类更高效。

`3. 类的合法值`

类的成员函数、成员变量可能涉及一些约束条件。

`4. 继承的类是否需要配合？`

如果类继承了某些类，这些类中可能存在一些约束，也可能存在一些虚函数，这些都是你要遵守且配合的。

`5. 类的转换问题`

生成的类可能会面临一些隐式转换，则需要我们重载操作符函数。亦或者这个类不能隐式转换，那我们需要手动编写显式转换函数，同时禁用类型转换操作符和某些构造函数。

`6. 操作符和函数类型是否合理？`

生成的类需要声明哪些函数，其他哪些是menber函数，哪些是普通函数。

`7. 成员变量的选取`

成员变量哪个是public，哪些是private？同时还要考虑成员变量中存在class或friend的情况。

`8. 类是否有一般性？`

有时候可能因为针对类型的不同，生成了一组类，这时候你应该生成class template而不是定义一个新类。

`9. 新类的必要性`

新类是为了在此基础上加上一些新的功能的话，那是否有生成的必要？是修改原有类更好呢？还是增加新类更好呢？

## 总结
> + 类的设计至关重要，这些问题将协助你完成类的设计

# 参数设计
我们知道函数参数分为实参和形参，在我们传入参数时，程序开辟新的内存空间，复制新参，生成一个新的临时副本在函数体内进行运算。有时候这个复制的过程可能会造成巨大的成本花销，就像下面这个例子：  
```c++
// Person类
class Person{
    public:
        Person();
        virtual ~Person();
        ...
    private:
        string name;
        string address;
};

// 继承Person类的Student类
class Student{
    public:
        Student();
        ~Student();
        ...
    private:
        string schoolName;
        string schoolAddress;
};

// 现在我们定义一个简单的函数，并将Student对象作为参数传入函数中
bool validateStudent(Student s); // 验证学生身份函数
Student plato;
validateStudent(plato);
```

当validateStudent(plato);被调用时，我们来看看发生了什么？  
+ 首先，Student的构造函数会被调用
+ 接着，Student类中有两个string类型的成员变量，所以会调用两次string类的构造函数
+ 其次，由于Student类继承了Person类，所以Person类的构造函数也会被调用
+ 最后，Person类中也有两个string类型的成员变量，也调用了两次string类的构造函数

所以最后一次调用函数，导致程序调用了一次Student构造函数，一次Person构造函数，四次string构造函数。而当我们函数返回的时候，需要调用对应次数的析构函数。如果我们的类更大，成员变量更多，一次传参的成本是相当大的。  
为了解决这个问题，我们想到了C++中的引用（reference）。我们把validateStudent函数修改成这样：  
```c++
bool validateStudent(const Student &s); // 这里const是为了禁止修改Student对象的内容
```

这样传递的方式效率会高很多，因为程序没有调用过一次构造函数和析构函数。  

<br>

接下来我们讨论引用传参中的三个细节：  
1. 引用传参是否一定比传值传参要好？

答案肯定是不一定。首先先引用是以指针来实现的，当我们传入参数是一些内置类型（比如int），用传值传参会更加高效（节省了寻址时间）。其次，STL的迭代器以及函数对象，传值传参也比引用传参要高效，因为习惯上他们都被设计成以值来传参。  

<br>

2. 这时候又有人问了，采用引用传参是因为成本低，那占用空间比较小的类或结构体我是不是用传值传参就好了？  

答案也是否定的。有三点理由：  
+ 第一，类的成员变量小不代表构造函数的代价小。许多对象看起来内含的东西不多，只有一些指针，但复制他们却要复制对象内指针所指的每一样东西（包括大多数STL容器）。
+ 第二，某些编译器对内置类型和用户自定义类型的态度不同，纵使他们底层是一样的。比如某些编译器会把double类型放入缓存器中，但如果某个类也是只有一个double变量，它却拒绝放入缓存器中。反过来如果我们用引用的方式，编译器一定会把对应指针放入缓存器中，加快读取速度。
+ 第三，作为一个用户自定义类型，大小是可以变化的。一个类虽然目前不大，但以后内部实现可能发生改变。比如某些标准库的string类型比其他版本大7倍。

3. 传值传参可能会引起切割问题

首先我们来解释一下什么是切割问题（slicing problem）?我们的派生类传入函数，而函数参数定义是基类时，只有基类的构造函数被调用，也就是说对象在函数中不会表现派生类的特性。
下面我们举一个例子来说明：  
我们有一个窗口系统，用来在屏幕上显示窗口。
```c++
// 基类
class Window{
    public:
        ...
        string name() const;  //  返回窗口名称
        virtual void display() const;  //  显示窗口及内容
};

// 派生类
class WindowWithScrollBars:public Window{
    public:
        ...
        virtual void display() const;  //  显示高级的条形窗口
};
```

接下来我们编写一个函数用来打印窗口名字，并显示窗口：  
```c++
void printNameAndDisplay(Window w){
    cout<<w.name()<<endl;
    w.display();
}
```

接着我们调用这个函数：  
```c++
WindowWithScrollBars wwsb;
printNameAndDisplay(wwsb);
```

结果这个对象被复制成一个基类对象Window，它显示的原始的Window窗口，而不是继承后华丽高级的条形窗口。也就是说，函数内调用的是Window::name和Window::display。

<br>

当我们修改一下函数，改用引用传值后，这个问题就能迎刃而解了。我们传进来的窗口是什么类型，对应的参数w就会表现成什么类型。
```c++
void printNameAndDisplay(const Window& w){
    cout<<w.name()<<endl;
    w.display();
}
```

## 总结
> + 尽量用引用传参代替传值传参，因为前者更高效，还可以避免切割问题
> + 对于内置类型，STL的迭代器和函数对象，传值传参更加高效

# 设计返回值
阅读了上面的内容，你可能会想那返回值是不是也能改成引用了。我们知道返回值在返回的时候，也是生成一个副本，然后函数内的变量会被销毁。根据这个思想，我们来设计出这么一个函数：  
```c++
// 这个函数的功能是两个有理数相乘
const Rational& operator*(const Rational& lhs,const Rational& rhs)
{
    Rational result(lhs.n*rhs.n,lhs.d*rhs.d);
    return result;
}
```

当我们运行的时候会发现result是一个local变量，它会在函数末尾销毁，返回了一个指向销毁内存的引用，如果我们使用返回值，就会陷入无定义行为。  

<br>

这时候你可能觉得有什么不对，只要result不自动销毁不就好了嘛，于是你修改了一下函数：  
```c++
const Rational& operator*(const Rational& lhs,const Rational& rhs)
{
    Rational *result=new Rational(lhs.n*rhs.n,lhs.d*rhs.d);
    return *result;
}
```

新的函数确实不会像第一版一样变成一个无定义指针了，但又产生了一个新的问题：既然不会自动销毁，那谁来delete掉呢？且不说delete是一件容易忘记的事情，如果我们把代码写出下面这样：  
```c++
Rational w,x,y,z;
w=x*y*z;
```

你会发现上面的操作符相对于operator*(operator*(x,y),z)。x和y运算产生的返回值指针丢失了，这意味着你永远无法delete掉，导致内存泄漏。

<br>

可能你感觉还是不对，那我把local变量变成全局变量呢，这样也能避免被自动销毁？于是突发奇想把函数修改成下面这样：  
```c++
const Rational& operator*(const Rational& lhs,const Rational& rhs)
{
    static Rational result;
    result=...;
    return result;
}
```

当我们运行的时候，好像没什么问题。但运行到下面这行代码的时候，又出现错误了：  
```c++
// 这个函数的功能是判断两个Rational对象是否值相等
bool operator==(const Rational& lhs,const Rational& rhs);
Rational a,b,c,d;
...
if((a*b)==(c*d)){
    ...
}else{
    ...
}
```

你会发现无论a,b,c,d的值是多少，`(a*b)==(c*d)`总是返回true。这是因为(a*b)返回的是静态变量result，(c*d)返回的也是静态变量result，它们返回的是同一个东西，所以总是返回true。  

<br>

接下来你可能还是想对这个方法打补丁，用一个static列表代替呢？  
但打完补丁，新的问题就会随之而来。
+ 列表的大小n怎么选择呢？n太大，则这些列表的初始化需要花费代价，降低程序效率。n太小，又会回到单个static设计面临的问题。
+ 对象在这些列表中赋值需要调用一次析构函数（销毁旧值），再调用一次构造函数（复制新值）。和我们用值返回并没有区别，反而花费了构造列表的成本。

<br>

所以并没有什么捷径，设计返回值最好的写法就是返回一个新的对象。长远来看我们付出了小小的代价，但我们保证了代码的正确性。所以正确的写法应该是这样的：  
```c++
const Rational operator*(const Rational& lhs,const Rational& rhs)
{
    return Rational(lhs.n*rhs.n,lhs.d*rhs.d);
}
```

## 总结
> + 函数返回值时，正确的写法是返回一个新的对象，而不是引用

# Reference
[1] <<Effective C++>>  
[2] <<C++ Primer>>  
[3] [跨DLL的内存分配释放问题 Heap corruption](https://blog.csdn.net/zj510/article/details/35290505)  