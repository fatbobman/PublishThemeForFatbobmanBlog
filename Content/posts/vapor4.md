---
date: 2020-05-07 12:00
description: 本文介绍了如何在mac 10.5.4和ubuntu 18.04下安装Vapor命令行工具，创建Vapor项目，简单的调试项目以及如何部署到生产环境的过程。文中的运行环境为: Vapor4,Swift5.2,Catalina 10.5.4,Ubuntu18.04
tags: Vapor
title: Vapor4 的安装与配置
---
> 本文介绍了如何在mac 10.5.4和ubuntu 18.04下安装Vapor命令行工具，创建Vapor项目，简单的调试项目以及如何部署到生产环境的过程。文中的运行环境为: Vapor4,Swift5.2,Catalina 10.5.4,Ubuntu18.04

最近新开通了一个云服务器（Linux系统），使用[Hexo](https://hexo.io/zh-cn/index.html/)创建了新的博客网页。考虑增加点简单的交互功能，所以需要在服务器端添加逻辑处理能力。由于近半年来基本上都是在使用Swift，所以打算尝试一下Server Side Swift。没有太仔细选择各种框架，看过几个介绍Vapor使用的视频后，感觉不错，便开始尝试安装配置。

Vapor的官方文档实在是有很大的问题，网上的不少心得、教程又有点陈旧（目前版本调整较大）。通过两天的折腾，终于基本上理出了脉络，初步搭建了开发和生产环境。

## 什么是Vapor ##

[Vapor](https://github.com/vapor/vapor)是一个使用swift语言编写的Web网络框架，它是跨平台的（mac、Linux），用户可以使用swift语言以及其丰富的第三方库来高效的完成多种网络服务。

```swift
import Vapor

let app = try Application()
let router = try app.make(Router.self)

router.get("hello") { req in
    return "Hello, world."
}

try app.run()
```

上面的代码变可以完成一个最基本的网络服务。访问 `http://localhost:8080/hello`     网页返回  *hello, world.*

你可以在mac或Linux平台上开发，同时也可以将通过Vapor框架开发的项目部署到mac或Linux平台上。

## 什么是Vaper 命令行工具 ##

Vaper命令行工具的作用有：

* 基于模板创建Vaper项目
* 配置、编译、运行项目
* 其他配合操作系统的一些功能

但它不是必须的，如果用户已经很熟悉Vapor的开发和配置，无论是在开发环境还是运行环境都可以不使用这个命令行工具。不过对于像我这样的新手来说，无疑它是一个好的帮手。

### 开发Vaper项目需要的资源 ###

* mac 或 Linux ，我目前在Catalina 10.5.4 和 Ubuntu 18.04下都成功完成了配置
* swift语言环境，目前Vapor4可以在swift5.2下运行
* web服务器，我目前使用Nginx （如果只是用于开发测试，也可以不配置）

## 安装swift ##

### Mac ###

在mac平台下，安装Xcode及Xcode ommand Line Tools，Vapor4对xcode提供了非常友好的支持，可以像其他的swift项目一样使用全部的Xcode的各种能力（比如断点调试）。

#### Ubuntu 18.04 ####

```bash
sudo apt-get install clang
sudo apt-get install libcurl3 libpython2.7 libpython2.7-dev 

#从swift.org找到需要的文件

wget https://swift.org/builds/swift-5.2.3-release/ubuntu1804/swift-5.2.3-RELEASE/swift-5.2.3-RELEASE-ubuntu18.04.tar.gz

tar xzvf swift-5.2.3-RELEASE-ubuntu18.04.tar.gz
sudo mv swift-5.2.3-RELEASE-ubuntu18.04 /usr/share/swift

echo "export PATH=/usr/share/swift/usr/bin:$PATH" >> ~/.bashrc
source  ~/.bashrc
```

我也使用过Docker安装Swift5.2，不过Image有点太大，需要1.2Gb左右的空间。

```bash
#Docker安装Swift的方法。
docker pull swift
```

## 安装Vapor命令行工具 ##

### MacOS ###

```shell
brew tap vapor/tap
brew install vapor
#我目前安装的是 vapor-beta
#brew install vapor-beta
#执行vapor测试一下
vapor
```

### Ubuntu 1804 ###

Ubuntu下安装Vapor toolbox略微麻烦，主要是目前的Vapor Toolbox源文件有点问题需要做一些修改才能正常编译。

首先保证已成功安装 **swift**

```bash
cd ~
git clone https://github.com/vapor/toolbox.git
cd toolbox

```

在 Test 目录下 创建一个 **LinuxMain.swift** 文件

```swift
import XCTest
@testable import AppTests
XCTMain([testCase(AppTests.allTests)])
```

***这个是Swift SPM需要的文件，上面我只写了个最简单的能够完成编译即可，不清楚为什么官方的git源不包含这个文件。***

修改 Source/VaporToolbox/exec.swift 文件

在36行左右（当前版本）找到

``` swift
let spawned = posix_spawnp(&pid, argv[0], &fileActions, nil, argv + [nil], envp + [nil])
```

修改成

```swift
guard let _argv0 = argv[0] else {
            fatalError("unwrap error")
        }
let spawned = posix_spawnp(&pid, _argv, &fileActions, nil, argv + [nil], envp + [nil])

```

***同样不清楚为什么代码会有这么一个错误。***

完成上述修改后

```bash
cd ~/toolbox
swift build -c release --disable-sandbox
sudo mv .build/release/vapor /usr/local/bin
```

*以上步骤在我本地的Ubuntu上已可正常编译，不过在我的腾讯云主机上，编译时会缺少一个相关库，添加上后即可正常编译。*

```bash
sudo apt-get install libcurl4 -y
```

至此Vapor Toolbox 安装完毕。

*Toolbox的目录中包含了Dockerfile，使用它可以直接将toolbox生成一个Docker Image，并且系统会自动下载swift的Docker Image。不过我在Ubuntu上使用这种方法安装后（已配置entrypoint），vapor的Image没有名字，只有container id，但是可以通过id来运行。个人目前不推荐这种方式。*

## 使用 Vapor命令行工具 ##

### 创建项目 ####

```bash
#vapor new <projectname> [--template]
vapor new hello
```

使用缺省模板创建一个名为 hello 的Vapor项目。

创建的过程其实就是从github上clone一个模板，并可帮你进行简单配置。如果已经比较熟悉的话也可以不适用工具，直接从github上[克隆模板](https://github.com/vapor?q=template&type=&language=)开始项目。

在Mac系统下，模板可以直接编译运行，不过Linux下，git源仍然缺少  **LinuxMain.swift** 文件，按照上面的方法，在项目中加入该文件后方可编译。

clone完成后，系统会有如下提示：

```bash
Would you like to use Fluent? y
数据库类型选择 #我选择了 sqllite
```

系统会根据你的选择直接在模板中创建好相应的代码。（[Fluent](https://github.com/vapor/fluent) 是一个swift写的ORM）

### 编译项目 ####

```bash
cd ~/hello
vapor build
```

我在ubuntu下执行**vapor new**可以正常执行，不过**vapor build**执行报错。因此就直接使用 **swift build** 来编译项目。其实**build** 和 **run** 都是直接调用的 **swift** 命令。

### 运行项目 ###

```bash
vapor run 
#系统显示，说明项目已正常启动。可以通过 http://127.0.0.1:8080 访问
Environment(name: "development", arguments: [".build/x86_64-apple-macosx/debug/Run"])
[ NOTICE ] Server starting on http://127.0.0.1:8080
```

可以在运行命令后面添加运行状态，对于部署尤为重要。

```bash
vapor run --env prod 
# test prod dev 对应不同的状态，主要关系到是否显示操作日志等
```

如果是Mac系统，使用

```bash
vapor xcode 
```

直接打开Xcode，然后就可以直接在Xcode下编辑、编译、调试、运行。

即使没有安装Vapor Toolbox也可以使用如下命令创建Xcode项目

```bash
swift package generate-xcodeproj
```

按照上述的步骤安装后，无论在Mac上还是Ubuntu上我们都可以开始编写并运行自己的Vapor项目了。

## 模板项目简单分析 ##

本节我们通过对模板代码的简单分析来快速感受一下Vapor的便捷。

我使用的是项目缺省模板，启用Fluent，数据库选择的是sqlite。

项目源文件存在Sources目录下。

![目录结构](http://cdn.fatbobman.com/vapor4-struct.png)

**main.swift**作为程序的入口，创建了Vapor服务

**configure.swift**中由于我们选择了使用sqlite，因此系统为我们自动生成了使用数据库所需的代码。下列代码完成数据库的创建工作。

```swift
app.migrations.add(CreateTodo())
```

为了能够完整的运行这个模板项目，我们需要在命令行执行

```bash
vapor run migrate
```

系统将在项目根目录下完成db.sqlite里的表创建工作。如果没有执行这个步骤，访问 localhost:8080/todos 将在得到如下的错误提示。

```bash
[ ERROR ] error: no such table: todos
```

**Xcode的用户也可以直接在Scheme中的Arguments添加 --auto-migrate 完成上述功能。**

**另外，最好在Xcode中将Scheme -- Run -- Working Directory设置成当前项目的根目录，这样无论使用命令行，还是直接使用Xcode都可以使用同一个Sqlite文件。**

```swift
//app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
```

如果取消这一句的注释，Vapor将提供对静态文件的支持。我们可以把静态文件放入项目根目录的 Public目录中，即可访问。 127.0.0.1:8080/index.html 。如果和其他WebServer配合使用的话，我感觉还是用如Nginx来提供静态文件的支持比较好。

routes.swift**作为项目的核心，在其中完成网络的路由逻辑设定。

```swift
import Fluent
import Vapor

func routes(_ app: Application) throws {
    /*
    访问  127.0.0.1:8080/  返回：It works!
    */
    app.get { req in
        return "It works!"
    }
    
    //   localhost:8080/hello    返回: "Hello world"
    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    let todoController = TodoController()
    /*
    以下操作我使用postman进行测试
    post 127.0.0.1:8080/todos body内容: {"title":"东坡肘子"}  添加一条记录
    get 127.0.0.1:8080/todos 显示已添加的记录
    del 127.0.0.1:8080/todos/B508471F-FF5F-422C-B384-C300FD7B49D9 删除一条记录。id使用显示记录获取
    */
    app.get("todos", use: todoController.index)
    app.post("todos", use: todoController.create)
    app.delete("todos", ":todoID", use: todoController.delete)
}

```

更具体的应用就不展开了。不过仅从模板例程上我们便可以感觉到Vapor的便利和高效。

## 和Nginx 配合使用 ##

通过编辑nginx的配置文件，我们的Vapor项目便可以对外发布了。

```nginx
server {
        listen       80;
        server_name  localhost;
  
        location / {
          root   html;
          index   index.html index.htm;
          try_files  $uri @proxy;
        }

        location @proxy {
               proxy_pass http://127.0.0.1:8080;
               proxy_pass_header Server;
               proxy_set_header Host $host;
               proxy_set_header X-Real-IP $remote_addr;
               proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
               proxy_pass_header Server;
               proxy_connect_timeout 3s;
               proxy_read_timeout 10s;
}
```

现在你就可以通过 `http://你的域名或地址/todos` 来访问你的项目。

我使用Vapor的目的是为了配合自己的博客，所以仍需配合我自己原有的页面使用，所以采用了如下的配置。

即使打开了Vapor的静态页面支持，如果我把Vapor项目配置在/的话（已取消Vapor对根的响应），仍然需要明确的输入 `http://我的域名/index.html`才能访问到索引页面。没有办法才把他转到 /api/下。

```nginx
server {
        listen       80;
        server_name  localhost;
  
        location / {
            root   html;
            index  index.html index.htm;
        }

        location /api {
          root   html;
          index   index.html index.htm;
          try_files  $uri @proxy;
        }

        location @proxy {
               proxy_pass http://127.0.0.1:8080;
               proxy_pass_header Server;
               proxy_set_header Host $host;
               proxy_set_header X-Real-IP $remote_addr;
               proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
               proxy_pass_header Server;
               proxy_connect_timeout 3s;
               proxy_read_timeout 10s;
}
```

如此配置后，需要对代码 routes.swift 进行改动后即可正常访问。

```swift
app.get("api","hello") { req -> String in
        return "Hello, world!"
    }
```

如果谁知道如何设置能够直接将/转发到Vapor而又可以 直接使用 http://我的域名 来访问原有的页面烦请告知一下。

## 部署 ##

### 修改运行端口 ###

Vapor4对于指定运行端口和之前有了较大的区别。

在main.swift中做如下修改

```swift
app.http.server.configuration.hostname = "127.0.0.1" //响应的地址 0.0.0.0 
app.http.server.configuration.port = 8000 //希望设定的端口
try configure(app)
```

目前我没有找到如何在命令行下设置运行端口（Vapor3之前的方法好像已经不支持了）。如果有人了解烦请告知一下。

### 手动部署 ###

由于我目前也还刚刚开始接触Vapor，为了调试方便，我在本机的Xcode下进行开发。通过github作为中转，将本地的修改commit到repository上。手动在服务器端fetch并执行。在终端中执行的话当前终端将被任务锁定。

### Docker部署 ###

另外，Vapor的模板本身已经生成了Dockerfile。也可以直接将完成后的项目生成Docker Image。这种方式可以将项目发布到任何支持Docker的平台（mac、Linux、windows等）。不过通常只适用于已经开发完善后的部署。更多细节可查阅[官方文档](https://docs.vapor.codes/4.0/deploy/docker/)

### Supervisior ###

Vapor Toolbox 已提供了对 [Supervisior](http://supervisord.org) 的支持,可以很方便的通过supervisor来管理服务。

ubuntu下安装Supervisor

```bash
sudo apt-get update
sudo apt-get install supervisor
```

我们需要为每一个项目创建一个supervisor配置文件。创建/etc/supervisor/conf.d/hello.conf

```bash
[program:hello]
command=/home/parallels/hello/.build/release/Run serve --env production
directory=/home/parallels/hello
user=parallels
stdout_logfile=/var/log/supervisor/%(program_name)-stdout.log
stderr_logfile=/var/log/supervisor/%(program_name)-stderr.log
```

文件名是你的项目名.conf，目录指向你项目的根目录并设置好用户名

```bash
command=/home/parallels/hello/.build/release/Run serve --env production
```

需确定已将项目编译成release版本，如果vapor build不好用，可以使用如下命令

```bash
cd ~/hello
swift build -c release
```

通过supervisor管理项目

```bash
supervisorctl reread
supervisorctl add hello
supervisorctl start hello
```

也可以通过supervisor的配置来指定运行端口

在/etc/supervisor/conf.d/hello.conf中加入

```bash
environment=PORT=8123
```

修改 main.swift

```swift
let port = Environment.get("PORT") ?? ""
app.http.server.configuration.port = Int(port) ?? 8080
```

## 结语 ##

希望本文能够对你开始使用Vapor4带来一点帮助。同时也希望swift能在更多的平台上有所表现。

swift已有更多的官方对window支持的迹象。
