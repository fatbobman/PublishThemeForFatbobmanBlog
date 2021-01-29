---
date: 2020-08-24 12:00
description: 在SwiftUI中使用List可以非常方便快速的制作各种列表.List其实就是对UITableView进行的封装.
tags: SwiftUI
title: 聊一下SwiftUI中的List和ForEach
---

在SwiftUI中使用List可以非常方便快速的制作各种列表.List其实就是对UITableView进行的封装(更多List的具体用法请参阅[List基本用法](https://zhuanlan.zhihu.com/p/110749923)).

在List中添加动态内容,我们可以使用两种方式

### 直接使用List自己提供的动态内容构造方法 ###

```swift
  List(0..<100){ i in
    Text("id:\(id)")
  }
```

### 在List中使用ForEach ###

```swift
  List{
    ForEach(0..<100){ i in
      Text("id:\(id)")
    }
  }
```

在碰到我最近出现的问题之前,我一直以为上述两种用法除了极个别的区别外,基本没有什么不同.

当时知道的区别:

### 使用ForEach可以在同一List中,添加多个动态源,且可添加静态内容 ###

```swift
  List{
    ForEach(items,id:\.self){ item in
      Text(item)
    }
    Text("其他内容")
    ForEach(0..<10){ i in
      Text("id:\(i)")
    }
  }
```

### 使用ForEach对于动态内容可以控制版式 ###

```swift
  List{
    ForEach(0..<10){ i in
      Rectangle()
        .listRowInsets(EdgeInsets()) //可以控制边界insets
    }
  }
  
  List(0..<10){ i in
     Rectangle()
        .listRowInsets(EdgeInsets()) 
        // 不可以控制边界insets.   .listRowInsets(EdgeInsets())在List中只对静态内容有效
  }
```

基于以上的区别,我在大多数的时候均采用ForEach在List中装填列表内容,并且都取得了预想的效果.

但是在最近我在开发一个类似于iOS邮件app的列表时发生了让我无语的状态——列表卡顿到完全无法忍耐.

通过下面的视频可以看到让我痛苦的app表现

<video src="http://cdn.fatbobman.com/swiftui-list-foreach-10ForEach.mp4" controls = "controls"></video>

只有十条记录时的状态.非常丝滑

```swift
 List{
    ForEach(0..<10000){ i in
        Cell(id: i)
          .listRowInsets(EdgeInsets())
          .swipeCell(cellPosition: .both, leftSlot: slot1, rightSlot: slot1)
        }
    }
```

<video src="http://cdn.fatbobman.com/swiftui-list-foreach-10000MyList.mp4" controls = "controls"></video>
10000条记录的样子

在10条记录时一切都很完美,但当记录设置为10000条时,完全卡成了ppt的状态.尤其是View初始化便占有了大量的时间.

起初我认为可能是我写的滑动菜单的问题,但在自己检查代码后排出了这个选项.为了更好的了解在List中Cell的生命周期状态,写了下面的测试代码.

```swift
    struct Cell:View{
        let id:Int
        @StateObject var t = Test()
        init(id:Int){
            self.id = id
            print("init:\(id)")
        }
        var body: some View{
            Rectangle()
                .fill(Color.blue)
                .overlay(
                    Text("id:\(id)")
                )
                .onAppear{
                    t.id = id
                }
        }
        
        class Test:ObservableObject{
            var id:Int = 0{
                didSet{
                    print("get value \(id)")
                }
            }
            init(){
                print("init object")
            }
            deinit {
                print("deinit:\(id)")
            }
        }
    }
    
    class Store:ObservableObject{
        @Published var currentID:Int = 0
    }
```

执行后,发现了一个奇怪的现象:**在List中,如果用ForEach处理数据源,所有的数据源的View竟然都要在List创建时进行初始化,这完全违背了tableView的本来意图**.

将上面的代码的数据源切换到List的方式进行测试

```swift
 List(0..<10000){ i in
        Cell(id: i)
          .listRowInsets(EdgeInsets())
          .swipeCell(cellPosition: .both, leftSlot: slot1, rightSlot: slot1)
    }
```

<video src="http://cdn.fatbobman.com/swiftui-list-foreach-10000withoutForEach.mp4" controls = "controls"></video>

熟悉的丝滑又回来了.

**ForEach要预先处理所有数据,提前准备View.并且初始化后,并不自动释放这些View(即使不可见)!**具体可以使用上面的测试代码通过Debug来分析.

不流畅的原因已经找到了,不过由于List处理的数据源并不能设置listRowInsets,尤其在iOS14下,苹果非常奇怪的屏蔽了不少通过UITableView来设置List的属性的途径,所以为了既能保证性能,又能保证显示需求,只好通过自己包装UITableView来同时满足上述两个条件.

好在我一直使用[SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)这个第三方库,节省了自己写封装代码的时间.将代码做了进一步调整,当前的问题得以解决.

```swift
 CocoaList(item){ i in
           Cell(id: i)
           .frame(height:100)
           .listRowInsets(EdgeInsets())
           .swipeCell(cellPosition: .both, leftSlot: slot1, rightSlot: slot1)
       }.edgesIgnoringSafeArea(.all)
```

<video src="http://cdn.fatbobman.com/swiftui-list-foreach-10000MyList.mp4" controls = "controls"></video>

通过这次碰到的问题,我知道了可以在什么情况下使用ForEach.通过这篇文章记录下来,希望其他人少走这样的弯路.

**后记:**

我已经向苹果反馈了这个问题,希望他们能够进行调整吧(最近苹果对于开发者的feedback回应还是挺及时的,Xcode12发布后,我提交了5个feedback,已经有4个获得了反馈,3个在最新版得到了解决).

**遗憾:**

目前的解决方案使我失去了使用ScrollViewReader的机会.
