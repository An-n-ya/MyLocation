//
//  LocationCell.swift
//  信标
//
//  Created by 张环宇 on 2022/10/13.
//

import UIKit

class LocationCell: UITableViewCell {
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var photoImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // 缩略图
    func thumbnail(for location: Location) -> UIImage {
        if location.hasPhoto, let image = location.photoImage {
            // 如果有照片，把照片unwrap出来
            // 调整大小
            return image.resized(withBounds: CGSize(width: 52, height: 52))
        }
        // 否则返回空image
        return UIImage()
    }

    func configure(for location: Location) {
        // 设置照片
        photoImageView.image = thumbnail(for: location)
        if location.locationDescription.isEmpty {
            descriptionLabel.text = "(无描述)"
        } else {
            descriptionLabel.text = location.locationDescription
        }

        if let placemark = location.placemark {
            var text = ""
            if let tmp = placemark.subThoroughfare {
                text += tmp + " "
            }
            if let tmp = placemark.thoroughfare {
                text += tmp + ", "
            }
            if let tmp = placemark.locality {
                text += tmp
            }
            addressLabel.text = text
        } else {
            addressLabel.text = String(
                    format: "纬度: %.8f, 经度: %.8f",
                    location.latitude,
                    location.longitude
            )
        }
    }
}
