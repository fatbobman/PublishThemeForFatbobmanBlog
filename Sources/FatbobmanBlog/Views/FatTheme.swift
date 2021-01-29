/**
 *  Publish
 *  Copyright (c) John Sundell 2019
 *  MIT license, see LICENSE file for details
 */

import Foundation
import Plot
import Publish

extension Theme {
    /// The default "Foundation" theme that Publish ships with, a very
    /// basic theme mostly implemented for demonstration purposes.
    public static var fatTheme: Self {
        Theme(
            htmlFactory: FatThemeHTMLFactory(),
            resourcePaths: ["Resources/FatTheme/styles.css"]
        )
    }
}

private struct FatThemeHTMLFactory<Site: Website>: HTMLFactory {
    //首页
    func makeIndexHTML(
        for index: Index,
        context: PublishingContext<Site>
    ) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: index, on: context.site),
            .body(
                .class("index"),
                .header(for: context, selectedSection: FatbobmanBlog.SectionID.index as? Site.SectionID),
                .wrapper(
//                    .gridBox(context:context),
                    .sectionheader(context:context),
                    .recentItemList(for: index, context: context,recentPostNumber:5,words:300),
                    .sectionheader(context:context,showTitle:false)
                ),
                .footer(for: context.site)
            )
        )
    }

    func makeSectionHTML(
        for section: Section<Site>,
        context: PublishingContext<Site>
    ) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: section, on: context.site),
            .body(
                .header(for: context, selectedSection: section.id),
                .wrapper(
                    //                    .h1(.text(section.title)),
                    .itemList(for: section.items, on: context.site)
                ),
                .footer(for: context.site)
            )
        )
    }

    //文章页面
    func makeItemHTML(
        for item: Item<Site>,
        context: PublishingContext<Site>
    ) throws -> HTML {
        var previous:Item<Site>? = nil
        var next:Item<Site>? = nil

        let items = context.allItems(sortedBy: \.date,order: .descending)
        guard let index = items.firstIndex(where: {$0 == item}) else {
            return HTML()
        }

        if index > 0 {
            previous = items[index - 1]
        }

        if index < (items.count - 1) {
            next = items[index + 1]
        }

        return HTML(
            .lang(context.site.language),
            .head(for: item, on: context.site),
            .body(
                .class("item-page"),
                .header(for: context, selectedSection: item.sectionID),
                .wrapper(
                    .article(
                        .div(
                            .h1(.text(item.title))
                        ),
                        .div(
                            .tagList(for: item, on: context.site,displayDate:true),
                            .div(
                                .class("content"),
                                .contentBody(item.body)
                            )
                        )
                    ),
                    .itemNavigator(previousItem:previous,nextItem:next),
                    .footer(for: context.site)
                )
            )
        )
    }

    //Pages,不属于Section
    func makePageHTML(
        for page: Page,
        context: PublishingContext<Site>
    ) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body(
                //需要特殊处理.在publish中是当做page来显示的.为了nav的选中显示正常
                .if(
                    page.path == Path("about"),
                    .header(
                        for: context,
                        selectedSection: FatbobmanBlog.SectionID.about as? Site.SectionID
                    ),
                    else: .header(for: context, selectedSection: nil)
                ),
                .div(
                    .class("about"),
                    .wrapper(
                        .contentBody(page.body)
                    )
                ),
                .footer(for: context.site)
            )
        )
    }

    func makeTagListHTML(
        for page: TagListPage,
        context: PublishingContext<Site>
    ) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body(
                .header(for: context, selectedSection: nil),
                .wrapper(
                    .h4(
                        .class("tags-title"),
                        .text("全部标签")
                    ),
                    .ul(
                        .class("all-tags"),
                        .forEach(page.tags.sorted()) { tag in
                            .li(
                                .class(tag.colorfiedClass),
                                .a(
                                    .href(context.site.path(for: tag)),
                                    .text("\(tag.string) (\(tag.count))")
                                )
                            )
                        }
                    )
                ),
                .footer(for: context.site)
            )
        )
    }

    func makeTagDetailsHTML(
        for page: TagDetailsPage,
        context: PublishingContext<Site>
    ) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body(
                .header(for: context, selectedSection: nil),
                .wrapper(
                    .div(
                        .class("float-container "),
                        .div(
                            .class("tag-detail-header"),
                            .text("标签: "),
                            .span(.class(page.tag.colorfiedClass), .text(page.tag.string)),
                            .a(
                                .class("browse-all-tag"),
                                .text("查看全部标签"),
                                .href(context.site.tagListPath)
                            )
                        )
                        ),
                    .itemList(
                        for: context.items(
                            taggedWith: page.tag,
                            sortedBy: \.date,
                            order: .descending
                        ),
                        on: context.site
                    )
                ),
                .footer(for: context.site)
            )
        )
    }
}

extension Node where Context == HTML.BodyContext {
    fileprivate static func wrapper(_ nodes: Node...) -> Node {
        .div(.class("wrapper"), .group(nodes))
    }

    //页面头部.
    fileprivate static func header<T: Website>(
        for context: PublishingContext<T>,
        selectedSection: T.SectionID?
    ) -> Node {
        let sectionIDs = T.SectionID.allCases
        return .header(
            .wrapper(
                .div(
                    .class("logo"),
                    .a(
                        .href("/"),
                        .h2("肘子的SWIFT记事本")
                    )
                ),
                .if(sectionIDs.count > 1, nav(for: context, selectedSection: selectedSection))
            )
        )
    }

    fileprivate static func nav<T: Website>(
        for context: PublishingContext<T>,
        selectedSection: T.SectionID?
    ) -> Node {
        let sectionIDs = T.SectionID.allCases
        return
            .nav(
                .ul(
                    .forEach(sectionIDs) { section in
                        .li(
                            .a(
                                .if(
                                    section as! FatbobmanBlog.SectionID
                                        == FatbobmanBlog.SectionID.about,
                                    .class("selected")
                                ),
                                .class(section == selectedSection ? "selected" : ""),
                                .if(section as! FatbobmanBlog.SectionID == FatbobmanBlog.SectionID.index,
                                    .href(context.index.path),
                                    else:.href(context.sections[section].path)),
                                .text(context.sections[section].title)


                            )
                        )
                    }
                )
            )

    }

    fileprivate static func itemList<T: Website>(for items: [Item<T>], on site: T) -> Node {
        return .ul(
            .class("item-list"),
            .forEach(items) { item in
                .li(
                    .article(
                        .h1(
                            .class("itme-list-title"),
                            .a(
                                .href(item.path),
                                .text(item.title)
                            )
                        ),
                        .tagList(for: item, on: site,displayDate:true),
                        .p(.text(item.description))
                    )
                )

            }
        )
    }


    static func tagList<T: Website>(for item: Item<T>, on site: T,displayDate:Bool = false) -> Node {
        return .ul(
            .class("tag-list"),
            .forEach(item.tags){ tag in
                .li(
                    .class(tag.colorfiedClass),
                    .a(
                        .href(site.path(for:tag)),
                        .text(tag.string)
                    )
                )
            },
            .li(
                .class("tag tagdate"),
                .if(displayDate,
                    .text(formatter.string(from: item.date))
                )
            )


        )
    }


    static func tagAndDate(tags:Node,date:Date) -> Node{
        return
            .div(
                .class("publishDate"),
                .table(
                    .tr(
                        .td(
                            tags
                        ),
                        .td(
                            .text(formatter.string(from: date))
                        )
                    )
                )
            )
    }

    fileprivate static func footer<T: Website>(for site: T) -> Node {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return .footer(
            .p(
                .text("Copyright &copy; 徐杨 \(formatter.string(from: Date())) "),
                .a(
                    .text("辽ICP备20006550"),
                    .href("http://beian.miit.gov.cn")
                )
            ),
            .p(
                .text("Generated using "),
                .a(
                    .text("Publish"),
                    .href("https://github.com/johnsundell/publish")
                )
            ),
            .ul(
                .li(
                .a(
                    .text("Twitter"),
                    .href("https://twitter.com/fatbobman")
                )),
                .li(
                    .a(
                        .text("Github"),
                        .href("https://github.com/fatbobman/")
                    )
                ),
                .li(
                    .a(
                        .text("知乎"),
                        .href("https://www.zhihu.com/people/fatbobman3000")
                    )
                ),
                .li(
                .a(
                    .text("RSS"),
                    .href("/feed.rss")
                )
                )

            ),
            .raw(googleAndBaidu)
        )
    }


}

let googleAndBaidu: String =
    """
    <script>
        // dynamic User by Hux
        var _gaId = 'UA-165296388-1';
        var _gaDomain = 'fatbobman.com';

        // Originial
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

        ga('create', _gaId, _gaDomain);
        ga('send', 'pageview');
    </script>

    <!-- Baidu Tongji -->

    <script>
        // dynamic User by Hux
        var _baId = '14e5d60a3ea6276655f9d14c58b1fcd0';

        // Originial
        var _hmt = _hmt || [];
        (function() {
          var hm = document.createElement("script");
          hm.src = "//hm.baidu.com/hm.js?" + _baId;
          var s = document.getElementsByTagName("script")[0];
          s.parentNode.insertBefore(hm, s);
        })();
    </script>
    """

var formatter:DateFormatter{
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}
