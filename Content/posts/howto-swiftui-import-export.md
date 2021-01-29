---
date: 2020-07-28 12:00
description: SwiftUI2.0中新增了原生的文件导入导出功能。需注意的是对于不同目录下文件的导出行为会有不同，不同平台下对于权限的处理也不同。
tags: SwiftUI,HowTo
title: HowTo —— SwiftUI2.0 文件导入导出
---


> SwiftUI2.0中新增了原生的文件导入导出功能。需注意的是对于不同目录下文件的导出行为会有不同，不同平台下对于权限的处理也不同。

## 更新 ##

目前SwiftUI大幅度的修改了导入导出的用法.

fileImporter fileExporter fileMover 分别对应 导入、导出、移动

示例如下:

```swift
  .fileImporter(isPresented: showImport, allowedContentTypes: [.zip], onCompletion: {
            result in
            switch result{
            case .success(let url):
                print(store.dataHandler.importData(url))
            case .failure(let error):
                print(error)
            }
            
            showImport.wrappedValue = false
  })
```

系统会自动弹出一个sheet,目前的fileImporter有bug,如果使用手势取消sheet,会很难二次呼出.只能使用cancel来取消.

其实我更喜欢之前的用法,不过现在以前的用法已经被废弃了.

----

## 原文章 ##

----

## importFiles ##

```swift
@Environment(\.importFiles) var importFile

importFile.callAsFunction(singleOfType: [.plainText]){ result in}
```

## exportFiles ##

```swift
@Environment(\.exportFiles) var exportFile

try! exportFile.callAsFunction(FileWrapper(url: URL(fileURLWithPath:filePath), options: .immediate), contentType: .plainText){result in}
```

## 示例代码 ##

```swift
import SwiftUI

struct ExportImportTest: View {
    @Environment(\.importFiles) var importFile
    @Environment(\.exportFiles) var exportFile
    @State var text:String = ""
    var body: some View {
        List{
            Button("生成文件"){
                let filePath = NSTemporaryDirectory() + "test.txt"
                let outputText = "Hello World!"
                do {
                    try outputText.write(toFile: filePath, atomically: true, encoding: .utf8)
                    print("测试文件已生成")
                }
                catch let error {
                    print(error)
                }
            }
            
            Button("导入文件importFiles"){
                importFile.callAsFunction(singleOfType: [.plainText]){ result in
                    switch result{
                    case .success(let url):
                        print(url)
                        do {
                            //iOS的沙盒机制保护需要我们申请临时调用url的权限
                            _ = url.startAccessingSecurityScopedResource()
                            let fileData = try Data(contentsOf: url)
                            if let text = String(data:fileData,encoding: .utf8) {
                                self.text = text
                                print(text)
                            }
                            url.stopAccessingSecurityScopedResource()
                        }
                        catch let error {
                            print(error)
                        }
                    case .failure(let error):
                        print(error)
                    case .none:
                        break
                    }
                }
            }
            
            Button("导出文件exportFiles"){
                //exportFile.callAsFunction(moving: URL, completion:  ) 移动文件,源文件会被删除
                //move如果出错(比如没有找到源文件,程序会崩溃)
                //从临时目录导出文件无论是否使用move,源文件都会被删除
                //个人比较倾向于FileWrapper的调用方式
                let filePath = NSTemporaryDirectory() + "test.txt"
                do {
                    try exportFile.callAsFunction(FileWrapper(url: URL(fileURLWithPath:filePath), options: .immediate), contentType: .plainText){result in
                        switch result{
                        case .success(let url):
                            print("文件导出成功:\(url)")
                        case .failure(let error):
                            print(error)
                        case .none:
                            break
                        }
                    }
                }
                catch let error {
                    print(error)
                }
            }
            
            Text("导入文件内容:\(text)")
        }
    }
}
```

> **macOS下需要将项目配置中的 App Sandbox - User Selected File 设置为 读写**

<video src="http://cdn.fatbobman.com/howto-swiftui-import-export-video.mp4" controls = "controls">你的浏览器不支持本视频</video>



## 遗憾 ##

没有提供原生的activityViewController。
