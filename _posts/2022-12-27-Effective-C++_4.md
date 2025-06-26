---
title: 读书笔记 —— Effective C++(4)
authors: fanventory
date: 2022-12-27 15:06:00 +0800
categories: [Reading Notes,Effective C++]
tags: [C++, Reading Notes]
---

> 众所周知我们编写程序的过程中经常会遇到需要动态对象的情况，我们new出动态对象时却由于各种原因可能忘记delete。这一章节我们先简单介绍了几种程序没有delete动态对象的情况。然后针对这个问题，我们介绍了采用c++中的智能指针来管理对象，从而能使对象在生命周期结束或发生异常的情况下，自动完成delete操作。

<br>
<br>

# 用智能指针管理资源的释放
我们在平时编写代码时，经常会new一些对象，然后在代码的结束部分将他们delete掉。就像下面这样：  
```c++
void function() {
    Person *p = new Person();
    p->doSomething();
    delete p;
}
```

我们知道如果没有及时delete我们创建的对象，就会造成内存泄漏。当然对于入门后的程序员来说，这肯定不会轻易忘记在末尾加一句delete。  
但现实比我们想象中的要复杂得多，有许多情况可能会导致我们并没有delete创建的对象。下面我们列举其中的几种情况：
1. 过早地return  

我们可能在delete语句之前，先执行了return语句，导致并没有及时delete我们创建的对象。就像下面这样：  
```c++
void function() {
    Person *p = new Person();
    if(...) {
        return;
    }
    p->doSomething();
    delete p;
}
```

2. 过早地跳过或结束循环

如果我们的delete语句在循环中（这极有可能），可能由于continue或者goto或者break语句，恰好跳过了delete语句。就像下面这样：  
```c++
void function() {
    while(...){
        Person *p = new Person();
        if(...) {
            continue;   // 看，这后面的p并没有被delete掉
        }   
        p->doSomething();
        delete p;
    }

}
```

3. 抛出异常

如果程序运行到delete语句之前，就发生了异常，那后面的delete语句将永远不会执行，同样跳过了delete！就像下面这样：
```c++
void function() {
    Person *p = new Person();
    ... //  发生了异常，后面的语句都不会执行
    p->doSomething();
    delete p;
}
```

可见，现实情况之复杂将导致我们不会尽善尽美，算无遗策地delete任何一个new出来的对象。就算我们编写代码的时候足够小心，足够谨慎，那我们修改代码的时候呢？如果别人接手了你的代码，在你的delete语句之前加了一个判断语句执行return操作，是不是就导致了delete语句在某些情况下并不会执行？  
为了解决这个问题，我们的思想是在程序控制流运行到区域边界的时候，由对象的析构函数自动释放这些资源（即使遇到异常的情况，我们也希望能正确释放资源）。而我们发现C++的智能指针，正好满足我们的需求！  
所以接下来，我们需要解决的问题是让程序自动调用析构函数释放资源，同时我们将介绍三种智能指针来解决这个问题。  

> RAII思想：RAII(Resource Acquisition Is Initialization)指我们上述所提到的思想观念，当我们获得一个资源的时候（比如new了一个对象，获得指向该对象的指针），然后在同一语句内将它初始化给某个管理对象（智能指针），也就是说每一笔资源在获得的同时就立刻放入管理资源中。这样，一旦对象离开作用域，就会立即被其析构函数销毁。

## 总结
> + 为了防止资源泄露，我们建议用智能指针来管理资源的释放

# 智能指针
C++主要的智能指针有3种，分别是unique_ptr、shared_ptr和weak_ptr这三种智能指针都定义在memory头文件中。他们都作用都是更加安全地使用动态内存，自动释放所指对象。接下来我们将一一介绍这几种智能指针。  

## auto_ptr
在介绍unique_ptr之前，我们先来介绍auto_ptr，它和unique_ptr功能类似，是c++11以前的最原始的智能指针，但是在c++11中已经被弃用（使用的话会被警告）了。c++11中完善了auto_ptr，推出了更加安全的unique_ptr。

auto_ptr是一个包含指针的对象，其析构函数会自动对所指对象调用delete。用法如下：  
```c++
void function() {
    std::auto_ptr<Person> peter(new Person()); // 创建一个父亲对象，并用auto_ptr管理
    peter->doSomething();
    // 作用域结束，auto_ptr的析构函数自动调用delete
}
```

这里需要注意的是，不能让多个auto_ptr指向同一个对象，就像下面这样：  
```c++
void function() {
    Person *p=new Person(); // 当然，这里违反了RAII思想原则
	std::auto_ptr<Person> peter(p);
	std::auto_ptr<Person> peter2(p);
	peter->doSomething();
	peter2->doSomething();
}
```

在上面这个例子中，作用域结束时`peter`会delete掉Person对象p，然后由于`peter2`也指向了Person对象p，会尝试delete对象p。但由于对象p已经被delete掉了，所以程序报错，不能释放一个空指针。  

还有一个需要注意的点是，auto_ptr是独占性的，不允许通过赋值或copy构造函数使多个auto_ptr指向同一个资源。也就是说，通过赋值或copy构造函数复制auto_ptr对象的话，会把指针指传给复制出来的对象，原有对象的指针成员随后重置为nullptr，就像下面这样： 
```c++
void function() {
	std::auto_ptr<Person> peter(new Person());
	std::auto_ptr<Person> peter2(peter); // 这里指针转移给了peter2，peter所指指针为nullptr
	peter->doSomething(); // error,peter所指指针为nullptr
	std::auto_ptr<Person> peter3 = peter2; // 这里指针转移给了peter3，peter2所指指针为nullptr
	peter2->doSomething(); // error,peter2所指指针为nullptr
    peter3->doSomething(); // ok,Person对象指针最终被转移到peter3
}
```

## unique_ptr
由于auto_ptr可能通过赋值或copy构造函数传递所指指针，导致程序出现空指针异常，这样不但不安全，反而使程序更容易出错。为了解决这个问题，提出了unique_ptr。unique_ptr在执行赋值或copy构造函数时，编译期就会出错，而auto_ptr则可以通过编译期。同时为了解决指针转移的问题，给出了std::move(std::unique_ptr对象)语法以及reset()+release()的方法，相比auto_ptr更加安全。unique_ptr的用法如下：  
```c++
void function() {
	std::unique_ptr<Person> father(new Person());
	father->doSomething();
	std::unique_ptr<Person> father2 = move(father); // 转移指针,father会变成nullptr
	father2->doSomething();
    // 作用域结束，unique_ptr的析构函数自动调用delete
}
```

unique_ptr还有几个常用的内置方法：  
1. release()

`release`方法的作用是使unique_ptr对象放弃当前所指指针的控制权，并返回指针，然后unique_ptr对象置空。需要注意的是，释放指针后我们需要自己负责资源的释放，例子如下：
```c++
unique_ptr<string> p(new string("hello"));
p.release(); // 错误，这样字符串对象会悬空，没有任何指针指向它，造成内存泄漏
auto q = p.release(); // 正确，获取释放的指针，然后手动释放
delete q;
```

2. reset()

`reset`方法意如其名，就是重置unique_ptr对象指向的指针，原来所指的对象会被释放，而unique_ptr会指向新的对象。它经常和release方法结合使用，用来转移指针的所有权给另一个unique_ptr对象。具体用法如下：  
```c++
unique_ptr<Person> p1(new Person("zhangsan"));
p1.reset(); // 释放p1所指指针
Person *pt=new Person("lisi");
p1.reset(pt);  // 如果传入内置指针，就让p1指向这个对象
p1.reset(nullptr); // 传入空指针，这和p1.reset();效果一致

unique_ptr<Person> p2(p1.release()); // 利用release转移指针
unique_ptr<Person> p3(new Person("wangwu"));
p1.reset(p3.release()); // 利用reset+release转移指针
```

3. get()

`get`方法的作用是返回所指的指针，该方法设计的主要目的是为了向不能使用智能指针的代码传递内置指针。但是该方法存在需要隐患，例如我们返回了指针，然后手动释放了它，那智能指针所指的对象也就失效了。或者我们返回了指针，然后智能指针释放了其对象，那我们得到的指针就是一个无效的指针，同样会导致错误。  
```c++
unique_ptr<Person> p1(new Person("zhangsan"));
Person *p=p1.get(); // 获取p1的内置指针
```

这里我们总结了几点建议：  
+ 不能使用get()初始化或reset另一个智能指针
+ 如果你使用了get()返回的指针，记住最后一个对应的智能指针销毁后，你的指针就无效了
+ 不要混用智能指针和内置指针，因为他们可能使彼此失效

<br>

虽然说unique_ptr不能拷贝，但存在一种特殊情况：我们可以拷贝或赋值一个将要被销毁的unique_ptr。这种情况一般用于方法内返回一个unique_ptr对象。具体用法如下：  
```c++
unique_ptr<int> clone(int p){
    ...
    // 方法内返回unique_ptr对象
    return unique_ptr<int>(new int(p));
}
unique_ptr<int> clone(int p){
    unique_ptr<int> ret(new int(p));
    ...
    // 方法内返回一个局部对象的拷贝
    return ret;
}
```

> boost库的boost::scoped_ptr也是一个独占性智能指针，但是它不允许转移所有权，从始而终都只对一个资源负责，它更安全谨慎，但是应用的范围也更狭窄。

## shared_ptr
shared_ptr和unique_ptr的区别在于，shared_ptr不是独占的，允许多个shared_ptr指向同一个对象，并用一个计数器进行管理。只有当计数器中指向该对象的引用数为0时，才会释放该对象内存。shared_ptr的用法如下：  
```c++
shared_ptr<string> p1;
shared_ptr<list<int>> p2;
shared_ptr<string> p3(p1); // p3和p1指向同一个对象，次数该对象计数为2
shared_ptr<string> p4("hello");
p4 = p1; // p4指向了p1所指的对象
         // 原来p4所指的对象对应的计数会递减，由于减少到0，所以会释放该对象
         // 原来p1所指的对象对应的计数会递增，现在p1,p3,p4指向了该对象，计数器为3
```

接下来我们介绍shared_ptr的几个常用操作：  
1. make_shared<T>(args)

`make_shared`方法的作用是动态分配一个T类型的对象并初始化它，然后返回该对象的shared_ptr。T为想要创建对象的类型，args为初始化参数，参数类型和数量需要与类T的构造函数对应。具体用法如下：  
```c++
// 指向值为42的int
shared_ptr<int> p1=make_shared<int>(42);
// 指向值为"9999999999"的string
shared_ptr<string> p2=make_shared<string>(10,'9');
// 指向值为0的int
shared_ptr<int> p3=make_shared<int>();
// 我们还可以用auto来表示结果
auto p4=make_shared<vector<string>>();
```

2. unique()

`unique`方法的作用是判断所指对象的引用计数是否为1，若为1返回true，否则返回false。它的主要用途一般是判断自己是否是唯一引用的shared_ptr，如果是才能发现修改所指指针的值，而不会影响其他使用到该指针的地方。
```c++
if(!p.unique()){
    p.reset(new string(*p)) // 我们不是唯一的用户，生成一个新的拷贝
}
*p = "hello world!"; // 我们是唯一的用户，所以可以改变该对象的值
```

3. use_count()

`use_count`方法的作用是返回共享对象的引用数，可能会运行得很慢，主要用于调试。

4. get()

`get`方法与unique_ptr的get方法相同，详情见上文。

<br>

shared_ptr也存在一些缺陷。
1. shared_ptr和unique_ptr都是在析构函数中做delete操作，而不是delete[]操作。这意味着，用智能指针管理动态分配的数组将是一个馊主意，因为这会导致内存泄漏。
```c++
unique_ptr<string> aps(new string[10]); // 错误，会调用错误的delete形式
shared_ptr<int> spi(new int[1024]); // 错误
```

2. 如果两个shared_ptr互相引用彼此，或者环状引用，那shared_ptr关联的计数永远不可能为1，这意味着它永远不会释放内存。让我们来看下面这个例子：  
```c++
class Person {
private:
	string name;
	shared_ptr<Person> father;
	shared_ptr<Person> son;
public:
	void doSomething() { cout << "doSomething" << endl; }
	void setFather(shared_ptr<Person>& person) { this->father = person; }
	void setSon(shared_ptr<Person>& person) { this->son = person; }
	~Person() { cout << "the process die" << endl; }
};

int main()
{
	shared_ptr<Person> bigHeadSon(new Person());
	shared_ptr<Person> smallHeadFather(new Person());
	bigHeadSon->setFather(smallHeadFather);
	smallHeadFather->setSon(bigHeadSon);
	return 0;
}
```

我们通过输出可以发现bigHeadSon和smallHeadFather的析构函数并没有被调用，也就是说这两个对象并没有被释放掉。  
我们来仔细分析一下，bigHeadSon的成员变量father关联了smallHeadFather，smallHeadFather的成员变量son关联了bigHeadSon。这时候bigHeadSon和smallHeadFather对应的引用计数均为2。当程序运行到作用域末尾：  
+ bigHeadSon智能指针退出栈，此时bigHeadSon引用数为1，smallHeadFather引用数为2  
+ smallHeadFather智能指针退出栈，此时smallHeadFather引用数为1，bigHeadSon引用数为1
+ 函数结束：所有计数都没有变0，也就是说中途没有释放任何堆对象  

为了解决这个问题，我们接下来提出weak_ptr。

## weak_ptr
weak_ptr是一种弱共享的智能指针，也就是说它绑定到一个shared_ptr中，但并不改变shared_ptr的引用计数，当weak_ptr计数为0时，并不改变对象的生命周期。相反，如果对象的shared_ptr计数为0时，哪怕对象绑定的weak_ptr引用计数不为0，依然改变不了对象被释放的结局。  
基于weak_ptr的特性，我们可以修改上面这个例子，使多个智能指针中间的互相引用变得更加合理和安全。  
```c++
class Person {
private:
	string name;
	weak_ptr<Person> father;
	weak_ptr<Person> son;
public:
	void doSomething() { cout << "doSomething" << endl; }
	void setFather(shared_ptr<Person>& person) { this->father = person; }
	void setSon(shared_ptr<Person>& person) { this->son = person; }
	~Person() { cout << "the process die" << endl; }
};

int main()
{
	shared_ptr<Person> bigHeadSon(new Person());
	shared_ptr<Person> smallHeadFather(new Person());
	bigHeadSon->setFather(smallHeadFather);
	smallHeadFather->setSon(bigHeadSon);
	return 0;
}
```

通过输出我们可以知道，bigHeadSon和smallHeadFather被正确得释放。这个例子中，当程序运行到作用域末尾：  
+ bigHeadSon智能指针退出栈，此时bigHeadSon的shared_ptr引用数为0，weak_ptr引用数为1  
+ smallHeadFather智能指针退出栈，此时smallHeadFather的shared_ptr引用数为0，weak_ptr引用数为1  
+ 函数结束：虽然两个对象的weak_ptr引用数均不为0，但由于weak_ptr补控制对象的生命周期，而shared_ptr的引用数都为0，所以两个对象都会被正确得释放

此外weak_ptr没有重载 * 和 -> 操作符，所以并不能直接使用资源。但我们可以通过它的一些内置方法操作对象。下面我们简单介绍几个常用的成员方法：  

1. reset()

`reset`方法和shared_ptr的reset方法功能差不多，可以用于赋值新的引用对象，也可以将当前weak_ptr指向空指针。

2. use_count()

`use_count`方法返回的是与当前weak_ptr共享对象的shared_ptr的数量，要注意这里返回的是shared_ptr的数量，而不是weak_ptr的数量。

3. expired()

`expired`方法是检查当前所指的对象是否已被释放，即当前所指共享对象的shared_ptr的数量是否为0，若为0返回true，否则返回false。

4. lock()

`lock`方法是返回当前所指共享对象的shared_ptr，然后通过该shared_ptr来操作对象。当然，如果该对象已被释放，即该对象的use_count为0的话，将返回一个空的shared_ptr。所以weak_ptr在没有重载 * 和 -> 操作符的情况下，我们需要通过lock方法间接获得shared_ptr来使用资源。具体用法如下：  
```c++
void function()
{　　
  shared_ptr<Person> p1(new Person());　　 
  weak_ptr<Person> w1 = p1;　　
  w1->doSomething(); //Error! 编译器出错！weak_ptr没有重载* 和 -> ，无法直接当指针用　　   		      
  shared_ptr<Monster> p2 = w1.lock();
  p2->doSomething(); // OK! 可以通过weak_ptr的lock方法获得shared_ptr来操作对象
}
```

## deleter
有些情况我们需要自定义结束操作，例如我们用一个对象管理数据库连接，而我们经常会忘记关闭连接操作（这和忘记delete是一样的），那我们同样可以用智能指针来管理资源。但这个时候，当数据库连接器的生命周期结束时，我们需要做的不是销毁这个对象，而是让这个对象关闭连接。  
幸运的是c++中的智能指针为自定义结束操作提供了很好的灵活性，只要我们传入一个自定义函数，就可以完成自定义的结束操作。具体用法如下：  
```c++
void endConnection(connection *p){
    close(p);   //  关闭数据库连接
}
void function()
{　　
    connection c = connect(...); // 获取数据库连接
    shared_ptr<connection> p(&c,endConnection);
    ... // 执行数据库相关操作
    // 当退出函数时（即使遇到异常情况），connection对象都会自动执行endConnection方法关闭连接
}
// 在unique_ptr中，由于模板的原因，写法有略微不同
void function()
{　　
    connection c = connect(...); // 获取数据库连接
    // decltype作用是指明函数指针类型，由于decltype返回一个函数类型，所以需要加*来表明当前传递的是一个指针
    unique_ptr<connection,decltype(endConnection)*> p(&c,endConnection);
    ... // 执行数据库相关操作
    // 当退出函数时（即使遇到异常情况），connection对象都会自动执行endConnection方法关闭连接
}
```

## 总结
> + 不要使用std::auto_ptr，它已经过时了
> + 当你需要一个独占资源所有权（访问权+生命控制权）的指针，请使用std::unique_ptr
> + 当你需要一个共享资源所有权（访问权+生命控制权）的指针，请使用std::shared_ptr
> + 当你需要一个能访问资源，但不控制其生命周期的指针，请使用std::weak_ptr
> + 建议使用一个shared_ptr和n个weak_ptr搭配，而不是定义n个shared_ptr。

# Reference
[1] <<Effective C++>>  
[2] <<C++ Primer>>  
[3] [C++智能指针详解](https://blog.csdn.net/locahuang/article/details/119026233)  