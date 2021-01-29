//
//  File.swift
//  
//
//  Created by Yang Xu on 2021/1/22.
//


import Foundation
import Publish

// 如果直接设置 SectionID的raw值的话,文件的目录名也会发生变化.还是这种方式灵活度更大

extension PublishingStep where Site == FatbobmanBlog {
    static func setSctionTitle() -> Self {
        .step(named: "setSctionTitle" ){ content in
            content.mutateAllSections { section in
                switch section.id {
                case .index:
                    section.title = "首页"
                case .posts:
                    section.title = "文章"
                case .project:
                    section.title = "我的APP"
                case .about:
                    section.title = "关于"
                case .tags:
                    section.title = "标签"
                }
            }
        }
    }
}




