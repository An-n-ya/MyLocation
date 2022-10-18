//
// Created by 张环宇 on 2022/10/18.
//

import UIKit

extension UIImage {
    func resized(withBounds bounds: CGSize) -> UIImage {
        let horizontalRatio = bounds.width / size.width
        let verticalRatio = bounds.height / size.height
        // 取较小者
        let ratio = min(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        // 开始画图
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        // 调整大小
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
