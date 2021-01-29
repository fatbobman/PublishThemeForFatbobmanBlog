---
date: 2020-07-10 14:00
description: SwiftUI2.0为了实现更好的多平台支持同时需要兼顾1.0版本代码兼容性，提供了一些与已有控件功能上类似但名称和用法全新的控件。比如ToolBar, navigationTitle等。Toolbar可以实现navigationbarItems的全部功能，并新增了在多平台下的适配。采用了全新的语法，代码更易阅读。
tags: SwiftUI,HowTo
title: HowTo —— SwiftUI2.0 使用ToolBar替代navigationbarItems
---


> SwiftUI2.0为了实现更好的多平台支持同时需要兼顾1.0版本代码兼容性，提供了一些与已有控件功能上类似但名称和用法全新的控件。比如ToolBar, navigationTitle等。Toolbar可以实现navigationbarItems的全部功能，并新增了在多平台下的适配。采用了全新的语法，代码更易阅读。
>
> **在当前的Xcode Version 12.0 beta 2 (12A6163b)版本下，ToolBar在macOS下仍然有非常多的问题。**

## 基本用法 ##

```swift
struct ToolBarTest: View {
    var body: some View {
      NavigationView{
        Text("ToolBar 演示")
            .toolbar{
                ToolbarItem(placement:.automatic){
                    HStack(spacing:20){
                        Button(action:{print("wave")}){
                            Image(systemName: "waveform.path.badge.plus")
                                .foregroundColor(.purple)
                                .scaleEffect(1.5, anchor: .center)
                        }
                        
                    }
                }
                //placement设置放置位置，ToolBarItem中的View解析不会完全和预期一致，不知道是特别限制还是bug.比如说无法显示多彩符号，无法使用Spacer等。
                ToolbarItem(placement: .bottomBar){
                    HStack(spacing:100){
                        Button(action:{print("lt")}){
                            Image(systemName: "lt.rectangle.roundedtop.fill")
                                .foregroundColor(.purple)
                                .scaleEffect(1.5, anchor: .center)
                        }
                        
                        Button(action:{print("rt")}){
                            Image(systemName: "rt.rectangle.roundedtop.fill")
                                .foregroundColor(.purple)
                                .scaleEffect(1.5, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}
```

![截屏2020-07-10 上午9.01.52](http://cdn.fatbobman.com/howto-swiftui-toolbar-toolbar1.png width=300)

## 多平台适配 ##

为了能够更好的适配多平台，placment提供了automatic这样的多平台自适应选项。placement有些值全平台可用，有些只支持部分平台，还有一部分的可在多平台运行不过只能在部分平台正确显示。

```swift
import SwiftUI

struct ToolBarTest: View {
    @State var placementSelection:Placement = .automatic
    @State var placement:ToolbarItemPlacement = .automatic
    @State var show = true
    var body: some View {
        NavigationView{
            VStack{
                Picker("placement:",selection:$placementSelection){
                    ForEach(Placement.allCases,id:\.self){ placement in
                        Text(placement.rawValue)
                            .tag(placement)
                    }
                }
                .labelsHidden()
                .padding(.all, 10)
                .onChange(of: placementSelection) { value in
                    switch value{
                    case .automatic:
                        placement = .automatic
                    case .principal:
                        placement = .principal //iOS不显示
                    case .navigation:
                        placement = .navigation
                    case .primaryAction:
                        placement = .primaryAction
                    case .status:
                        placement = .status //iOS不显示
                    case .confirmationAction:
                        placement = .confirmationAction //iOS不显示
                    case .cancellationAction:
                        placement = .cancellationAction //iOS不显示
                    case .destructiveAction:
                        placement = .destructiveAction //iOS不显示
                    #if os(iOS)
                    case .bottomBar:
                        placement = .bottomBar
                    //不知道为什么有bug,设置后不显示
                    //ToolbarItem(placement:.bottomBar)可以显示
                    case .navigationBarLeading:
                        placement = .navigationBarLeading
                    case .navigationBarTrailing:
                        placement = .navigationBarTrailing
                    #endif
                    }
                }
                //在macOS下如果需要显式设置是否显示ToolBar,需要设置id,iOS下可以不用设置
                //当前在macOS下,如果不显式关闭可能导致不同View的ToolBar混合到了一起,或者重复出现.不知道是否是bug还是设计逻辑
                .toolbar(id:"ToolBar") {
                    ToolbarItem(id:"1",placement:placement,showsByDefault:show) {
                        Button("确定"){
                            
                        }
                    }
                }
                .navigationTitle("Toolbar演示")
                
                #if os(macOS)
                Toggle("显示ToolBar",isOn:$show)
                Spacer()
                #endif
            } .frame(maxWidth:.infinity,maxHeight: .infinity)
        }
        
    }
}

enum Placement:String,CaseIterable{
    case automatic,principal,navigation
    case primaryAction,status,confirmationAction
    case cancellationAction,destructiveAction
    #if os(iOS)
    case navigationBarLeading,navigationBarTrailing,bottomBar
    #endif
}
```

<video src="http://cdn.fatbobman.com/howto-swiftui-toolbar-video.mp4" controls = "controls">你的浏览器不支持本视频</video>

> macOS下不同placement的演示

**遗憾**

macOS目前bug较多，ToolBarItem对于View的解析还不完整，ToolBarContentBuilder不支持逻辑判断。
