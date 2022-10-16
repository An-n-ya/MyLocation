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
