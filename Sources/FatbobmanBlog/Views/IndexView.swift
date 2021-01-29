//
//  File.swift
//
//
//  Created by Yang Xu on 2021/1/25.
//

import Foundation
import Plot
import Publish

extension Node where Context == HTML.BodyContext {
    static func recentItemList<Site: Website>(
        for index: Index,
        context: PublishingContext<Site>,
        recentPostNumber: Int = 5,
        words: Int = 200
    ) -> Node {
        let items = context.allItems(sortedBy: \.date, order: .descending)
        guard items.count > 1 else {
            return .empty
        }
        
        return
            .div(
                .class("index-list"),
                .ul(
                    .class("indexul"),
                    .forEach(items.prefix(recentPostNumber)) { item in
                        .li(
                            .class("indexli"),
                            .div(
                                .class("index-title"),
                                .a(
                                    .href(item.path),
                                    .h1(.text(item.title))
                                )
                            ),
                            .div(
                                .tagList(for: item, on: context.site, displayDate: true)
                            ),
                            .div(
                                .class("content"),
                                .article(
                                    .raw(
                                        item.content.body.htmlDescription(
                                            words: 800,
                                            keepImageTag: true,
                                            ellipsis: "..."
                                        )
                                    )
                                ),
                                .div(
                                    .class("index-item-more float-container"),
                                    .a(
                                        .href(item.path),
                                        .text("查看全文")
                                    )
                                )
                            )
                        )

                    }
                )
            )

    }

    static func gridBox<Site: Website>(context: PublishingContext<Site>) -> Node {
        return
            .ul(
                .class("item-list feature grid compact"),
                .li(
                    .a(
                        .href("/"),
                        .article(
                            .text("hgdsg"),
                            .p(.text("sdg"))

                        )
                    )
                ),
                .li(
                    .text("asadgasg")
                ),
                .li(
                    .text("sdgasasdsgasd")
                )
            )
    }

    static func sectionheader<Site: Website>(
        context: PublishingContext<Site>,
        showTitle: Bool = true
    ) -> Node {
        return .div(
            .class("section-header float-container"),
            .if(showTitle, .h2(.text("最新文章"))),
            .a(
                .class("browse-all"),
                .href("/posts/"),
                .text("显示全部文章(\(context.itemCount))")
            )

        )
    }

    static func itemNavigator<Site: Website>(previousItem: Item<Site>?, nextItem: Item<Site>?)
        -> Node
    {
        .div(
            .class("item-navigator"),
            .table(
                .tr(
                    .if(
                        previousItem != nil,
                        .td(
                            .class("previous-item"),
                            .a(

                                .href(previousItem?.path ?? Path("")),
                                .text((previousItem?.title ?? ""))
                            )
                        ),
                        else:
                            .td(
                                .text("")
                            )

                    ),
                    .if(
                        nextItem != nil,
                        .td(
                            .class("next-item"),
                            .a(

                                .href(nextItem?.path ?? Path("")),
                                .text((nextItem?.title ?? ""))
                            )
                        ),
                        else:
                            .td(
                                .text("")
                            )
                    )
                )
            )
        )
    }
}

extension Node where Context == HTML.ListContext {
    static func itemDate(date: Date) -> Node {
        return .li(
            .class("teg-list date"),
            .text(formatter.string(from: date))
        )
    }
}


