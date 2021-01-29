//
//  File.swift
//  
//
//  Created by Yang Xu on 2021/1/29.
//

import Foundation
import Publish

extension Plugin{
    /// 为生成RSS 做配置
    /// - Parameter including: 需要处理的section,
    /// - Returns: Plugin
    static func rssSetting(including:Set<Site.SectionID> = []) -> Self{
        return Plugin(name: "Rss Properties Setting"){ content in
            content.mutateAllSections{ section in
                if !including.isEmpty {
                    guard including.contains(section.id) else {return}
                }

                //设置你的RSS属性.这个属性Publish中已经预留了接口
                let rss = ItemRSSProperties(guid: "rss guid:", titlePrefix: "前缀:", titleSuffix: "尾缀:", bodyPrefix: "内容前缀:", bodySuffix: "内容尾缀", link: nil)

                section.mutateItems{ item in
                    item.rssProperties = rss
                }
            }
        }
    }
}


