---
date: 2020-07-09 13:05
description: SwiftUI2.0中新增了Label控件，方便我们添加由图片和文字组成的标签.
tags: SwiftUI,HowTo
title: HowTo —— SwiftUI2.0如何使用Label
---

> SwiftUI2.0中新增了Label控件，方便我们添加由图片和文字组成的标签

## 基本用法 ##

```swift
Label("Hello World",systemImage:"person.badge.plus")
```

![image-20200709174029886](http://cdn.fatbobman.com/howto-swiftui-label1.png)

## 支持自定义标签风格 ##

```swift
import SwiftUI

struct LabelTest: View {
    var body: some View {
        List(LabelItem.labels(),id:\.id){ label in
            Label(label.title,systemImage:label.image)
                .foregroundColor(.blue)
                .labelStyle(MyLabelStyle(color:label.color))
        }
    }
}

struct MyLabelStyle:LabelStyle{
    let color:Color
    func makeBody(configuration: Self.Configuration) -> some View{
       HStack{
            configuration.icon //View,不能精细控制
                .font(.title)
                .foregroundColor(color) //颜色是叠加上去的，并不能准确显示
            configuration.title  //View,不能精细控制
                .foregroundColor(.blue)
            Spacer()
        }.padding(.all, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow)
        )
    }
}

struct LabelItem:Identifiable{
    let id = UUID()
    let title:String
    let image:String
    let color:Color
    static func labels() -> [LabelItem] {
        return [
       LabelItem(title: "Label1", image: "pencil.tip.crop.circle.badge.plus", color: .red),
       LabelItem(title: "df", image: "person.crop.circle.fill.badge.plus", color: .blue),
        ]
    }
}

```

![image-20200709175339008](http://cdn.fatbobman.com/howto-swiftui-label2.png)

## 使用自己的Label控件，更多控制力 ##

Label能够提高开发效率，不过并不能精细控制，下面代码使用自定义MyLabel，可以支持SF2.0提供的彩色符号。

```swift
import SwiftUI

struct LabelTest: View {
    @State var multiColor = true
    var body: some View {
        VStack{
        Toggle("彩色符号", isOn: $multiColor).padding(.horizontal, 20)
        List(LabelItem.labels(),id:\.id){ label in         
              MyLabel(title:label.title,
                      systemImage:label.image,
                      color:label.color,
                      multiColor:multiColor)
        }
        }
    }
}

struct LabelItem:Identifiable{
    let id = UUID()
    let title:String
    let image:String
    let color:Color
    static func labels() -> [LabelItem] {
        return [
       LabelItem(title: "Label1", image: "pencil.tip.crop.circle.badge.plus", color: .red),
       LabelItem(title: "df", image: "person.crop.circle.fill.badge.plus", color: .blue),
        ]
    }
}

struct MyLabel:View{
    let title:String
    let systemImage:String
    let color:Color
    let multiColor:Bool
    
    var body: some View{
        HStack{
            Image(systemName: systemImage)
                .renderingMode(multiColor ? .original : .template)
                .foregroundColor(multiColor ? .clear : color)
            Text(title)
                .bold()
                .foregroundColor(.blue)
            Spacer()
        }
        .padding(.all, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow)
        )
    }
}

```

![image-20200709180353538](http://cdn.fatbobman.com/howto-swiftui-label3.png)
