//
//  File.swift
//  
//
//  Created by Yang Xu on 2021/1/28.
//

import Foundation
import Publish

//计算每个tag的数量
extension Plugin{
    static func countTag() -> Self{
        return Plugin(name: "countTag"){ content in
            CountTag.count(content: content)
        }
    }
}

struct CountTag{
    static var count:[Tag:Int] = [:]
    static func count<T:Website>(content:PublishingContext<T>){
        for tag in content.allTags{
            count[tag] =  content.items(taggedWith: tag).count
        }
    }
}

extension Tag{
    public var count:Int{
        CountTag.count[self] ?? 0
    }
}

//item_count
extension PublishingContext{
    var itemCount:Int{
        allItems(sortedBy: \.date,order: .descending).count
    }
}
