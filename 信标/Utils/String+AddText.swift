//
// Created by 张环宇 on 2022/10/20.
//

extension String {
    mutating func add(
            text: String?,
            separateBy separator: String = ""
    ) {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}