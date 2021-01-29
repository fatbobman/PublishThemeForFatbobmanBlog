---
date: 2020-10-28 12:00
description: 本文并非一个教你如何在SwiftUI下使用CoreData的教程。主要探讨的是在我近一年的SwiftUI开发中使用CoreData的教训、经验、心得。
tags: SwiftUI,Core Data
title: 聊一下在SwiftUI中使用CoreData
---


> 本文并非一个教你如何在SwiftUI下使用CoreData的教程。主要探讨的是在我近一年的SwiftUI开发中使用CoreData的教训、经验、心得。

## SwiftUI lifecycle 中如何声明持久化存储和上下文 ##

在XCode12中，苹果新增了SwiftUI lifecycle，让App完全的SwiftUI化。不过这就需要我们使用新的方法来声明持久化存储和上下文。

好像是从beta6开始，XCode 12提供了基于SwiftUI lifecycle的CoreData模板

```swift
@main
struct CoreDataTestApp: App {
    //持久化声明
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)  
          //上下文注入
        }
    }
}
```

在它的Presitence中，添加了用于preview的持久化定义

```swift
struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        //根据你的实际需要，创建用于preview的数据
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer
    //如果是用于preview便将数据保存在内存而非sqlite中
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Shared")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}

```

虽然对于用于preview的持久化设置并不完美，不过苹果也意识到了在SwiftUI1.0中的一个很大问题，无法preview使用了@FetchRequest的视图。

由于在官方CoreData模板出现前，我已经开始了我的项目构建，因此，我使用了下面的方式来声明

```swift
struct HealthNotesApp:App{
  static let coreDataStack = CoreDataStack(modelName: "Model") //Model.xcdatemodeld
  static let context = DataNoteApp.coreDataStack.managedContext
  static var storeRoot = Store() 
   @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  WindowGroup {
        rootView()
            .environmentObject(store)
            .environment(\.managedObjectContext, DataNoteApp.context)
  }
}
```

在UIKit App Delegate中，我们可以使用如下代码在App任意位置获取上下文

```swift
let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
```

但由于我们已经没有办法在SwiftUI lifecycle中如此使用，通过上面的声明我们可以利用下面的方法在全局获取想要的上下文或其他想要获得的对象

```swift
let context = HealthNotesApp.context
```

比如在 delegate中

```swift
class AppDelegate:NSObject,UIApplicationDelegate{
    
    let send = HealthNotesApp.storeRoot.send
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        logDebug("app startup on ios")
       
        send(.loadNote)
        return true
    }

    func applicationDidFinishLaunching(_ application: UIApplication){
        
        logDebug("app quit on ios")
        send(.counter(.save))

    }

}

//或者直接操作数据库，都是可以的
```

## 如何动态设置 @FetchRequest ##

在SwiftUI中，如果无需复杂的数据操作，使用CoreData是非常方便的。在完成xcdatamodeld的设置后，我们就可以在View中轻松的操作数据了。

我们通常使用如下语句来获取某个entity的数据

```swift
@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Student.studentId, ascending: true)],
              predicate:NSPredicate(format: "age > 10"),
              animation: .default) 
private var students: FetchedResults<Student>
```

不过如此使用的话，查询条件将无法改变，如果想根据需要调整查询条件，可以使用下面的方法。

健康笔记2中的部分代码：

```swift
struct rootView:View{
    @State var predicate:NSPredicate? = nil
    @State var sort = NSSortDescriptor(key: "date", ascending: false)
    @StateObject var searchStore = SearchStore()
    @EnvironmentObject var store:Store
    var body:some View{
      VStack {
       SearchBar(text: $searchStore.searchText) //搜索框
       MemoList(predicate: predicate, sort: sort,searching:searchStore.showSearch)
        }
      .onChange(of: searchStore.text){ _ in
          getMemos()
      } 
    }
  
       //读取指定范围的memo
    func getMemos() {
        var predicators:[NSPredicate] = []
        if !searchStore.searchText.isEmpty && searchStore.showSearch {
            //memo内容或者item名称包含关键字
            predicators.append(NSPredicate(format: "itemData.item.name contains[cd] %@ OR content contains[cd] %@", searchStore.searchText,searchStore.searchText))
        }
        if star {
            predicators.append(NSPredicate(format: "star = true"))
        }
        
        switch store.state.memo{
        case .all:
            break
        case .memo:
            if !searchStore.searchText.isEmpty && noteOption == 1 {
                break
            }
            else {
                predicators.append(NSPredicate(format: "itemData.item.note = nil"))
            }
        case .note(let note):
            if !searchStore.searchText.isEmpty && noteOption == 1 {
                break
            }
            else {
                predicators.append(NSPredicate(format: "itemData.item.note = %@", note))
            }
        }
        
        withAnimation(.easeInOut){
            predicate =  NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: predicators)
            sort =  NSSortDescriptor(key: "date", ascending: ascending)
        }
    }
}
```

上述代码会根据搜索关键字以及一些其他的范围条件，动态的创建predicate，从而获得所需的数据。

对于类似查询这样的操作，最好配合上Combine来限制数据获取的频次

例如：

```swift
class SearchStore:ObservableObject{
    @Published var searchText = ""
    @Published var text = ""
    @Published var showSearch = false
    
    private var cancellables:[AnyCancellable] = []
    
    func registerPublisher(){
        $searchText
            .removeDuplicates()
            .debounce(for: 0.4, scheduler: DispatchQueue.main)
            .assign(to: &$text)
    }
    
    func removePublisher(){
        cancellables.removeAll()
    }
    
}
```

上述所有代码均缺失了很大部分，仅做思路上的说明

## 增加转换层方便代码开发 ##

在开发健康笔记 1.0的时候我经常被类似下面的代码所烦恼

```swift
@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Student.name, ascending: true)],
              animation: .default) 
private var students: FetchedResults<Student>

ForEach(students){ student in
  Text(student.name ?? "")
  Text(String(student.date ?? Date()))
}
```

在CoreData中，设置Attribute，很多时候并不能完全如愿。

好几个类型是可选的，比如String，UUID等，如果在已发布的app，将新增的attribute其改为不可选，并设置默认值，将极大的增加迁移的难度。另外，如果使用了NSPersistentCloudKitContainer,由于Cloudkit的atrribute和CoreData并不相同，XCode会强制你将很多Attribute改成你不希望的样式。

为了提高开发效率，并为未来的修改留出灵活、充分的更改空间，在健康笔记2.0的开发中，我为每个NSManagedObject都增加了一个便于在View和其他数据操作中使用的中间层。

例如：

```swift
@objc(Student)
public class Student: NSManagedObject,Identifiable {
    @NSManaged public var name: String?
    @NSmanaged public var birthdate: Date?
}

public struct StudentViewModel: Identifiable{
    let name:String
    let birthdate:String
}

extension Student{
   var viewModel:StudentViewModel(
        name:name ?? ""
        birthdate:(birthdate ?? Date()).toString() //举例
   )
  
}
```

如此一来，在View中调用将非常方便，同时即使更改entity的设置，整个程序的代码修改量也将显著降低。

```swift
ForEach(students){ student in
  let student = student.viewModel
  Text(student.name)
  Text(student.birthdate)
}
```

同时，对于数据的其他操作，我也都通过这个viewModel来完成。

比如：

```swift

//MARK:通过ViewModel生成Note数据,所有的prepare动作都需要显示调用 _coreDataSave()
    func _prepareNote(_ viewModel:NoteViewModel) -> Note{
        let note = Note(context: context )
        note.id = viewModel.id 
        note.index = Int32(viewModel.index)  
        note.createDate = viewModel.createDate  
        note.name = viewModel.name 
        note.source = Int32(viewModel.source)  
        note.descriptionContent = viewModel.descriptionContent 
        note.color = viewModel.color.rawValue 
        return note
    }
    
    //MARK:更新Note数据,仍需显示调用save
    func _updateNote(_ note:Note,_ viewModel:NoteViewModel) -> Note {
        note.name = viewModel.name
        note.source = Int32(viewModel.source)
        note.descriptionContent = viewModel.descriptionContent
        note.color = viewModel.color.rawValue
        return note
    }

func newNote(noteViewModel:NoteViewModel) -> AnyPublisher<AppAction,Never> {
       let _ = _prepareNote(noteViewModel)
       if  !_coreDataSave() {
            logDebug("新建Note出现错误")
       }
       return Just(AppAction.none).eraseToAnyPublisher()
    }
    
func editNote(note:Note,newNoteViewModel:NoteViewModel) -> AnyPublisher<AppAction,Never>{
        let _ = _updateNote(note, newNoteViewModel)
        if !_coreDataSave() {
            logDebug("更新Note出现错误")
        }
        return Just(AppAction.none).eraseToAnyPublisher()
}
```

在View中调用

```swift
Button("New"){
      let noteViewModel = NoteViewModel(createDate: Date(), descriptionContent: myState.noteDescription, id: UUID(), index: -1, name: myState.noteName, source: 0, color: .none)
     store.send(.newNote(noteViewModel: noteViewModel))
     presentationMode.wrappedValue.dismiss()
}
```

从而将可选值或者类型转换控制在最小范围

## 使用NSPersistentCloudKitContainer 需要注意的问题 ##

从iOS13开始，苹果提供了NSPersistentCloudKitContainer，让app可以以最简单的方式享有了数据库云同步功能。

不过在使用中，我们需要注意几个问题。

* Attribute
  在上一节提高过，由于Cloudkit的数据设定和CoreData并不完全兼容，因此如果你在项目初始阶段是使用NSPersistentContainer进行开发的，当将代码改成NSPersistentCloudKitContainer后，XCode可能会提示你某些Attribute不兼容的情况。如果你采用了中间层处理数据，修改起来会很方便，否则你需要对已完成的代码做出不少的修改和调整。我通常为了开发调试的效率，只有到最后的时候才会使用NSPersistentCloudKitContainer，因此这个问题会比较突出。

* 合并策略
  奇怪的是，在XCode的CoreData（点选使用CloudKit）默认模板中，并没有设定合并策略。如果没有设置的话，当app的数据进行云同步时，时长会出现合并错误，并且@FetchRequest也并不会在有数据发生变动时对View进行刷新。因此我们需要自己明确数据的合并策略。

```swift
      lazy var persistentContainer: NSPersistentCloudKitContainer = {
          let container = NSPersistentCloudKitContainer(name: modelName)
          container.loadPersistentStores(completionHandler: { (storeDescription, error) in
              if let error = error as NSError? {
                  fatalError("Unresolved error \(error), \(error.userInfo)")
              }
          })
          //需要显式表明下面的合并策略,否则会出现合并错误!
          container.viewContext.automaticallyMergesChangesFromParent = true
          container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
          return container
      }()
```

* 调试信息
  当打开云同步后，在调试信息中将出现大量的数据同步调试信息，严重影响了对于其他调试信息的观察。虽然可以通过启动命令屏蔽掉数据同步信息，但有时候我还是需要对其进行观察的。目前我使用了一个临时的解决方案。

```swift
  #if !targetEnvironment(macCatalyst) && canImport(OSLog)
  import OSLog
  let logger = Logger.init(subsystem: "com.fatbobman.DataNote", category: "main") //调试用
  func logDebug(_ text:String,enable:Bool = true){
      #if DEBUG
      if enable {
          logger.debug("\(text)")
      }
      #endif
  }
  #else
  func logDebug(_ text:String,enable:Bool = true){
      print(text,"$$$$")
  }
  #endif
```

  对于需要显示调试信息的地方

```swift
  logDebug("数据格式错误")
```

  然后通过在Debug窗口中将Filter设置为$$$$来屏蔽掉暂时不想看到的其他信息

## 不要用SQL的思维限制了CoreData的能力 ##

CoreData虽然主要是采用Sqlite来作为数据存储方案，不过对于它的数据对象操作不要完全套用Sql中的惯用思维。

一些例子

排序：

```swift
//Sql式的
NSSortDescriptor(key: "name", ascending: true)
//更CoreData化，不会出现拼写错误
NSSortDescriptor(keyPath: \Student.name, ascending: true)
```

在断言中不适用子查询而直接比较对象：

```swift
NSPredicate(format: "itemData.item.name = %@",name)
```

Count:

```swift
func _getCount(entity:String,predicate:NSPredicate?) -> Int{
        let fetchRequest = NSFetchRequest<NSNumber>(entityName: entity)  
        fetchRequest.predicate = predicate
        fetchRequest.resultType = .countResultType
        
        do {
            let results  = try context.fetch(fetchRequest)
            let count = results.first!.intValue
            return count
        }
        catch {
            #if DEBUG
            logDebug("\(error.localizedDescription)")
            #endif
            return 0
        }
    }
```

或者更加简单的count

```swift
@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Student.name, ascending: true)],
              animation: .default) 
private var students: FetchedResults<Student>

sutudents.count
```

对于数据量不大的情况，我们也可以不采用上面的动态predicate方式，在View中直接对获取后的数据进行操作，比如：

```swift
@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Student.name, ascending: true)],
              animation: .default) 
private var studentDatas: FetchedResults<Student>
@State var students:[Student] = []
var body:some View{
  List{
        ForEach(students){ student in
           Text(student.viewModel.name)
         }
        }
        .onReceive(studentDatas.publisher){ _ in
            students = studentDatas.filter{ student in
                student.viewModel.age > 10
            }
        }
   }
}
```

总之数据皆对象
