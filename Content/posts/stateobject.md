---
date: 2020-06-26 12:00
description: WWDC20刚刚结束，在过去的一周，苹果为开发者带来了巨大的惊喜。由于新特性实在太多，需要不少时间来消化，我首先选择自己最感兴趣的内容进行一些简单的研究和探讨。本文首先浅谈一下SwiftUI新提供的属性包装器@StateObject。
tags: SwiftUI
title: SwiftUI 2.0 —— @StateObject 研究
---


> WWDC20刚刚结束，在过去的一周，苹果为开发者带来了巨大的惊喜。由于新特性实在太多，需要不少时间来消化，我首先选择自己最感兴趣的内容进行一些简单的研究和探讨。本文首先浅谈一下SwiftUI新提供的属性包装器@StateObject。

## 为什么要新增@StateObject ##

在我之前的文章[@State研究](https://zhuanlan.zhihu.com/p/141229504)中我们探讨过@State，通过它，我们可以方便的将值类型数据作为View的Source of truth。在SwiftUI 1.0时代，如果想将引用类型作为source of truth,通常的方法是使用@EnvironmentObject或者 @ObservedObject。

```swift
struct RootView:View{
    var body: some View{
        ContentView()
            .environmentObject(Store())
    }
}

struct ContentView: View {
    @EnvironmentObject  var store1:Store
    var body: some View {
        Text("count:\(store.count)")
    }
}
```

对于使用@EnvironmentObject注入的数据，由于其通常是在SceneDelegate或着当前View的父辈、祖先View上创建的，所以其生命周期必然不短于当前View,因此在使用中并不会发生由于生命周期不可预测而导致的异常。

```swift
struct Test5: View {
    @ObservedObject var store = Store()
    var body: some View {
        Text("count:\(store.count)")
    }
}
```

对于上面的代码，乍看起来没有任何不妥，不过由于@ObservedObject的机制问题，其创建的实例并不被当前View所拥有（当前View无法管理其生命周期），因此在一些特殊的情况下会出现不可预料的结果。

为了能够让开发者更好的掌控代码，同时也保持对于上一版本良好的兼容性，苹果在SwiftUI2.0中添加了@StateObject。顾名思义，它是@State的引用类型版本。

在WWDC的视频中，苹果明确的表明@StateObject是被创建他的View所持有的，也就是说，实例的生命周期是完全可控的，是同创建它的View的生命周期一样的。

**@StateObject 和 @ObservedObject 的区别就是实例是否被创建其的View所持有，其生命周期是否完全可控。**

## 通过代码了解不同 ##

我通过下面的代码来详细阐述一下 @StateObject 和 @ObservedObject的不同表现。

**准备工作：**

```swift
class StateObjectClass:ObservableObject{
    let type:String
    let id:Int
    @Published var count = 0
    init(type:String){
        self.type = type
        self.id = Int.random(in: 0...1000)
        print("type:\(type) id:\(id) init")
    }
    deinit {
        print("type:\(type) id:\(id) deinit")
    }
}

struct CountViewState:View{
    @StateObject var state = StateObjectClass(type:"StateObject")
    var body: some View{
        VStack{
            Text("@StateObject count :\(state.count)")
            Button("+1"){
                state.count += 1
            }
        }
    }
}

struct CountViewObserved:View{
    @ObservedObject var state = StateObjectClass(type:"Observed")
    var body: some View{
        VStack{
            Text("@Observed count :\(state.count)")
            Button("+1"){
                state.count += 1
            }
        }
    }
}
```

StateObjectClass将在其被创建和销毁时通过type 和 id 告知我们它是被那种方法创建的，以及具体哪个实例被销毁了。

CountViewState和CountViewObserved唯一的不同是创建实例使用的属性包装器不同。

**测试1：**

```swift
struct Test1: View {
    @State var count = 0
    var body: some View {
        VStack{
            Text("刷新CounterView计数 :\(count)")
            Button("刷新"){
                count += 1
            }
            
            CountViewState()
                .padding()
            
            CountViewObserved()
                .padding()
            
        }
    }
}
```

在测试1中，当进点击+1按钮时，无论是@StateObject或是@ObservedObject其都表现出一致的状态，两个View都可以正常的显示当前按钮的点击次数，不过当点击刷新按钮时，CountViewState中的数值仍然正常，不过CountViewObserved中的计数值被清零了。从调试信息可以看出，当点击刷新时，CountViewObserved中的实例被重新创建了，并销毁了之前的实例（CountViewObserved视图并没有被重新创建，仅是重新求了body的值）。

```swift
type:Observed id:443 init
type:Observed id:103 deinit
```

在这个测试中，@ObservedObject创建的实例的生命周期短于当前View。

**测试2:**

```swift
struct Test2: View {
    @State var count = 0
    var body: some View {
        NavigationView{
            List{
                NavigationLink("@StateObject", destination: CountViewState())
                NavigationLink("@ObservedObject", destination: CountViewObserved())
            }
        }
    }
}
```

测试2中，点击link进入对应的View后通过点击+1进行计数，然后返回父视图。当再次进入link后，@StateObject对应的视图中计数清零（由于返回父视图，再次进入时会重新创建视图，所以会重新创建实例），不过@ObservedObject对应的视图中计数是不清零的。

在这个测试中，@ObservedObject创建的实例生命周期长于当前的View。

**测试3:**

```swift
struct Test3: View {
    @State private var showStateObjectSheet = false
    @State private var showObservedObjectSheet = false
    var body: some View {
        List{
            Button("Show StateObject Sheet"){
                showStateObjectSheet.toggle()
            }
            .sheet(isPresented: $showStateObjectSheet) {
                CountViewState()
            }
            Button("Show ObservedObject Sheet"){
                showObservedObjectSheet.toggle()
            }
            .sheet(isPresented: $showObservedObjectSheet) {
                CountViewObserved()
            }   
        }
    }
}
```

测试3中点击按钮，在sheet中点击+1,当再次进入sheet后，无论是@StateObject还是@ObservedObject对应的View中的计数都被清零。

在这个测试中，@ObservedObject创建的实例生命周期和View是一致的。

**三段代码，三种结果，这也就是为什么苹果要新增@StateObject的原因——让开发者可以明确地了解并掌握实例的生命周期，消除不确定性！**

## ObservedObject是否还有存在的必要？ ##

对我个人而言，基本失去了使用其的理由（可用于绑定父视图传递的@StateObject）。

尽管或许上面例子的某种特性可能让你觉得ObservedObject可以完成某些特殊需求（比如测试2），但我们无法保证苹果在之后不改变ObservedObject的运行机理，从而改变当前的结果。

我个人还是更推荐将来都使用@StateObject来消除代码运行的不确定性。

通过下述代码，使用@StateObject同样可以得到测试2中ObservedObject的运行效果。

```swift
struct Test4: View {
    @State private var showStateObjectSheet = false
    @StateObject var state = StateObjectClass(type: "stateObject")
    var body: some View {
        List{
            Button("Show StateObject1 Sheet"){
                showStateObjectSheet.toggle()
            }
            .sheet(isPresented: $showStateObjectSheet) {
                CountViewState1(state: state)
            }
        }
    }
}

struct CountViewState1:View{
    @ObservedObject var state:StateObjectClass
    var body: some View{
        VStack{
            Text("@StateObject count :\(state.count)")
            Button("+1"){
                state.count += 1
            }
        }
    }
}
```

## Next ##

苹果使用@StateObject一方面修复了之前的隐患，同时通过SwiftUI2.0众多新特性的引入，进一步完善了Data Flow的实现手段。在下一篇文章《SwiftUI2.0 —— 100% SwiftUI app》中，我们来进一步探讨。
