//
//  File.swift
//  
//
//  Created by Yang Xu on 2021/1/29.
//

import Foundation
import Publish

extension Plugin{
    static func setDateFormatter() -> Self{
        Plugin(name: "setDateFormatter"){ context in
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            context.dateFormatter = formatter
        }
    }
}

