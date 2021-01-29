---
date: 2020-10-27 12:00
description: 本文介绍了其中几个在健康笔记开发过程中使用的第三方的开源库
tags: SwiftUI
title: 介绍几个我在开发健康笔记2用到的Swift或SwiftUI第三方库
---


## [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX) ##

> SwiftUIX试图弥补仍处于新生阶段的SwiftUI框架的空白，提供了广泛的组件，扩展和实用程序套件来补充标准库。 迄今为止，该项目是缺少的UIKit / AppKit功能的最完整的移植，力求使其以大多数类似于Apple的方式交付。
> 这个项目的目标是补充SwiftUI标准库，提供数百种扩展和视图，使开发人员可以轻松地通过SwiftUI的革命来构建应用程序。

提供了非常多的苹果本应提供但没有提供的功能扩展。项目的发起者非常年轻，但mac的开发经验十分丰富。到目前为止一直保持的较高的更新频率和维护状态。这个库同时支持UIKit和Appkit，对于需要做苹果生态全平台的用户十分友好。由于目前SwiftUI的List和LazyVStack的问题还很多，他自己在开发中也深受其苦，前天在交流中，他已经决定重做CocoaList功能，尤其提高对Fetchrequest的支持。

对于进行SwiftUI开发的朋友，它是十分值得推荐的。

目前的问题是文档太少。不过对我来说也未尝不是一个好事。在研究它的用法过程中，给了我更多的机会阅读并学习它的代码，对SwiftUI，UIkit等有了更多的认识和了解。

## [Charts](https://github.com/danielgindi/Charts) ##

> denielgindi对著名的安卓图表库 MPAndroidChart的Swift移植。是目前不多的纯Swift解决方案。它的优势也是同时支持UIKit和Appkit，同时提供了不错的Demo社区活跃度。

不过他的开发者好像不打算在3.x版本上在增加太多的功能，非常多目前急需并且已有解决方案的功能并没有被当前版本接受。所以整体的视觉呈现还是比较传统的。社区上对于功能的讨论不少，但合并的极少，4.0的版本好像也已经开发了不短的时间了，不过进度好像也不是特别理想。

从效率上讲，Charts应该是非常合格的了。

[航歌](https://www.hangge.com) 上面有非常详细的中文使用教程，对我的学习帮助很大。

为了健康笔记开发的需要，我在当前3.6的版本上合并了两个社区上较为成熟的解决方案：

* 圆角Bar

```swift
  dataSet.roundedCorners = [.topLeft,.topRight]
```

* 渐变色Bar

```swift
  dataSet.drawBarGradientEnabled = true
              dataSet.colors = [UIColor(named: "barColor1")!, UIColor(named: "barColor1")!, UIColor(named: "barColor2")!]
              dataSet.gradientPositions = [0, 40, 100]
```

由于当前的Charts本身并不支持对于图表滚动后停止事件的响应，我自己为它增加了停止响应。

```swift
        //滚动终止时调用
        func chartScrollStop(_ chartView:ChartViewBase){
            print("stopped")
        }
```

修改后的代码[在此可以获得](https://github.com/fatbobman/Charts)。

## [Introspect](https://github.com/siteline/SwiftUI-Introspect) ##

> Introspect允许您获取SwiftUI视图的基础UIKit或AppKit元素。
> 例如，使用Introspect，您可以访问UITableView来修改分隔符，或访问UINavigationController来自定义选项卡栏。

有一个非常推荐的利器。目前官方对于SwiftUI中的控件提供的可控选项很少，如果想做一些深度定制的话，通常就是自己写代码来重新包装UIkit控件。不过introspect提供了一个非常巧妙的办法通过简单的注入方式便可以对SwiftUI控件做更多的调整。

比如：

只有当内容超出显示范围才进行滚动

```swift
ScrollView{
    ....
}
.introspectScrollView{ scrollView in
        crollView.isScrollEnabled = scrollView.contentSize.height > scrollView.frame.height
               }
```

显示TextField的clear按钮

```swift
TextField("note_noteName",text: $myState.noteName)
          .introspectTextField{ text in
             text.clearButtonMode = .whileEditing
           }
```

对于新的控件它本身还没提供具体支持的也可以方便的注入

修改SwiftUI2.0中新提供的TextEditor背景色

```swift
TextEditor(text: $text)
                .introspect(selector: TargetViewSelector.sibling){ textView in
                    textView.backgroundColor = .clear
                }
```

等等。类似的用法在我整个的开发中的使用频率是很高的。

## [SwiftDate](https://github.com/malcommac/SwiftDate) ##

> 使用Swift编写的时间日期处理库。同时支持苹果平台以及Linux。

它提供了非常详尽的文档，航哥上也有非常好的中文教程。

由于健康笔记需要对数据进行不少处理，尤其是需要将相同时间粒度的数据进行合并比较。SwiftDate提供的Region方案提供了完美的解决途径。

在SwiftDate中，我多数使用它提供的DateInRegion来处理日期。通过

```swift
SwiftDate.defaultRegion = region
```

我几乎无需关心日期的本地化问题。而且它也提供了部分的日期时间的本地化显示方案（但并不完美）。

一些使用举例：

除非用户在app中设定了特定的时区，否则使用当前设备的默认设置：

```swift
if let data = UserDefaults.standard.data(forKey: "dateRegion"),
           let region = try? JSONDecoder().decode(Region.self, from: data) {
            SwiftDate.defaultRegion = region
        }
        else {
            SwiftDate.defaultRegion = Region(calendar: Calendars.gregorian, zone: Zones.current, locale: Locales.current)
        }
```

判断某个日期和指定日期的天数差（本地时区）：

```swift
let startDate = DateInRegion(datas.first!.viewModel.date1).dateTruncated(at: [.hour,.minute,.second])!
duration = date.difference(in: .day, from: startDate) ?? 0
```

如果你的程序需要对日期进行频繁的处理或者有较多的本地化需求时，SwiftDate是非常好的选择！

## [SwiftUIOverlayContainer](https://github.com/fatbobman/SwiftUIOverlayContainer) ##

> SwiftUIOverlayContainer本身并不提供任何预置的视图样式，不过通过它，你有充分的自有度来实现自己需要的视图效果。OverlayContainer的主要目的在于帮助你完成动画、交互、样式定制等基础工作，使开发者能够将时间和精力仅需投入在视图本身的代码上。

这是我自己写的一个库，这次通过它实现的屏幕侧边滑动菜单。

本来它的用途主要不是做这个的，暂时使用它来完成侧向滑动菜单也是权宜之计，表现尚可。

## [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) ##

> ZIP Foundation是一个用于创建，读取和修改ZIP存档文件的库。
> 它是用Swift编写的，基于Apple的libcompression来实现高性能和高能效。

小巧、高效，使用便捷。健康笔记在数据导入导出时，使用它来完成zip文件的操作。

比如解压备份数据：

```swift
//打开沙盒读取权限
   _ = url.startAccessingSecurityScopedResource() 
//解压
   do {
      try FileManager.default.unzipItem(at: url, to: URL(fileURLWithPath: NSTemporaryDirectory()))
        }
        catch {
          
        }
```

## [MarkdownView](https://github.com/keitaoouchi/MarkdownView) ##

> 基于WKwebView实现的Markdown文件Viewer。对md的解析是通过调用js库来完成的。

由于SwiftUI的Text文本排版能力几乎为零，因此我选择使用md格式来保存app所需的一些文字显示，比如隐私政策等。

MarkdownView的渲染效率一般，但我的显示需求并不大，所以感觉不明显。但它的开发者对js文件进行了加扰处理，所以如果你想对其中它所调用的例如mardown-it进行更多配置的话，就几乎不可能了。

另外，通过UIViewRepresentable对其进行封装，在SwiftUI下是无法正确获取frame的尺寸的，从而无法正确显示。我对于UIkit所知甚少，只能做了最简单的修改，勉强让其可以在SwiftUI下完成所需要的功能。

修改后的版本可在[这里下载](https://github.com/fatbobman/MarkdownView)

另外，我在UIViewRepresentable包装中增加了一些简单的修改，使其可以方便的将md中的图片，替换成Bundle中的本地图片。

调用代码 [下载](https://github.com/fatbobman/ShareCode/blob/main/MarkDownView.swift)

## [ExcelExport](https://github.com/avielg/ExcelExport/blob/master/Sources/ExcelExport/ExcelExport.swift) ##

> 生成XSL文件的Swift代码。

这段代码有一段时间了，不过去年又做了更新，不过我感觉更新后的版本还不如之前的。但它的新版本不支持Date的字段导出，老版本导出的Date字段格式在Excel中也有问题。我合并了两个版本，并且让其在命名上对SwiftUI更加友好。

修改后的代码 [下载](https://github.com/fatbobman/ShareCode/blob/main/ExcelExport)

必须对日期做如下处理，日期字段才能被Excel顺利识别

```swift
 let date = DateInRegion(memo.viewModel.date).toFormat("yyyy-MM-dd")
 let time = DateInRegion(memo.viewModel.date).toFormat("HH:mm:ss.FFF")
 let dateCell = ExcelCell(date + "T" + time,type: .dateTime)
```

上述的库都被使用在 [健康笔记2.0](https://apps.apple.com/us/app/health-notes-2/id1534513553) 中。如想查看更多的演示，可以移步
