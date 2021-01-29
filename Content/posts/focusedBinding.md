---
date: 2020-07-05 12:00
description: 在苹果WWDC20中视频中出现了下面的代码，介绍了一个新的属性包装器@FocusedBinding。由于仍处于测试阶段，当前的代码并不能被正确的执行。@FocusedBinding的资料苹果披露的也很少，网上也没有相关的信息。出于个人兴趣，我对它进行了简单的研究。尽管@FocusedBinding在目前Xcode Version 12.0 beta 2 (12A6163b)的版本上运行还有很多问题，但我基本上对其有了一定的了解。
tags: SwiftUI
title: @FocusedBinding 浅谈
---

> 在苹果WWDC20中视频中出现了下面的代码，介绍了一个新的属性包装器@FocusedBinding。由于仍处于测试阶段，当前的代码并不能被正确的执行。@FocusedBinding的资料苹果披露的也很少，网上也没有相关的信息。出于个人兴趣，我对它进行了简单的研究。尽管@FocusedBinding在目前Xcode Version 12.0 beta 2 (12A6163b)的版本上运行还有很多问题，但我基本上对其有了一定的了解。

```swift
struct BookCommands: Commands {
 @FocusedBinding(\.selectedBook) private var selectedBook: Book?
  var body: some Commands {
    CommandMenu("Book") {
        Section {
            Button("Update Progress...", action: updateProgress)
                .keyboardShortcut("u")
            Button("Mark Completed", action: markCompleted)
                .keyboardShortcut("C")
        }
        .disabled(selectedBook == nil)
    }
  }

   private func updateProgress() {
       selectedBook?.updateProgress()
   }
   private func markCompleted() {
       selectedBook?.markCompleted()
   }
}
```

## 用途 ##

**在任意视图（View）之间数据共享、修改、绑定操作。**

在SwiftUI1.0中，我们可以使用EnvironmentKey向子视图传递数据，使用PreferenceKey向父视图传递数据。如果我们想在不在同一视图树上的两个平行视图间进行数据传递的话，通常需要使用Single of truth或者通过NotificationCenter来进行。

在SwiftUI2.0中，苹果引入了@FocusedBinding和@FocusedValue来解决这个问题。通过定义FocusedValueKey，我们可以在任意的视图之间，无需通过Single of truth，便可以直接进行数据共享、修改、绑定。

在[SwiftUI2.0 —— Commands（macOS菜单）](https://zhuanlan.zhihu.com/p/152127847)这篇文章中，我们通过了Single of truth的方式，在App这个层级，使Commnads可以同其他视图进行数据共享。通过WWDC提供的例子，我们可以看出，苹果希望能够提供一种其他的解决方案，完成上述的功能。同样，这种方案也使我们拥有了可以在任意视图（无论是否在同一颗树上，是否有联系）之间进行数据交换。

## 使用方法 ##

其基本的使用方式和Environment很类似，都需要首先定义指定的Key

```swift
struct FocusedMessageKey:FocusedValueKey{
    //同EnvironmentKey不同，FocusedValueKey没有缺省值，且必须是一个可选值。为了下面的演示，在这里我们将数据类型设置为Binding<String>,可以设置为任意值类型数据
    typealias Value = Binding<String>
}

extension FocusedValues{
    
    var message:Binding<String>?{
        get{self[FocusedMessageKey.self]}
        set{self[FocusedMessageKey.self] = newValue}
    }
}
```

由于可以使用在任意视图，所以数据无需注入。和EnvironmentKey不同（只在当前注入的视图树之下有效），数据在全域有效。

```swift
struct ShowView:View{
    //调用方式同@Environment几乎一致,使用@FocusedValue或@FocusedBinding需不同的引用方式
    @FocusedValue(\.message) var focusedMessage
    //@FocusedBinding(\.message) var focusedMessage1
    var body: some View{
        VStack{
        Text("focused:\(focusedMessage?.wrappedValue ?? "")")
        //Text("focused:\(focusedMessage1 ?? "")")
        }
    }
}
```

在另一视图对该FocusedValueKey数据进行修改。

```swift
struct InputView1:View{
    @State private var text = ""
    var body: some View{
        VStack{
        TextField("input1:",text:$text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            //使message和text同步
            .focusedValue(\.message, $text)
        }
    }
}
```

可以在多个视图对同一FocusedValueKey进行修改

```swift
struct InputView2:View{
    @State private var text = ""
    var body:some View{
        TextField("input2:",text:$text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focusedValue(\.message, $text)
    }
}
```

最后组装在一起

```swift
struct RootView: View {
    var body: some View {
        VStack{
            //三个视图是平行关系，在之前使用Environment或者Preference都无法在这三个视图间进行数据传递、共享
            InputView1()
            InputView2()
            ShowView()
        }
        .padding(.all, 20)
        .frame(maxWidth:.infinity, maxHeight: .infinity)
    }
}
```

<video src="http://cdn.fatbobman.com/focusebinding-video.mov" controls="controls">您的浏览器不支持播放该视频！</video>

目前在iOS下无法获取FocusedValueKey数值，文档中标识是支持iOS的，应该在未来会解决

## 如何用，怎么用？ ##

FoccusedBinding的引入，进一步完善了SwiftUI不同视图中数据操作的功能。不过个人建议还是不要滥用此功能。

由于我们可以在任意视图中修改key中的值，一旦滥用，很可能再度陷入代码难以管理的窘境。

对于一些功能很简单，无需使用MVVM逻辑的代码，或者Single of truth过于臃肿（[ObservableObject研究——想说爱你不容易](/posts/observableObject-study/)），可能导致app响应问题的代码，可以考虑使用上述的方案。
