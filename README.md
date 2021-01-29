# [Publish](https://github.com/johnsundell/publish) theme for [fatbobman.com](https://fatbobman.com) #

这是我[个人博客站点](https://www.fatbobman.com)目前使用的Publish代码.
分享的目的是让大家可以较快的上手Publish.
我在其中使用的第三方插件都已经标明了出处.你也可以直接从各自的Git源获取.
关于Publish的上手介绍,以及如何编写Plugin和扩展新的功能,可以访问我的文章.

This is the Publish code I am currently using for my [personal blog site](https://www.fatbobman.com).
The purpose of sharing is to get you started with Publish faster.
The third-party plugins I've used in it have been marked with their source. You can also get them directly from their respective Git sources.
For an introduction to getting started with Publish, and how to write Plugin and extend it with new features, visit my article

其中包括了我自己写的几个Plugin:

[TruncateHtmlDescription](https://github.com/fatbobman/PublishThemeForFatbobmanBlog/blob/main/Sources/FatbobmanBlog/Plugins/TruncateHtml.swift)
为content生成指定字符数的HTML String，用于更详细的文章描述

[TagCount](https://github.com/fatbobman/PublishThemeForFatbobmanBlog/blob/main/Sources/FatbobmanBlog/Plugins/TagCount.swift)
给每个Tag增加count属性，获取该Tag下的文章数

[Bilibili Video](https://github.com/fatbobman/PublishThemeForFatbobmanBlog/blob/main/Sources/FatbobmanBlog/Plugins/Bilibili.swift)
一个modifier演示，创建一个显示bilibili视频的标签

[RssPropertiesSetting](https://github.com/fatbobman/PublishThemeForFatbobmanBlog/blob/main/Sources/FatbobmanBlog/Plugins/RssPropertiesSetting.swift)
为rss设定更多的配置

and more...
