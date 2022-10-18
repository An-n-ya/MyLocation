//
//  Location+CoreDataClass.swift
//  信标
//
//  Created by 张环宇 on 2022/10/10.
//
//

import Foundation
import CoreData
import MapKit

@objc(Location)
public class Location: NSManagedObject, MKAnnotation {
    var hasPhoto: Bool {
        photoID != nil
    }

    var photoURL: URL {
        assert(photoID != nil, "没有photoID！")
        let filename = "Photo-\(photoID!.intValue).jpg"
        return applicationDocumentsDirectory.appendingPathComponent(filename)
    }

    var photoImage: UIImage? {
        // 从photoURL中取出地址，返回UIImage
        UIImage(contentsOfFile: photoURL.path)
    }

    class func nextPhotoID() -> Int {
        // 下一个照片的ID
        // 使用 UserDefaults存储当前ID值(比CoreData来的方便)
        let userDefaults = UserDefaults.standard
        let currentID = userDefaults.integer(forKey: "PhotoID") + 1
        userDefaults.set(currentID, forKey: "PhotoID")
        return currentID
    }

    // 删除照片
    func removePhotoFile() {
        if hasPhoto {
            do {
                try FileManager.default.removeItem(at: photoURL)
            } catch {
                print("删除照片失败：\(error)")
            }
        }
    }

    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }

    public var title: String? {
        if locationDescription.isEmpty {
            return "(无描述)"
        } else {
            return locationDescription
        }
    }

    public var subtitle: String? {
        return category
    }
}
