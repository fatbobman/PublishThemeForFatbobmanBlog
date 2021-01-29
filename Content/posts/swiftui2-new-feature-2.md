---
date: 2020-07-08 14:00
description: 在上篇文章中我们简单了解了App、Scene，以及几个内置Scene的应用。在本文中，我们着重探讨在SwiftUI2.0新的代码结构下如果更高效的组织Data Flow。
tags: SwiftUI
title: SwiftUI2.0 —— App、Scene、新的代码结构（二）
---

> 在[上篇文章](/posts/swiftui2-new-feature-1/)中我们简单了解了App、Scene，以及几个内置Scene的应用。在本文中，我们着重探讨在SwiftUI2.0新的代码结构下如果更高效的组织Data Flow。

## 新特性 ##

### @AppStorage ###

AppStorage是苹果官方提供的用于操作UserDefault的属性包装器。这个功能在Swift提供了propertyWrapper特性后，已经有众多的开发者编写了类似的代码。功能上没有任何特别之处，不过名称对应了新的App协议，让人更容易了解其可适用的周期。

* 数据可持久化，app退出后数据仍保留
* 仅包装了UserDefault，数据可以UserDefault正常读取
* 可保存的数据类型同UserDefault，不适合保存复杂类型数据
* 在app的任意View层级都可适用，不过在app层使用并不起作用（不报错）

```swift
@main
struct AppStorageTest: App {
    //不报错，不过不起作用
    //@AppStorage("count") var count = 0
    var body: some Scene {
        WindowGroup {
            RootView()
            CountView()
        }
    }
}

struct RootView: View {
    @AppStorage("count") var count = 0
    var body: some View {
        List{
            Button("+1"){
                count += 1
            }
        }
    }
}

struct CountView:View{
    @AppStorage("count") var count = 0
    var body: some View{
        Text("Count:\(count)")
    }
}

```

### @SceneStorage ###

使用方法同@AppStorage十分类似，不过其作用域仅限于当前Scene。

* 数据作用域仅限于Scene中
* 生命周期同Scene一致，当前在PadOS下，如果强制退出一个两分屏显示的app,系统在下次打开app时有时会保留上次的Scene信息。不过，如果如果单独退出一个Scene，数据则失效
* 支持的类型基本等同于@AppStorage，适合保存轻量数据
* 比较适合保存基于Scene的特质信息，比如TabView的选择，独立布局等数据

```swift
@main
struct NewAllApp: App {
    var body: some Scene {
        WindowGroup{
            ContentView1()
        }
    }
}

struct ContentView:View{
    @SceneStorage("tabSeleted") var selection = 2
    var body:some View{
        TabView(selection:$selection){
            Text("1").tabItem { Text("1") }.tag(1)
            Text("2").tabItem { Text("2") }.tag(2)
            Text("3").tabItem { Text("3") }.tag(3)
        }
    }
}
```

![abc](http://cdn.fatbobman.com/swiftui2-new-feature-2-sceneStorage.png)

>***上述代码在PadOS下运行正常，不过在macOS下程序会报错。估计应该是bug***

## Data Flow ##

### 手段 ###

苹果在SwiftUI2.0中添加了@AppStorage @SceneStorage @StateObject 等新的属性包装器，我根据自己的理解对目前SwiftUI提供的部分属性包装器做了如下总结：

![propertyWrapperSheet](http://cdn.fatbobman.com/swiftui2-new-feature-2-propertyWrapperSheet.png)

经过此次升级后，SwiftUI已经大大的完善了各个层级数据的生命周期管理，对不同的类型、不同的场合、不同的用途都提供了解决方案，为编写符合SwiftUI的Data Flow提供了便利，我们可以根据自己的需要选择适合的Source of truth手段。

想了解其中的更多细节，可以参看我的其他文章：

[@State 研究](/posts/swiftUI-state/)

[@StateObject研究](/posts/stateobject/)

[ObservableObject研究——想说爱你不容易](/posts/observableObject-study/)

### 变化 ###

在SwiftUI1.0中，我们通常会在AppDelegate中创建需要生命周期与app一致的数据（比如CoreData的Container），在SceneDelegate中创建Store之类的数据源，并通过.environmentObject注入。不过随着SwiftUI2.0在程序入口方面的变化，以及采取的全新Delegate响应方式，我们可以通过更简洁、清晰的代码完成上述工作。

```swift
@main
struct NewAllApp: App {
    @StateObject var store = Store()
    var body: some Scene {
        WindowGroup{
            ContentView()
                .environmentObject(store)
        }
    }
}

class Store:ObservableObject{
    @Published var count = 0
}
```

上述例子中，将

```swift
@StateObject var store = Store()
```

换成

```swift
let store = Store()
```

目前来说是一样的。

*虽然目前SceneBuilder、CommandBuilder对Dynamic update和逻辑判断尚不支持，我相信应该在不久的将来，或许我们就可以使用类似下面的代码来完成很多有趣的工作了,**当前代码无法执行***

```swift
@main
struct NewAllApp: App {
    @StateObject var store = Store()
    @SceneBuilder var body: some Scene {
        //@SceneBuilder目前不支持判断，不过将来应该会加上
        if store.scene == 0 {
        WindowGroup{
            ContentView1()
                .environmentObject(store)
        }
        .onChange(of: store.number){ value in
            print(value)
        }
        .commands{
            CommandMenu("DynamicButton"){
                //目前无法动态切换内容，怀疑是bug，已反馈
                switch store.number{
                case 0:
                    Button("0"){}
                case 1:
                    Button("1"){}
                default:
                    Button("other"){}
                }
            }
        }
        }
        else {
         DocumentGroup(newDocment:TextFile()){ file in
              TextEditorView(document:file.$document)
         }
        }
        
        Settings{
            VStack{
               //可正常变换
                Text("\(store.number)")
                    .padding(.all, 50)
            }
        }

    }
}


struct ContentView1:View{
    @EnvironmentObject var store:Store
    var body:some View{
        VStack{
        Picker("select",selection:$store.number){
            Text("0").tag(0)
            Text("1").tag(1)
            Text("2").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        }
    }
}

class Store:ObservableObject{
    @Published var number = 0
    @Published var scene = 0
}

```

### 跨平台代码 ###

在[上篇文章](https://zhuanlan.zhihu.com/p/152624613)我们介绍了新的@UIApplicationDelegateAdaptor的使用方法，我们也可以直接创建一个支持Delegate的store。

```swift
import SwiftUI

class Store:NSObject,ObservableObject{
    @Published var count = 0
}

#if os(iOS)
extension Store:UIApplicationDelegate{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("launch")
        return true
    }
}
#endif

@main
struct AllInOneApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(Store.self) var store
    #else
    @StateObject var store = Store()
    #endif
    
    @Environment(\.scenePhase) var phase

    @SceneBuilder var body: some Scene {
            WindowGroup {
                RootView()
                    .environmentObject(store)
            }
            .onChange(of: phase){phase in
                switch phase{
                case .active:
                    print("active")
                case .inactive:
                    print("inactive")
                case .background:
                    print("background")
                @unknown default:
                    print("for future")
                }

            }
      
        #if os(macOS)
        Settings{
            Text("偏好设置").padding(.all, 50)
        }
        #endif
    }
}
```

## 总结 ##

在[ObservableObject研究——想说爱你不容易](/posts/observableObject-study/)中，我们探讨过SwiftUI更倾向于我们不要创建一个沉重的Singel source of truth,而是将每个功能模块作为独立的状态机（一起组合成一个大的状态app），使用能够对生命周期和作用域更精确可控的手段创建区域性的source of truth。

从SwiftUI第一个版本升级的内容来看，目前SwiftUI仍是这样的思路。
