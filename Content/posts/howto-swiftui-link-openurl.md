---
date: 2020-07-10 13:00
description: SwiftUI2.0提供了原生的打开URL scheme的功能，我们可以十分方便的在代码中调用其他的app。
tags: SwiftUI,HowTo
title: HowTo —— SwiftUI2.0 使用Link或openURL打开URL scheme
---

> SwiftUI2.0提供了原生的打开URL scheme的功能，我们可以十分方便的在代码中调用其他的app。

## Link ##

类似于 NavigationLink ,直接打开URL scheme对应的app

```swift
Link("openURL",destination:safariUrl)
```

## openURL ##

本次在SwiftUI2.0中，苹果提供了若干个通过Environment注入的调用系统操作的方法。比如 exportFiles,importFiles,openURL等。

```swift
@Environment(\.openURL) var openURL
openURL.callAsFunction(url)
```

## 代码范例 ##

```swift
struct URLTest: View {
    @Environment(\.openURL) var openURL
    let safariUrl = URL(string:"http://www.apple.com")!
    let mailUrl = URL(string:"mailto:foo@example.com?cc=bar@example.com&subject=Hello%20Wrold&body=Testing!")!
    let phoneURl = URL(string:"tel:12345678")!
    
    var body: some View {
        List{
            Link("使用safari打开网页",destination:safariUrl)
            Button("发送邮件"){
                openURL.callAsFunction(mailUrl){ result in
                    print(result)
                }
            }
            Link(destination: phoneURl){
                Label("拨打电话",systemImage:"phone.circle")
            }
        }
    }
}
```

> 模拟器仅支持极少数的URL，最好使用真机测试
> [苹果官方提供的一些URL scheme](https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/PhoneLinks/PhoneLinks.html#//apple_ref/doc/uid/TP40007899-CH6-SW1)

<video src="http://cdn.fatbobman.com/howto-swiftui-openurl-video.mp4" controls = "controls">你的浏览器不支持本视频</video>
