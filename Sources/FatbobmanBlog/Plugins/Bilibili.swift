//
//  File.swift
//
//
//  Created by Yang Xu on 2021/1/29.
//

import Foundation
import Ink
import Sweep

/*

```bilibili
aid: 500064395
danmu: true
```

*/

var bilibili = Modifier(target: .codeBlocks) { html, markdown in
    guard let content = markdown.substrings(between: "```bilibili\n", and: "\n```").first else {
        return html
    }
    var aid: String = ""
    var danmu: Int = 1
    content.scan(using: [
        Matcher(identifier: "aid: ", terminator: "\n", allowMultipleMatches: false) { match, _ in
            aid = String(match)
        },
        Matcher(identifiers: ["danmu: "], terminators: ["\n", .end], allowMultipleMatches: false) {
            match,
            _ in
            danmu = match == "true" ? 1 : 0
        },
    ])

    return
        """
        <div style="position: relative; padding: 30% 45% ; margin-top:20px;margin-bottom:20px">
        <iframe style="position: absolute; width: 100%; height: 100%; left: 0; top: 0;" src="https://player.bilibili.com/player.html?aid=\(aid)&page=1&as_wide=1&high_quality=1&danmaku=\(danmu)" frameborder="no" scrolling="no"></iframe>
        </div>
        """
}
