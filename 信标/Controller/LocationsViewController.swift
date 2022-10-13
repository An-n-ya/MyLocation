//
//  LocationsViewController.swift
//  信标
//
//  Created by 张环宇 on 2022/10/13.
//


import UIKit
import CoreData
import CoreLocation

class LocationsViewController: UITableViewController {
    var managedObjectContext: NSManagedObjectContext!
    var locations = [Location]()

    // region Table View Delegates

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationCell

        let location = locations[indexPath.row]

        cell.configure(for: location)

        return cell
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        let fetchRequest = NSFetchRequest<Location>()
        // 查找设置
        let entity = Location.entity()
        fetchRequest.entity = entity

        // 排序设置
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            locations = try managedObjectContext.fetch(fetchRequest)
        } catch {
            fatalCoreDataError(error)
        }
    }

    // endregion


    // region Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocation" {
            let controller = segue.destination as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext

            if let indexPath = tableView.indexPath(for: sender as! UITableViewCell) {
                // 判断用户点击的是哪个cell，给下一个controller赋值
                let location = locations[indexPath.row]
                controller.locationToEdit = location
            }
        }
    }

    // endregion
}
