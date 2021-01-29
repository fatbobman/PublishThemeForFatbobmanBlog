---
date: 2020-09-04 12:00
description: 我的app健康笔记主要是对数据的收集、管理，所以对于表单的实时检查、响应的要求比较高。因此制作一个对用于输入响应及时、反馈准确的Form十分重要。本文尝试提出一个SwiftUI下的Form开发思路。
tags: SwiftUI
title: 如何在SwiftUI中创建一个实时响应的Form
---

> 我的app健康笔记主要是对数据的收集、管理，所以对于表单的实时检查、响应的要求比较高。因此制作一个对用于输入响应及时、反馈准确的Form十分重要。本文尝试提出一个SwiftUI下的Form开发思路。

## 健康笔记1.0的时候 ##

在开发健康笔记1.0的使用，当时由于iOS13尚不支持onChange，当时主要使用类似的检查方式：

## 对于简单情况 ##

```swift
@State var name = ""

TextField("name",text:$name)
     .foregroundColor(name.count.isEmpty ? .red : .black)

```

## 稍复杂的情况 ##

```swift
@State var name = ""
@State var age = ""

TextField("name",text:$name)
    .foregroundColor(!checkName() ? .red : .black)
TextField("age",text:$name)
     .keyboardType(.decimalPad)
     .foregroundColor(!checkAge() ? .red : .black)

Button("Save"){
   //保存
}
.disable(!(checkName()&&checkeAge))

func chekcName() -> Bool {
   return name.count > 0 && name.count <= 10 
}

func checkAge() -> Bool {
   guard let age = Double(age) else {return false}
   return age > 10 && age < 20
}
```

其实之前对于很复杂的表单，我也是采用了Combine的方式来做验证的。

不过Publisher的和View的刷新周期之间有一个响应的差距，也就是说，第一个输入的判断需要到第二个输入时才会返回结果。如此一来，只能将判断逻辑都写在View中。不过如果需要利用网络验证的部分，仍然是使用Publisher来处理的。它的响应由于使用OnReceive所以不会出现上面的判断时间差。

## 健康笔记2.0的处理方式 ##

在我目前开发的健康笔记2.0中，由于iOS 14支持了onChange,让开发者在View有了非常方便的处理逻辑判断的时机。

以下是目前开发中的画面：

![demo](http://cdn.fatbobman.com/swiftui-form-formDemo.gif)

## 用MVVM的方式来编写Form ##

在使用SwiftUI进行开发中，我们不仅需要使用MVVM的思想来考虑app的架构，对于每一个View都可以把它当做一个mini的app来对待。

在下面的例子中，我们需要完成如下的功能：

1. 显示档案、编辑档案、新建档案都使用同一个代码
2. 对于用户的每一次输入都给出及时和准确的反馈
3. 只有用户的数据完全满足需求时（各个输入项都满足检查条件同时在编辑状态下，当前修改数据要与原始数据不同），才允许用户保存。
4. 如果用户已经修改或创建了数据，用户取消时需要二次确认
5. 在用户显示档案时，可以一键切换到编辑模式

*如果你所需要创建的FormView功能简单，请千万不要使用下列的方法。下列代码仅在创建较复杂的表单时才会发挥优势。*

完成后的视频如下：

![demo](http://cdn.fatbobman.com/swiftui-form-studentDemo.gif)

下载 (当前代码已和 [在SwiftUI中制作可以控制取消手势的Sheet](https://zhuanlan.zhihu.com/p/245663226) 合并)

[源代码](https://github.com/fatbobman/DismissConfirmSheet)

为输入准备数据源

不同于创建多个@State数据源来处理数据，我现在将所有需要录入的数据统一放到了一个数据源中

```swift
struct MyState:Equatable{
    var name:String
    var sex:Int
    var birthday:Date
}
```

让View响应不同的动作

```swift
enum StudentAction{
    case show,edit,new
}
```

**有了上述的准备，我们便可以创建表单的构造方法了：**

```swift
struct StudentManager: View {
    @EnvironmentObject var store:Store
    @State var action:StudentAction
    let student:Student?
    
    private let defaultState:MyState  //用于保存初始数据，可以用来比较，或者在我的app中，可以恢复用户之前的值
    @State private var myState:MyState //数据源
    
    @Environment(\.presentationMode) var presentationMode

init(action:StudentAction,student:Student?){
        _action = State(wrappedValue: action)
        self.student = student
        
        switch action{
        case .new:
            self.defaultState = MyState(name: "",sex:0, birthday: Date())
            _myState = State(wrappedValue: MyState(name: "", sex:0, birthday: Date()))
        case .edit,.show:
            self.defaultState = MyState(name: student?.name ?? "", sex:Int(student?.sex ?? 0) , birthday: student?.birthday ?? Date())
            _myState = State(wrappedValue: MyState(name: student?.name ?? "", sex:Int(student?.sex ?? 0), birthday: student?.birthday ?? Date()))
        }
    }
  
}
```

准备表单显示内容

```swift
func nameView() -> some View{
        HStack{
            Text("姓名:")
            if action == .show {
                Spacer()
                Text(defaultState.name)
            }
            else {
                TextField("学生姓名",text:$myState.name)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
```

合成显示内容

```swift
Form{
             nameView()
             sexView()
             birthdayView()
             errorView()
      }
```

对每个输入项目进行验证

```swift
func checkName() -> Bool {
        if myState.name.isEmpty {
            errors.append("必须填写姓名")
            return false
        }
        else{
            return true
        }
    }
```

处理所有的验证信息

```swift
func checkAll() -> Bool {
        if action == .show {return true}
        errors.removeAll()
        let r1 = checkName()
        let r2 = checkSex()
        let r3 = checkBirthday()
        let r4 = checkChange()
        return r1&&r2&&r3&&r4
    }
```

通过onChange来进行校验

```swift
.onChange(of: myState){ _ in
         confirm =  checkAll()
       }
//由于onChange必须在数据源发生变化时才会激发，所以在View最初显示时便进行一次验证
.onAppear{
     confirm =  checkAll()
   }
```

对toolbar的内容进行处理

```swift
ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing){
                    if action == .show {
                        Button("编辑"){
                            action = .edit
                            confirm = false
                        }
                    }
                    else {
                    Button("确定"){
                        if action == .new {
                        presentationMode.wrappedValue.dismiss()
                        store.newStudent(viewModel: myState)
                        }
                        if action == .edit{
                            presentationMode.wrappedValue.dismiss()
                            store.editStudent(viewModel: myState, student: student!)
                        }
                    }
                    .disabled(!confirm)
                    }
```

更详尽的内容可以参看[源代码](https://github.com/fatbobman/DismissConfirmSheet)
