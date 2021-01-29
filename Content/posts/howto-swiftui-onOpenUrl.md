---
date: 2020-07-11 13:00
description: SwiftUI2.0由于可以采用新的代码架构（Life Cycle SwiftUI App）来组织app,因此提供了onOpenURL来处理Univeresal Links。不同于在AppDelegate或SceneDelegate中的解决方案，onOpenURL作为一个view modifier，你可以在任意View上注册你的app的URL处理机制。
tags: SwiftUI,HowTo
title: HowTo —— 使用onOpenURL处理Universal Links
---


> SwiftUI2.0由于可以采用新的代码架构（Life Cycle SwiftUI App）来组织app,因此提供了onOpenURL来处理Univeresal Links。不同于在AppDelegate或SceneDelegate中的解决方案，onOpenURL作为一个view modifier，你可以在任意View上注册你的app的URL处理机制。关于如何为自己的app创建URL Scheme，请参阅[苹果的官方文档](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app)。

## 基本用法 ##

```swift
VStack{
   Text("Hello World")
}
.onOpenURL{ url in
    //做点啥
}
```

## 示例代码 ##

首先在项目中设置URL

![URL](http://cdn.fatbobman.com/howto-swiftui-onOpenURL-URL.png)

```swift
import SwiftUI

struct ContentView: View {
    @State var tabSelection:TabSelection = .news
    @State var show = false
    var body: some View {
        TabView(selection:$tabSelection){
            Text("News")
                .tabItem {Image(systemName: "newspaper")}
                .tag(TabSelection.news)
            Text("Music")
                .tabItem {Image(systemName: "music.quarternote.3")}
                .tag(TabSelection.music)
            Text("Settings")
                .tabItem {Image(systemName: "dial.max")}
                .tag(TabSelection.settings)
        }
        .sheet(isPresented: $show) {
            Text("URL调用参数错误")
        }
        .onOpenURL { url in
            let selection = url.host
            switch selection{
            case "news":
                tabSelection = .news
            case "music":
                tabSelection = .music
            case "settings":
                tabSelection = .settings
            default:
                show = true
            }
        }
    }
}

enum TabSelection:Hashable{
    case news,music,settings
}
```

> macOS目前暂不支持，应该会在正式版本提供。

<video src="http://cdn.fatbobman.com/howto-swiftui-onOpenURL-video.mp4" controls = "controls">你的浏览器不支持本视频</video>

## 特别注意 ##

* onOpenURL只有在项目采用Swift App的方式管理Life Cycle才会响应

* 在代码中可以添加多个onOpenURL，注册在不同的View上，当采用URL访问时，每个闭包都会响应。这样可以针对不同的View做出各自需要的调整。
