---
title: 读书笔记 —— Effective C++(9)
authors: fanventory
date: 2023-02-22 14:55:00 +0800
categories: [Reading Notes,Effective C++]
tags: [C++, Reading Notes]
---

> 本节我们从类实现的角度来给出一些建议。在类的实现中，我们可以在变量使用之前的容易地方进行定义，但是不妥的定义位置可能会导致多余的运行成本，这个实现的小细节可能被很多人所忽略。此外，类实现时我们可能会用到一些转型，转型的表示方式有很多，但你会发现新式转型比旧式更加好用。转型不只是简单的换个解释方式，编译器会增加一些额外的语句转换变量。这导致了转型过程很容易出现错误，而且有一些转型特别费时，我们应该用其他方法尽量避免转型。最后讲到类实现过程中的返回值问题，我们再一次声明了返回引用、指针和迭代器是很不安全的。但是为了提高效率，很多情况下我们得选择返回引用（比如数据储存在外部结构且数据量很大的情况）。这种情况我们可以用const修饰返回值，以此来达到可读不可写的目的。

<br>
<br>

# 延后变量定义的时间
## 避免无意义的成本
当程序的控制流到达一个变量定义的时候（假设这个变量带有构造函数和析构函数），就能进入构造函数，产生构造成本。当这个变量离开其作用域的时候，就会产生析构成本。所以有些情况下，应该延后变量定义的时间，防止变量未被使用，就会耗费了构造和析构的成本。  
我们来通过下面这个例子说明这种情况：  

<br>

现在我们有一个加密函数，功能是对用户输入的密码进行加密。
```c++
string encryptPassword(const string& password)
{
    string encrypted;
    //  如果密码长度过短，我们抛出错误
    if(password.length < MinimumPasswordLength){
        throw logic_error("password is too short!");
    }
    encrypted=password;
    encrypt(encrypted); //  执行加密
    return encrypted;
}
```

我们可以看到，如果我们输入的密码过短，就会进入if分支中，从而抛出错误，下面的加密过程不会再进行。但是，上面实现中，我们先声明了变量encrypted，哪怕它并未被使用，我们也耗费了构造和析构变量encrypted的成本。  
这些成本完全是没有必要的。所以我们做出了如下修改：  
```c++
string encryptPassword(const string& password)
{
    //  如果密码长度过短，我们抛出错误
    if(password.length < MinimumPasswordLength){
        throw logic_error("password is too short!");
    }
    string encrypted;
    encrypted=password;
    encrypt(encrypted); //  执行加密
    return encrypted;
}
```

现在这个函数少了不必要的构造和析构成本了。但是，它还不是完美的。还记得前面提到过尽量用初始化代替赋值吗？变量encrypted先调用了default构造函数，然后调用了赋值函数。如果我们直接使用copy构造函数，就可以免去无意义的default构造函数的成本，就像下面这样：  
```c++
string encryptPassword(const string& password)
{
    //  如果密码长度过短，我们抛出错误
    if(password.length < MinimumPasswordLength){
        throw logic_error("password is too short!");
    }
    string encrypted(password); //  copy构造函数
    encrypt(encrypted); //  执行加密
    return encrypted;
}
```

所以我们延迟变量定义的时间，应该尽可能延迟到该变量能够确定实参，这样不仅可以避免构造和析构无意义的对象，还能避免无意义的default构造行为。

## 循环
上面的建议可以让我们在很多地方受用，但我们很快发现了一个特殊情况：循环。  
我们先看下面两个循环体：  
```c++
//  循环1
Widget w;
for (int i=0;i<n;i++){
    w=arr[i];
    ...
}

//  循环2
for (int i=0;i<n;i++){
    Widget w=arr[i];
    ...
}
```

现在我们来分析一下它们的成本：  
循环1： 1次构造函数 + 1次析构函数 + n次赋值操作  
循环2： n次构造函数 + n次析构函数  

<br>

它们的成本谁大谁小只能具体情况具体分析。  
如果赋值成本低于构造+析构成本，那循环1更加高效。尤其是n很大的时候，循环1的效率更明显。如果赋值成本高于构造+析构成本，循环2会更好。此外循环1中变量w的作用域更大，可能会与后续的变量产生冲突，降低代码的可阅读性和易维护性。  
所以除非赋值成本低于构造+析构成本，且代码对效率要求很高的时候，应该采用循环2的做法。

## 总结
> + 延后变量定义的时间，尽可能延迟到该变量能够确定实参
> + 除非赋值成本低于构造+析构成本，且代码对效率要求很高的时候，循环2的做法会更好

# 减少转型
转型是程序中危险却又必不可少的一个特性，如果可以，我们应该尽可能避免转型。在探讨减少转型之前，我们先来回顾一下转型。
## 转型形式
转型通常由三种不同的形式：
1. (T)expression;   //  将expression转型为T
2. T(expression);   //  将expression转型为T
3. c++提供的新式转型，分为四种:  
> + const_cast\<T>(expression);  
通常用来将对象的常量性转除
> + dynamic_cast\<T>(expression);  
主要用来实现“安全向下转型”，也就是用来决定某对象是否归属继承体系中的某个类型。它是唯一无法用旧式转型语法实现的动作，也是唯一可能耗费重大运行成本的转型动作
> + reinterpret_cast\<T>(expression);  
reinterpret_cast运算符是用来处理无关类型之间的转换；它会产生一个新的值，这个值会有与原始参数（expressoin）有完全相同的比特位
> + static_cast\<T>(expression);  
强迫隐式转换

新式转型比旧式转型更受欢迎，原因有以下两点：
1. 相比旧式转型，新式转型在代码中更容易被辨认
2. 新式转型作用范围变窄，编译器更可能诊断出错误

## 转型动作
有些程序员可能决定转型实际上什么也没做，只是让编译器将某种类型视为另一种类型，这是不对的。类型转换往往会令编译器产生一些代码，由这些代码来执行转型动作。我们来看下面两个例子：  
```c++
//  例子1
int x,y;
...
double d = static_cast<double>(x)/y;
```

上面将int类型转换为double类型，由于int类型和double类型底层的描述是不一样的，所以肯定产生一些代码完成转换操作，而不能单纯地将底层比特位换种方式解释。

```c++
//  例子2
class B1 {...};
class B2 {...};
class D : public B1, public B2 {...};

int main()
{
	D aD;

	D* pD = &aD;
	B1* pB1 = &aD;
	B2* pB2 = &aD;

	cout << *pD << endl;
	cout << *pB1 << endl;
	cout << *pB2 << endl;
	return 0;
}
//  输出结果：
009DFE10
009DFE10
009DFE14
```

上面这个例子可以看到，同一个指针，发生了隐式转换后的值可能是不相同的。原因是为了能正确得到Base指针值，编译器运气期间给指针加上了一个偏移量(offset)。所以单一对象可能拥有一个以上的地址。  
请注意，由于对象的结构布局和地址计算方式根据编译器的不同而不同，意味着更换平台后，“根据对象布局进行类型转换”这种做法不一定行得通。  

## 错误转型
假设我们有个Window类和SpecialWindow类，这两个类是继承关系，且它们都有onResize()函数。  
如果我们需要在SpecialWindow的onResize()函数中调用Window的onResize()函数，下面做法是错误的：  
```c++
class Window{
public:
    virtual void onResize() { ... }
    ...
};

class SpecialWindow:public Window {
public:
    virtual void onResize () {
        static_cast<Window>(*this).onResize();  //  转型，然后调用基类的onResize函数
        ... //  子类onResize函数的专属行为
    }
    ...
}
```

乍看之下没有什么问题，但是static_cast<Window>(*this)将this转型后，会返回一个this的副本，即当前对象base class成分的副本。接着我们在这个副本上调用Window::onResize()函数，然后在原来的对象上调用SpecialWindow::onResize()函数。如果这两个onResize()函数都涉及修改，就会造成base class成分的修改没有失效，而derive class成分的修改失效了。这种行为是不正确的，可能会造成bug。  

<br>

那怎么解决呢？很简单，调用base class版本的onResize()函数就可以了：  
```c++
class SpecialWindow:public Window {
public:
    virtual void onResize () {
        Window::onResize();  //  调用Window::onResize()，作用在this上
        ...
    }
    ...
}
```

错误的行为就像你想欺骗编译器将this视为一个base对象，而你的目的应该是调用当前对象的base版本的onResize()函数，所以拿掉转型才是正确之道。

<br>

你可能注意到dynamic_cast用于继承类之间的转型，那是不是就能解决上述问题了呢？我们来看下面这个例子，你手上有base class的指针，但你想调用derive class中的操作函数，你可能自然而然地想用转型来实现。  
```c++
class Window{ ... };
class SpecialWindow:public Window {
public:
    void blink();   //  只有SpecialWindow类才有blink()函数
    ...
}
typedef vector<shared_ptr<Window>> VPW; //  用容器和智能指针管理

VPW winPtrs;
...
for(VPW::iterator iter = winPtrs.begin(); iter != winPtrs.end(); iter++ ){
    if(SpecialWindow *psw=dynamic_cast<SpecialWindow*>(iter->get())){
        pws->blink();   //  错误做法
    }
}
```

这样做虽然程序并不会报错，但问题在于dynamic_cast实现的速度非常慢。因为dynamic_cast在向下转换的时候会进行安全检查，如果是多层继承或者多重继承，每一次继承都要执行检查，成本很高。所以我们应该尽量避免使用转型去完成上述操作。

> ## dynamic_cast
> + dynamic_cast运行时会检查类型安全（转换失败返回NULL）
> + dynamic_cast在将父类cast到子类时，父类必须要有虚函数，否则编译器会报错
> + 在类层次间进行上行转换时，dynamic_cast和static_cast的效果是一样的
> + 在进行下行转换时，dynamic_cast具有类型检查的功能，比static_cast更安全
> + dynamic_cast利用c++的RTTI机制确保转换的正确性，RTTI指c++的运行时类型识别信息，这个信息是该类虚函数表中存放的typeinfo的指针，里面记录了该类的类型信息和继承关系。在进行动态类型转换时，先取虚函数表中的第-1个元素得到type_info类，然后判断是否是你要转换的类型以及在继承关系是否合法，最后再进行转型操作

由于效率低下，我们一般避免使用这种方法，替换方法有两种：  
1. 使用类型安全容器，即容器中只存储一种类型，避免通过Base接口处理对象

```c++
typedef vector<shared_ptr<SpecialWindow>> VPSW; //  用容器和智能指针管理

VPSW winPtrs;
...
for(VPSW::iterator iter = winPtrs.begin(); iter != winPtrs.end(); iter++ ){
    (*iter)->blink();
    ...
}
```

当然这种如果有多种派生类，我们需要多个容器，这种方法并不方便。

2. 在base class中提供virtual函数，这样就可以在不用转型的情况下，使用base class的接口操作derive class的函数。

```c++
class Window{
public:
    virtual void blink(){ }
    ...
};
class SpecialWindow:public Window {
public:
    virtual void blink(); 
    ...
}
typedef vector<shared_ptr<Window>> VPW; //  用容器和智能指针管理

VPW winPtrs;
...
for(VPW::iterator iter = winPtrs.begin(); iter != winPtrs.end(); iter++ ){
    (*iter)->blink();   //  错误做法
    ...
}
```

## 绝对避免的转型
在上面的例子中，如果derive class有多种类型，那对应的转型代码可能写成这个样子：  
```c++
typedef vector<shared_ptr<Window>> VPW; //  用容器和智能指针管理

VPW winPtrs;
...
for(VPW::iterator iter = winPtrs.begin(); iter != winPtrs.end(); iter++ ){
    if(SpecialWindow1 *psw1=dynamic_cast<SpecialWindow1>(iter->get())){...}
    else if(SpecialWindow2 *psw2=dynamic_cast<SpecialWindow2>(iter->get())){...}
    else if(SpecialWindow3 *psw3=dynamic_cast<SpecialWindow3>(iter->get())){...}
    ...
}
```

这种行为称为 “连串(cascading)dynamic_cast” 。我们要杜绝这种做法，因为：  
1. dynamic_cast效率低，这样生成的代码又大又慢
2. 如果产生或减少分支，上面的代码需要重新检查一遍
3. 这样的代码可以采用基于virtual的函数调用取而代之

## 总结
> + 尽量避免转型，如果设计中有转型动作，尝试用其他解决方法替代它
> + 如果转型是必要的，将他用某个函数包装起来，避免客户将转型放入自己的代码中
> + 尽量用新式转型，因为新式转型更方便纠错和调试

# 避免返回handle指向对象内部成员
这里的handle指的是引用，指针和迭代器，通过这些对象，我们可以修改对象内部的私有对象。  
首先让我们来看一个例子：我们用一个类表示矩形（左上角点和右下角点表示）
```c++
//  表示点的类
class Point {
public:
	Point(int x, int y);
	void setX(int x);
	void setY(int y);
    ...
private:
	int x, y;
};

//  表示矩形的结构体
struct RectData {
	Point ulhc;
	Point lrhc;
};

//  用智能指针管理结构体
class Rectangle {
private:
	shared_ptr<RectData> pData;
public:
	Point& upperLeft() const { return pData->ulhc; }
	Point& lowerLeft() const { return pData->lrhc; }
    ...
};
```

upperLeft()和lowerLeft()函数表示返回左上角的点和右下角的点，但是这两个方法返回了引用，给了我们一个修改内部数据的机会：  

```c++
Point coord1(0, 0);
Point coord2(100, 100);
const Rectangle rec(coord1,coord2);
//  (0,0),(100,100)
rec.upperLeft().setX(50);
//  (50,0),(100,100)
```

upperLeft()和lowerLeft()应该是一个只读函数，矩阵对象rec也是声明为可读的，却发生了修改行为，这显然不对。我们可以从中看出：
1. 成员变量的封装性可以被返回引用的函数改变。  
2. 如果const成员函数传出一个引用，后者所指数据与对象自身相关联，那这个函数调用者可以修改这笔数据。  

而我们前面提到的handle(引用，指针和迭代器)，都可以降低对象的封装性，使const成员函数发生对象状态的改变。  
但是有些情况我们可能不得不采用引用，像上面这个例子，类中的数据存储在外部结构体中，返回的对象可能特别大，对于一些效率要求比较高的程序而已，我们得想一个两全其美的解决方法。

## 解决方法
解决方法也很简单，只要在返回类型上加上const限制即可：  
```c++
class Rectangle {
private:
	shared_ptr<RectData> pData;
public:
	const Point& upperLeft() const { return pData->ulhc; }
	const Point& lowerLeft() const { return pData->lrhc; }
    ...
};
```

修改之后，返回的Point点只可读，不可写。

## 其他情形
上面我们讲了返回对象的handle可能修改对象内部的私有数据，但还有一种很严重的情况：返回的handle可能指向一个不存在的对象。我们先来看下面这个例子：  
```c++
//  这是一个GUI类
class GUIObject { ... };
//  传入GUI对象，返回一个表示GUI外框的矩阵对象
const Rectangle boundingBox(const GUIObject& obj);
```

接着我们这么使用这个函数：  
```c++
GUIObject* pgo;
...
const Point* pUpperLeft = &(boundingBox(*pgo).upperLeft());
```

我们来分析一下这段代码，boundingBox(*pgo)返回了一个临时对象，我们称为tmp，tmp调用了upperLeft()方法得到了Point对象。当语句结束后，tmp会被析构，也间接导致了Point对象也被析构，所以pUpperLeft会指向一个不存在的对象。这就是所谓的dangling handles（空悬、虚吊）。这也是函数返回handle可能造成的后果之一。

最后我们强调，并不是说成员函数一定不能返回handle，比如我们通过[]获取vector元素的时候，是允许我们进行修改的。但这种情况毕竟是少数，我们在实现类的时候，对于返回handle的情况应该仔细斟酌。

## 总结
> + 避免返回handle(包括引用)指向对象内部成员

# Reference
[1] <<Effective C++>>  
[2] <<C++ Primer>>  
[3] [dynamic_cast介绍](https://blog.csdn.net/qq_36553031/article/details/109625502)  
[4] [C++标准转换运算符之 reinterpret_cast](https://blog.csdn.net/p942005405/article/details/105783090)   