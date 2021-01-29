//
//  File.swift
//  
//
//  Created by Yang Xu on 2021/1/29.
//

import Foundation
import Publish
import Ink

extension PublishingStep{
    static func addModifier(modifier:Modifier,modifierName name:String = "") -> Self{
        .step(named: "addModifier \(name)"){ context in
            context.markdownParser.addModifier(modifier)
        }
    }
}
