//
// Created by 张环宇 on 2022/10/8.
//

import UIKit

class HudView: UIView {
    var text = ""

    // 静态方法（类方法）
    class func hud(inView view: UIView, animated: Bool) -> HudView {
        // HubView(:frame:)继承自UIView
        let hudView = HudView(frame: view.bounds)
        hudView.isOpaque = false

        view.addSubview(hudView)
        view.isUserInteractionEnabled = false

//        hudView.backgroundColor = UIColor(red: 0, green: 0, blue: 0.5, alpha: 0.5)
        hudView.show(animated: animated)
        return hudView
    }

    override func draw(_ rect: CGRect) {
        let boxWidth: CGFloat = 96
        let boxHeight: CGFloat = 96

        let boxRect = CGRect(
                x: round((bounds.size.width - boxWidth) / 2),
                y: round((bounds.size.height - boxHeight) / 2),
                width: boxWidth,
                height: boxHeight
        )

        // 圆角矩形
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        // 淡灰色
        UIColor(white: 0.3, alpha: 0.8).setFill()
        roundedRect.fill()

        // 画勾
        guard let image = UIImage(named: "Checkmark") else { return }
        // 居中放置
        let imagePoint = CGPoint(
                x: center.x - round(image.size.width / 2),
                y: center.y - round(image.size.height / 2) - boxHeight / 8)
        image.draw(at: imagePoint)

        // 展示提示文字
        let attribs = [
            // 使用代码的方式设置字号和颜色
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]

        let textSize = text.size(withAttributes: attribs)

        // 文字位置居中偏下
        let textPont = CGPoint(
                x: center.x - round(textSize.width / 2),
                y: center.y - round(textSize.height / 2) + boxHeight / 4
        )
        text.draw(at: textPont, withAttributes: attribs)
    }

    // region 帮助函数

    func show(animated: Bool) {
        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 1.3, y: 1.3)

//            UIView.animate(withDuration: 0.3) {
//                // 大小和透明度还原
//                self.alpha = 1
//                self.transform = CGAffineTransform.identity
//            }
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: [],
                animations: {
                    // 这里是闭包， 因此需要使用self引用外边作用域的变量
                    self.alpha = 1
                    self.transform = CGAffineTransform.identity
                },
                completion: nil
            )
        }

    }

    func hide() {
        superview?.isUserInteractionEnabled = true
        removeFromSuperview()
    }

    // endregion
}
