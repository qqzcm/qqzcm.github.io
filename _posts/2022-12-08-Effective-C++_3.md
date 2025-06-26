---
title: 读书笔记 —— Effective C++(3)
authors: fanventory
date: 2022-12-08 19:43:00 +0800
categories: [Reading Notes,Effective C++]
tags: [C++, Reading Notes]
---

> 这一节重点探讨构造函数、析构函数、以及赋值操作函数，他们与类的生命周期有关，其中有很多细节值得我们去思考。我们知道在类中如果没有显示声明构造函数、析构函数、copy构造函数、赋值重载函数，编译器则会自动生成这些函数。这些自动生成的函数在某些特殊情况下可能会出错。同时在某些特殊情况下，我们要拒绝自动生成这些函数（或者说让这些函数调用时失效）。当然自己显式定义这些函数是一个好的方法，但是有更方便的方法吗？当我们声明基类时，构造、析构函数往往要声明virtual。virtual析构函数有一些比较有意思的用法。最后当析构函数出现异常时，我们应该吞下或者直接中止，同时把异常的处理交给程序员而不是由析构函数抛出。最后，我们要注意不要在构造、析构函数内调用virtual函数，因为你调用的不是派生类的版本。

<br>
<br>

# 自动生成构造/析构/赋值函数
C++中如果我们没有声明和定义构造函数、析构函数、copy构造函数、赋值重载函数，则编译器会为我们自动生成这些函数。  
例如我们实现一个空类：
```c++
class empty{ };
```

经过编译器编译后，会自动生成构造函数、析构函数、copy构造函数、赋值重载函数，就像下面这样：
```c++
class empty{
public:
    empty() {}
    empty(const empty &rhs) {...}
    ~empty() {}
    empty& operator=(const empty &rhs) {...}
};
```

这些知识相信大家都十分了解，我们接下来讨论一些细节：  
1. 如果我们自定义了构造/析构/赋值函数，那编译器就不会自动生成已有的那个函数。
2. 如果成员变量是引用或者const修饰，则编译器拒绝编译赋值动作。  

第1点相信大家再熟悉不过了。  
针对第2点，我们先来看下面一段代码：  
```c++
template<class T>
class Object{
public:
    Object(std::string &name,cosnt T& value);
private:
    std::string &name;
    const T value;
};
```

考虑下面一段代码：  
```c++
std::string newDog("peter");
std::string oldDog("satch");
Object<int> P(newDog,2); // 一只叫peter的小狗，岁数为2
Object<int> S(oldDog,1); // 一只叫satch的小狗，岁数为1

P=S;    //  现在p变量会发生什么呢？
```

我们假设赋值成功，对象P和S的成员变量name指向同一个引用，那修改P对象的name值也会影响S对象的name值。  
但这就不对了呀，S只是赋值给P，并不是P引用S。而且C++不允许，让声明的reference引用指向不同的对象。  

<br>

同样，对于const的成员变量，赋值操作会修改成员变量的值，更改const变量同样是不合法的。

<br>

最后还有一种情况，如果某个基类将赋值操作函数定义为private，然后用派生类去继承它。编译器会拒绝自动生成一个赋值操作函数。这是因为当派生类的赋值操作需要调用基类的赋值操作函数，而基类的赋值操作是private，派生类并没有权限，所以编译器只能作罢。

> 以上三种情况，会导致编译器拒绝自动生成构造/析构/赋值函数。

## 总结
> + 编译器会在类缺省的情况下，自动生成构造/析构/赋值函数，但某些特殊情况例外

# 拒绝自动生成构造/析构/赋值函数
我们假设一个场景，我们需要定义一个类来表示狗，但是按照现实逻辑，没有两条一模一样的狗，就好比如没有两个一模一样的人。按照这个逻辑，这个类并不能具备拷贝构造函数和赋值操作函数。  
代码逻辑如下：  
```c++
std::string newDog("peter");
std::string oldDog("satch");
Object<int> P(newDog,2); // 一只叫peter的小狗，岁数为2
Object<int> S(oldDog,1); // 一只叫satch的小狗，岁数为1

Object<int> R(P); // No，peter狗是唯一的
P=S;  // No，peter和satch是两条不一样的狗
```

你可能会想，我们修改这两个函数的定义为空不就好了。但是这样做，编译可以通过，但在程序运行时会报错，这是我们不希望发生的，我们希望在编译阶段就发现错误，这是不能赋值的！  
为了解决这个问题，我们提出几种方法：
1. 我们发现编译器产出的函数都是public，那意味着我们只要把拷贝构造函数和赋值操作函数声明为private，就可以在程序编译`P=S；`时报错。  

但是这个做法不是绝对安全的，因为member函数和friend函数也可以调用private函数。

2. 针对这个点，我们发现只要声明函数而不去定义，那在编译器的连接阶段，`P=S；`这样的语句就会抛出连接错误。这样就可以解决member函数和friend函数调用问题。

```c++
template<class T>
class Object{
public:
    Object(std::string &name,cosnt T& value);
private:
    std::string &name;
    const T value;
    Object(const Object&); // 这里参数名是可以省略的，因为我们并不需要使用它
    Object& operator=(const Object&);
};
```

3. 我们注意到上面讲到有一种情况下也会阻止编译器自动生成函数，那就是基类定义了构造/析构/赋值函数，且类型为private的时候。基于这个思路，只要我们定义一个uncopyable类，然后继承它，就能解决问题了。  
代码逻辑如下：  
```c++
class uncopyable{
protected:
    uncopyable() { }
    ~uncopyable() { }
private:
    uncopyable(const uncopyable&);
    uncopyable& operator=(const uncopyable&);
};
//  继承uncopyable类
class Object: private uncopyable{
    ...
};
```

> Boost也提供了类似的版本，名为noncopyable。

## 总结  
> + 如果要阻止编译器生成构造/析构/赋值函数，可以采用声明为private类型，且不定义，或者继承uncopyable类的方法。

# 多态基类声明为virtual析构函数
我们知道C++中存在多态，可以让我们通过基类指针指向派生类，从而实现工厂模式。  
代码逻辑如下：
```c++
class TimeKeeper{
public:
    TimeKeeper();
    ~TimeKeeper();
};
class AtomicClock: public TimeKeeper {...}; //  原子钟
class WaterClock: public TimeKeeper {...}; //  水钟
class WristWatch: public TimeKeeper {...}; //  腕表
//  通过base class指针，指向derived class对象
TimeKeeper *ptk=getTimeKeeper();    //  动态分配对象，可以是原子钟、水钟或者腕表
... //  运用钟
delete ptk; //  释放资源
```

但上面代码存在一个错误，基类没有声明virtual析构函数，导致我们执行`delete ptk;`时，base部分被释放了，但derived部分没有被销毁，从而造成资源泄漏。  

<br>

所以我们需要在base class中将析构函数声明为virtual。此时它会销毁整个对象，而不是base的局部部分。  
代码修改如下：  
```c++
virtual ~TimeKeeper();
```

## 构造函数为什么不能是virtual函数？  
因为virtual函数的执行依赖于virtual函数表，而virtual函数表的初始化是在构造函数中完成，所以构造函数无法声明为virtual函数。也就是说，构造函数中构造出virtual函数表，然后类中各个virtual成员函数根据virtual函数表执行。先有构造函数，再有virtual函数表。  

## 为什么默认的析构函数不是virtual函数？
回答这个问题前，首先思考一下，所有析构函数都需要声明为virtual吗？  
我们先看一个例子：  
```c++
class Point{
public:
    Point(int xCoord,int yCoord);
    ~Point();
private:
    int x,y;
};
```

这是一个二维空间坐标点类，它有两个成员变量（x和y），而一个int型变量占32bits，所以一个Point对象应该占64bits。在一些跨语言应用中，还可以当初64-bit量传递给其他语言，比如C语言。  
但是如果声明为virtual成员函数，则对象必须携带某些信息，用来执行运行期间该virtual函数调用哪一个版本。这些信息通常由vptr（virtual table pointer）指针指出。vptr指向一个函数指针数组，称为vtbl（virtual table）；每一个类都有一个对应的vtbl。当对象调用某一个virtual函数时，实际被调用的函数取决于该对象的vptr指针所指的vtbl。  
简单来说，如果Point class含有virtual函数，则它的存储空间不止64bits。因为一个指针也是32bits，所以为Point增加一个vptr会使存储空间中间50%~100%。  
造成的结果是，Point对象不能一次塞入64-bits的寄存器，也不能传递给其他语言（因为其他语言很可能没有vtpr结构）。  
所以，某些情况下不声明为virtual函数是不对的，而某些情况下无端端声明为virtual函数也是不对的。我们建议是，针对第一种情况，当class中至少存在一个virtual函数时，才为它声明virtual析构函数；针对第二种情况，如果该类不作为base class使用时，不应该声明为virtual函数。  

<br>

所以回到上面的问题，为什么默认的析构函数不是virtual函数？  
因为virtual函数指针和virtual函数表时需要消耗空间，而在类程序中又不一定被继承，所以默认的析构函数不是虚函数。

<br>

> 类的空间存储：  
> + 空的类是会占用类内存空间的，而且大小是1，原因是C++要求每个实例在内存中都有独一无二的地址。
> + 类的普通成员变量占用类内存空间，并且遵守字节对齐原则。
> + 类的static静态变量不占用类内存空间，原因是编译器将其放在全局变量区。
> + 类的普通成员函数不占用类内存空间。
> + 类的虚函数占用4个字节（32位系统）或8个字节（64位系统），用来指定虚函数的虚拟函数表的入口地址。一个类的虚函数指针是不变的，和虚函数的个数以及基类是否有虚函数没有关系的。
> + C++编译系统中，数据和函数是分开存放的(函数放在代码区；数据主要放在栈区和堆区，少数放在静态/全局区以及文字常量区)，实例化不同对象时，只给数据分配空间，而函数不占用类内存空间（包括友元函数、内联函数）。

## 总结
> + 如果该类不作为base class使用时，不应该声明为virtual函数
> + 当class中至少存在一个virtual函数时，才为它声明virtual析构函数

# 纯虚析构函数
拥有纯虚（pure virtual）函数的类，为抽象类。抽象类不能实例化对象。抽象类的子类会自动继承该纯虚函数，如果子类中任然没有实现该方法，那么该子类任然为纯虚函数。  
声明代码如下：  
```c++  
//声明格式：virtual 函数类型 函数名（ 参数列表 ） =0; 可以没有函数体的实现
virtual int fun(int n,int m)=0;
```

如果我们想将类声明为抽象类，但手上没有纯虚函数，此时我们可以将析构函数声明为纯虚函数。  
代码逻辑如下：
```c++
class AWOV{
public:
    virtual ~AWOV() = 0 ;
};
AWOV::~AWOV() { }   //  当然，你必须为纯虚析构函数提供一份定义
```

最外层的派生类会先调用析构函数，然后逐级调用析构函数，一直到里层的基类析构函数。编译器会在派生类的析构函数中创建一个对基类调用析构函数的动作。所以这里必须为纯虚析构函数提供一份定义，否则AWOV找不到对应的析构函数定义，连接器会报错。

## 总结
> + 如果想将类声明为抽象类，但成员函数没有纯虚函数时，可以将析构函数声明为纯虚函数，但是需要为纯虚析构函数提供一份定义

# 析构函数异常
假设一个场景，我们有以下的类。
```c++
class Widget{
public:
    ...
    ~Widget() {...} //  假设可能会产生异常
};
void doSomething(){
    std::vector<Widget> v;
    ...
}   //  程序运行到此处，v应该被自动销毁
```

我们现在执行`doSomething`函数，假设在执行过程中发生了异常，那系统要调用析构函数释放资源。  
但是这个时候，如果`Widget`析构函数也出现了异常。就会导致一个问题，前一个异常还没有处理完成，析构函数中的异常将怎么处理呢？  
对于C++而言，两个同时存在异常太多了，程序会不知道怎么处理它们。前一个异常的处理，需要析构函数释放资源；但是现在析构函数也异常了，如果抛出的话，上一层栈也是异常状态。那该怎么办呢？总的来说，它们会导致程序出现不明确的行为，或者导致程序过早结束。  

## 建议
C++中，析构函数不要抛出异常，因为容易导致程序过早结束或出现不明确行为。  

## 现实例子
我们现在封装一个数据库操作类，由于打开数据库后，需要及时`close`掉数据库连接，否则会导致不必要的资源浪费（连接持续存在，但是我们已经不用了）。为了方便，我们可以将close方法写在数据库操作类的析构函数中。  
代码逻辑如下：  
```c++
class DBConn{
public:
    ...
    ~DBConn(){
        db.close();
    }
private:
    DBConnnection db;
};
```

客户使用该类的时候，代码逻辑如下：
```c++
{   //  在某个代码块内调用数据库
    DBConn dbc(DBConnnection.create());
    ...
}   //  区块结束时，DBConn对象会自动调用析构函数，执行clase()方法
```

## 解决方法
根据上面数据库的例子，我们给出两个解决方法：
1. 结束程序  
如果析构函数抛出异常，既然这个对象后面不会再使用了，那我们就结束掉程序（因为当前对象或变量正在注销，意味着它们不会在后面的代码出现，也就是不会对后面的行为产生影响），阻止异常从析构函数中传播出去，防止程序出现不明确行为。  
代码逻辑如下：
```c++
DBConn::~DBConn{
    try{
        db.close();
    }catch (...){
        ... //  记录错误情况
        std::abort();   //  调用abort方法结束程序
    }
}
```

2. 吞下异常  
吞下异常是指记录下异常情况（必要的日志输出），然后忽略该异常，让异常不再向上传播。虽然一般而言吞下异常是个坏主意，但是比起程序过早结束和出现不明确行为，吞下异常让程序继续清理内存，防止内存泄漏。  
代码逻辑如下：
```c++
DBConn::~DBConn{
    try{
        db.close();
    }catch (...){
        ... //  记录错误情况
    }
}
```

3. 让客户处理  
以上两个方法都无法对异常做出反应，最好的方法还是让客户自己处理异常，而把上面两种方法作为第二重保险（如果处理不了该异常，则结束或者吞下它）。  
代码逻辑如下：

```c++ 
class DBConn{
public:
    ...
    void close(){   //  自定义函数，处理各种可能的情况
        //  这里可以在数据库关闭前做各种检查，并执行对应措施，预防出现异常的情况出现
        ...
        db.close();
        closed = true;
    }
    ~DBConn(){
        if(!closed){    //  追踪关闭状态，防止客户忘记调用close方法
            try{
                db.close();
            }catch (...){
                ... //  记录错误情况
                ... //  结束或吞下异常
            }
        }
    }
private:
    DBConnnection db;
    bool closed;
};
```

## 总结
> + 析构函数中不要抛出异常，因为可能导致程序过早结束或出现不明确行为
> + 提供一个普通函数（并非在析构函数中）对异常做出处理，而析构函数中出现异常应该直接结束程序或者吞下异常

# 不要在构造/析构函数中调用virtual函数
我们先看一个例子，假设我们有有个股票交易类，该类表示每一笔交易，当交易创建的时候需要写入日志进行审计。  
代码逻辑如下：
```c++
class Transaction{
public:
    Transaction();
    virtual void logTransaction() cosnt = 0 ; //  日志记录
};
Transaction::Transaction(){
    ...
    logTransaction();
}
```

当然，交易类型可能有多种，对于不同的交易类型，需要记录的信息也有所差别。  
代码逻辑如下：  
```c++
Class BuyTransaction: public Transaction{
public:
    virtual void logTransaction() const;    //  买入交易记录
    ...
}
Class SellTransaction: public Transaction{
public:
    virtual void logTransaction() const;    //  卖出交易记录
    ...
}
```

现在我们执行以下代码：  
```c++
BuyTransaction b;
```

我们很快发现了问题，Transaction构造函数在最后一行调用`logTransaction`方法，但这时候被调用的Transaciton的版本，而不是BuyTransaction的版本。本例中，由于logTransaction方法是纯虚函数，还会抛出连接器错误。也就是说，基类构造函数调用期间，virtual函数不是virtu函数，不会下降到derived class的阶层。  
我们有两个原因解释这个现象：  
1. base class的构造函数先于derived class的构造函数调用。这个时候derived class很多成员变量尚未初始化，C++为了防止一些不安全的行为（如使用未初始化的变量），不能使用derived class的成员函数。
2. 在base class构造函数运行期间，所有的运行期类型信息（virtual函数，dynamic_cast，typeid等等）会被编译器解析为base class类型。也就是说，在derived class构造函数调用之前，并不是成为derived对象，而是视为base对象。

<br>

同样的道理也适用于析构函数，由于derived class的析构函数先于base class的析构函数调用。所以在base class析构函数调用时，derived class的成员变量是未定义值，C++视它们为不存在。base class析构函数后的对象成为一个base对象，C++的virtu函数部分也对应base class的定义。

## 编译器能监测构造/析构过程中是否调用virtual函数吗？
可能你有个疑问，那禁止在构造/析构函数中调用virtual函数不就好了吗？这对编译器很容易实现吧？  
回答这个问题之前，我们先来看下面一段代码：
```c++
class Transaction{
public:
    Transaction();
    virtual void logTransaction() cosnt = 0 ; //  日志记录
private:
    void init();
};
Transaction::Transaction(){
    init();
}
void Transaction::init(){
    ...
    logTransaction();
}
```

如果我们有多个构造函数，我们可能会提取重复部分（即init方法）。如果virtual函数存在于init方法中，而编译器检测构造函数并没有发现调用virtual函数，很有可能就让这段有问题的代码通过了。所以编译器监测构造/析构过程中是否调用virtual函数并不容易。

## 解决方法
这个场景下我们知道构造函数中肯定无法调用derived class的virtual函数了，所以解决方法就是将virtual函数转化为non-virtual函数。同时我们可以在derived class构造之前，通过初值列将必要的构造信息向上传递给base class的构造函数，从而实现不同类型的日志记录。  
代码逻辑如下：
```c++
class Transaction{
public:
    explicit Transaction(const std::string& logInfo);
    void logTransaction(const std::string& logInfo); //  non-virtual函数
    ...
};
Transaction::Transaction(const std::string& logInfo){
    ...
    logTransaction(logInfo)
}

class BuyTransaction:public Transaction{
public:
    BuyTransaction(params):Transaction(createLogString(params)){...}
    ...
private:
    //  这里可以先将params参数操作后再传递给base class构造函数，增强灵活性和可读性
    static std::string createLogString(params);
};
```

注意，createLogString修饰为static，可以防止构造函数初始化过程中，该方法不会指向BuyTransaction对象内尚未初始化的成员变量。这很重要，因为base class构造和析构函数期间，这些成员变量处于未定义状态，不能下降传递给derived class。

## 总结
> + 不要在构造/析构函数中调用virtual函数，因为这类调用不能下降到derived class层


# Reference
[1] <<Effective C++>>  
[2] [虚函数（virtual）](https://blog.csdn.net/qq_37200329/article/details/100066599)  
[3] [C++中类所占的内存大小以及成员函数的存储位置](https://blog.csdn.net/luolaihua2018/article/details/110736211)