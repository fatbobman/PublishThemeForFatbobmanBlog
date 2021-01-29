---
date: 2020-07-10 12:00
description: SwiftUI的第一版中，官方并没有提供UICollectionView的对应功能。开发者需要自行包装或者依赖很多第三方库。SwiftUI2.0中，苹果通过LazyVGrid、LazyHGrid提供了Grid控件。该控件的实现很有SwiftUI的风格，和众多的第三方库有显著的区别。
tags: SwiftUI,HowTo
title: HowTO —— SwiftUI2.0 原生的Grid
---


> SwiftUI的第一版中，官方并没有提供UICollectionView的对应功能。开发者需要自行包装或者依赖很多第三方库。SwiftUI2.0中，苹果通过LazyVGrid、LazyHGrid提供了Grid控件。该控件的实现很有SwiftUI的风格，和众多的第三方库有显著的区别。

## 基本用法 ##

```swift
struct GridTest1: View {
    
    let columns = [
        GridItem(.adaptive(minimum: 50))
        //adaptive自适应，在一行或一列中放入尽可能多的Item
        //fixed完全固定的尺寸 GridItem(.fixed(50)), 需显式设置每行或每列中放入的item数量
        //flexible用法类似fixed，不过每个item的尺寸可以弹性调整，同样需要显式设置item数量
        //可以混用
    ]
    
    var body: some View {
        ScrollView{
            LazyVGrid(columns: columns, //行列设置数据
                      alignment: .center,
                      spacing: 20,  //item行或列宽
                      pinnedViews: [.sectionHeaders] 
                      //如果有section,将header或footer在滚动中固定
            ){
                Section(header:Text("Header")){
                    ForEach(0...1000,id:\.self){ id in
                        Text(String(id))
                            .foregroundColor(.white)
                            .padding(.all, 10)
                            .background(Rectangle().fill(Color.orange))
                    }
                }
            }
        }
    }
}

```

![image-20200709202554829](http://cdn.fatbobman.com/howto-swiftui-grid1.png)

## LazyVGrid和LazyHGrid混合使用 ##

```swift
struct CombineGrid: View {
    
    var body: some View {
        ScrollView{
            LazyVGrid(columns: [GridItem(.adaptive(minimum:40))], alignment: .center, spacing: 10){
                ForEach(0...40,id:\.self){ id in
                    cell(id:id,color:.red)
                }
            }
            //横向滚动
            ScrollView(.horizontal) {
                LazyHGrid(rows: [GridItem(.fixed(50)),GridItem(.fixed(50))]){
                    ForEach(0...100,id:\.self){id in
                        cell(id:id,color:.green)
                    }
                }
            }
            .frame(height: 240, alignment: .center)
            LazyVGrid(columns: [GridItem(.adaptive(minimum:40))], alignment: .center, spacing: 10){
                ForEach(0...100,id:\.self){ id in
                    cell(id:id,color:.blue)
                }
            }
        }
    }
    
    func cell(id:Int,color:Color) -> some View{
        RoundedRectangle(cornerRadius: 10)
            .fill(color)
            .frame(width: 50, height: 50)
            .overlay(Text("\(id)").foregroundColor(.white))
    }
}
```

![image-20200709205047655](http://cdn.fatbobman.com/howto-swiftui-grid2.png)

> **这段代码快速向上滚动时显示正常，如果向上滚动速度较慢，中部的LazyHGrid会显示异常。应该是bug。当前环境Xcode Version 12.0 beta 2 (12A6163b)**

## 各种参数混合的例子 ##

```swift
import SwiftUI

struct GridTest: View {
    @State var data = (1...1000).map{i in CellView(item:i, width: CGFloat(Int.random(in: 30...100)), height: CGFloat(Int.random(in: 40...80)))}
    
    let column1 = [
        GridItem(.adaptive(minimum: 40, maximum: 80))
    ]
    let column2 = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    let column3 = [
        GridItem(.fixed(100)),
        GridItem(.fixed(100)),
        GridItem(.fixed(100)),
        GridItem(.fixed(100)),
        GridItem(.fixed(100)),
    ]
    
    @State var selection = 1
    @State var alignment:HorizontalAlignment = .leading
    @State var alignmentSelection = 0
    @State var spacing:CGFloat = 10
    var body: some View {
        VStack{
            Picker("", selection: $selection){
                Text("adaptive").tag(0)
                Text("flexible").tag(1)
                Text("fixed").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            Picker("",selection:$alignmentSelection){
                Text("leading").tag(0)
                Text("center").tag(1)
                Text("trailing").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            Slider(value: $spacing, in: -100...100){Text("spacing")}
            Text("\(spacing)")
                .onChange(of: alignmentSelection) { value in
                    switch value{
                    case 0:
                        alignment = .leading
                    case 1:
                        alignment = .center
                    case 2:
                        alignment = .trailing
                    default:
                        break
                    }
                }
            Button("shuffle"){
                withAnimation(Animation.easeInOut){
                    data.shuffle()
                }
            }
            ScrollView{
                let colums = [column1,column2,column3]
                LazyVGrid(columns: colums[selection], alignment: alignment, spacing: spacing, pinnedViews: [.sectionHeaders]){
                    Section(header: Text("header")){
                        ForEach(data,id:\.id){ view in
                            view
                        }
                    }
                }
            }
        }
    }
}

struct CellView:View,Identifiable{
    let id = UUID()
    let item:Int
    let width:CGFloat
    let height:CGFloat
    let colors:[Color] = [.red,.blue,.yellow,.purple,.pink,.green]
    var body: some View{
        Rectangle()
            .fill(colors.randomElement() ?? Color.gray)
            .frame(width: width, height: height, alignment: .center)
            .overlay(Text("\(item)").font(.caption2))
    }
}

```

> **由于是Lazy显式，所以如果没有将全部cell滚动显示出来便进行shuffle操作，没有创建的cell将不会以动画的方式进行移动。

<video src="http://cdn.fatbobman.com/howto-swiftui-gridvideo.mov" controls = "controls" >你的浏览器不支持本视频</video>

目前LazyGrid没有自动避碰的能力，也无法实现Waterfall Grid的效果。
