//
//  Location+CoreDataProperties.swift
//  信标
//
//  Created by 张环宇 on 2022/10/10.
//
//

import Foundation
import CoreData
import CoreLocation


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var locationDescription: String
    @NSManaged public var date: Date
    @NSManaged public var category: String
    @NSManaged public var placemark: CLPlacemark?
    // 存储照片的编号
    @NSManaged public var photoID: NSNumber?

}

extension Location : Identifiable {

}
