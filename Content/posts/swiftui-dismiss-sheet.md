---
date: 2020-09-17 12:00
description: 在前面的两篇文章中，我们探讨了如何制作一个可以判断是否进行了修改的表单，以及如何统一管理app各个层级View的弹出Sheet。今天我们将他们合并在一起，完成整个项目的最终目的——在Sheet中制作一个可以实时响应的表单，并且sheet会感觉表单的情况响应取消手势。
tags: SwiftUI
title: 在SwiftUI中制作可以控制取消手势的Sheet
---


> 在前面的两篇文章中，我们探讨了如何制作一个可以判断是否进行了修改的表单，以及如何统一管理app各个层级View的弹出Sheet。今天我们将他们合并在一起，完成整个项目的最终目的——在Sheet中制作一个可以实时响应的表单，并且sheet会感觉表单的情况响应取消手势。

[在SwiftUI中,根据需求弹出不同的Sheet](/posts/swiftui-multiSheet/)

[如何在SwiftUI中创建一个实时响应的Form](/posts/swiftui-input-form/)

## 由来 ##

在之前Form的例子中，虽然我们可以根据表单是否进行了修改来对cancel、edit等做出不同的响应，但是我们并没有办法控制用户直接使用手势来取消sheet，为了不让用户绕过程序的判断检查，不得已使用了fullScreenCover来规避手势取消。不过在实际使用中，尽管全屏sheet提供了更多的屏幕可用空间，但还是会给使用者带来了操作逻辑不统一的体验。

在去年，我使用的解决方案是，屏蔽sheet的拖动手势。

```swift
 .highPriorityGesture(DragGesture())
```

这也是没有办法的办法。

后来，SwiftUI-lab中，Javier提出了他的解决方案[Dismiss Gesture for SwiftUI Modals](https://swiftui-lab.com/modal-dismiss-gesture/)。这个方案基本上实现了我想要的全部功能。不过这个方案看起来有些怪异。

1. 数据和sheet控制混合在一起
2. 对于sheet的控制过于繁琐，而且不直观

前段时间[mobilinked](https://gist.github.com/mobilinked/9b6086b3760bcf1e5432932dad0813c0)编写了一段用于控制sheet的代码，结构精巧，使用简单。

本文对于sheet的控制采用了mobilinked的基础代码，并针对Form的响应做出了对应的修改。

在进行下面的代码说明前，如果你还没有阅读前两篇文章的话，请阅读后再继续。

## 目标 ##

1. 表单对输入的内容进行实时检查（是否有错误，是否有空白项）
2. 表单将根据当前的状态决定是否允许sheet进行手势取消
3. 当用户进行手势取消时，如果表单已经进行了修改，需要用户二次确认是否取消

## 代码简介 ##

由于本文代码中多数部分同Form示例代码类似，所以仅简述一下新增及修改的部分。

SheetManager

```swift
public class AIOSheetManager:ObservableObject{
    @Published  var action:AllInOneSheetAction?
    var unlock:Bool = false //false时无法下滑dismiss,由form程序维护
    var type:AllInOneSheetType = .sheet //sheet or fullScreenCover
    var dismissControl:Bool = true //是否启动dismiss阻止开关,true启动阻止
    
    @Published var showSheet = false
    @Published var showFullCoverScreen = false

    var dismissed = PassthroughSubject<Bool,Never>()
    var dismissAction:(() -> Void)? = nil

    enum AllInOneSheetType{
        case fullScreenCover
        case sheet
    }
}
```

sheet控制代码

```swift
struct MbModalHackView: UIViewControllerRepresentable {
    let manager:AIOSheetManager

    func makeUIViewController(context: UIViewControllerRepresentableContext<MbModalHackView>) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<MbModalHackView>) {
        rootViewController(of: uiViewController).presentationController?.delegate = context.coordinator
    }

    private func rootViewController(of uiViewController: UIViewController) -> UIViewController {
        if let parent = uiViewController.parent {
            return rootViewController(of: parent)
        }
        else {
            return uiViewController
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(manager: manager)
    }

    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        let manager:AIOSheetManager
        init(manager:AIOSheetManager){
            self.manager = manager
        }
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            guard manager.dismissControl else {return true}
            return manager.unlock
        }

        //当阻止取消时,发送用户要求取消sheet命令
        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController){
            manager.dismissed.send(true)
        }
    }
}

extension View {
    public func allowAutoDismiss(_ manager:AIOSheetManager) -> some View {
        self
            .background(MbModalHackView(manager: manager))

    }
}
```

包装

```swift
struct XSheet:ViewModifier{
    @EnvironmentObject var manager:AIOSheetManager
    @EnvironmentObject var store:Store
    @Environment(\.managedObjectContext) var context
    var onDismiss:()->Void{
        return {
            (manager.dismissAction ?? {})()
            manager.dismissAction = nil
            manager.action = nil
            manager.showSheet = false
            manager.showFullCoverScreen = false
        }
    }
    func body(content: Content) -> some View {
        ZStack{
            content
            
            Color.clear
                .sheet(isPresented: $manager.showSheet,onDismiss: onDismiss){
                        if let action = manager.action
                        {
                            reducer(action)
                            .allowAutoDismiss(manager)
                            .environmentObject(manager)
                        }
                    
                }
            
            Color.clear
                .fullScreenCover(isPresented: $manager.showFullCoverScreen,onDismiss: onDismiss){
                        if let action = manager.action
                        {
                            reducer(action)
                                .allowAutoDismiss(manager)
                                .environmentObject(manager)
                        }
                }
        }
        .onChange(of: manager.action){ action in
            guard action != nil else {
                manager.showSheet = false
                manager.showFullCoverScreen = false
                return
            }
            if manager.type == .sheet {
                manager.showSheet = true
            }
            if manager.type == .fullScreenCover{
                manager.showFullCoverScreen = true
            }
        }
    }
}

enum AllInOneSheetAction:Identifiable,Equatable{
    case show(student:Student)
    case edit(student:Student)
    case new
    
    
    var id:UUID{UUID()}
}

extension XSheet{
    func reducer(_ action:AllInOneSheetAction) -> some View{
        switch action{
        case .show(let student):
            return StudentManager(action:.show, student:student)
        case .new:
            return StudentManager(action: .new, student: nil)
        case .edit(let student):
            return StudentManager(action:.edit,student: student)
        }
    }
}

extension View{
    func xsheet() -> some View{
        self
            .modifier(XSheet())
    }
}
```

调用方式

```swift
NavigationView{
    ...
}
.xsheet()


Button("New"){
         sheetManager.type = .sheet  //当前支持两种方式 sheet fullScreenCover
         sheetManager.dismissControl = true //打开控制
         sheetManager.action = .new   //设置统一sheet的action
              }
```

Form代码的修改

为了让我们的表单代码能够管理sheet，并且可以响应用户的取消手势，对Form代码做了如下的修改：

```swift
    @State private var changed = false{
        didSet{
            //控制sheet是否允许dismiss
            if action == .show {
                sheetManager.unlock = true
            }
            else {
                sheetManager.unlock = !changed
            }
        }
    }
```

```swift
新增
 .onReceive(sheetManager.dismissed){ value in
                delConfirm.toggle()
            }
```

详细代码请访问我的[github](https://github.com/fatbobman/DismissConfirmSheet)
