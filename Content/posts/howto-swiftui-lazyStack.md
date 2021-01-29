---
date: 2020-07-09 13:05
description: SwiftUI2.0提供了LazyVStack和LazyHStack，其作用是只有当View在可见区域内才进行渲染，这样可以大大大提高app执行效率
tags: SwiftUI,HowTo
title: HowTo —— SwiftU2.0 LazyVStack,LazyHStack
---

> SwiftUI2.0提供了LazyVStack和LazyHStack，其作用是只有当View在可见区域内才进行渲染，这样可以大大大提高app执行效率。由于VStack或HStack导致的效率问题，在[SwiftUI List (3) —— List、Form、VStack](https://zhuanlan.zhihu.com/p/111151515)文章中有简单的比较。

## 基本用法 ##

```swift
struct LazyStack: View {
    var body: some View {
        ScrollView{
            LazyVStack{ //换成VStack作比较新数据创建的时机
                ForEach(0...1000,id:\.self){ id in
                    Text(LazyItem(id:id).title)
                }
            }
        }
    }
}

struct LazyItem{
    let id:Int
    let title:String
    init(id:Int){
        self.id = id
        self.title = "id:\(id)"
        print("init new object:\(id)") 
    }
}

```

## 使用Lazy特性创建不间断的列表显示 ##

```swift
import SwiftUI

struct LazyStack: View {
    @State var list = (0...40).map{_ in Item(number:Int.random(in: 1000...5000))}
    @State var loading = false
    var body: some View {
        VStack{
        Text("count:\(list.count)")
        //数据数量，在LazyVStack下数据在每次刷新后才会增加，在VStack下，数据会一直增加。
        ScrollView{
            LazyVStack{ //换成VStack作比较
                ForEach(list,id:\.id){ item in
                    Text("id:\(item.number)")
                        .onAppear {
                            moreItem(id: item.id)
                        }
                }
            }
            if loading {
                ProgressView()
            }
        }
        }
    }
    
    func moreItem(id:UUID){
       //如果是最后一个数据则获取新数据
        if id == list.last!.id && loading != true {
            loading = true
            //增加延时，模拟异步数据获取效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                //数据模拟，也可获取网络数据
                list.append(contentsOf: (0...30)
                            .map{_ in Item(number:Int.random(in: 1000...5000))})
                loading = false
            }
        }
        
    }
}

 struct Item:Identifiable{
    let id = UUID()
    let number:Int
}

```

LazyHStack的用法同LazyVStack一样
