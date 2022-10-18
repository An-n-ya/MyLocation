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
    // 把fetch相关的初始化工作都放到lazy里
    lazy var fetchedResultsController: NSFetchedResultsController<Location> = {
        let fetchRequest = NSFetchRequest<Location>()

        let entity = Location.entity()
        fetchRequest.entity = entity

        let sort1 = NSSortDescriptor(key: "category", ascending: true)
        let sort2 = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sort1, sort2]

        fetchRequest.fetchBatchSize = 20

        let fetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: self.managedObjectContext,
                // 按category分section
                sectionNameKeyPath: "category",
                cacheName: "Locations")

        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    deinit {
        fetchedResultsController.delegate = nil
    }

    // region Table View Delegates

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationCell


        let location = fetchedResultsController.object(at: indexPath)
        cell.configure(for: location)

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let location = fetchedResultsController.object(at: indexPath)
            // 执行删除照片操作
            location.removePhotoFile()
            managedObjectContext.delete(location)
            do {
                try managedObjectContext.save()
            } catch {
                fatalCoreDataError(error)
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        fetchedResultsController.sections!.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        performFetch()

        navigationItem.rightBarButtonItem = editButtonItem
    }
    // endregion

    // region Helper Function
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
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
                let location = fetchedResultsController.object(at: indexPath)
                controller.locationToEdit = location
            }
        }
    }

    // endregion
}

extension LocationsViewController: NSFetchedResultsControllerDelegate {
    // cell或者说行改变
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("*** NSFetchedResults insert cell")
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            print("*** NSFetchedResults delete cell")
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            print("*** NSFetchedResults update cell")
            if let cell = tableView.cellForRow(at: indexPath!) as? LocationCell {
                let location = controller.object(at: indexPath!) as! Location
                cell.configure(for: location)
            }
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        @unknown default:
            print("*** NSFetchedResults 位置类型")
        }
    }

    // section改变
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            print("*** NSFetchedResultsChange insert section")
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            print("*** NSFetchedResultsChange delete section")
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .update:
            print("*** NSFetchedResultsChange section更新")
        case .move:
            print("*** NSFetchedResultsChange section移动")
        @unknown default :
            print("*** NSFetchedResultsChange 位置类型")
        }
    }

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("*** controllerWillChangeContent")
        // 在数据改变的时候更新tableView
        tableView.beginUpdates()
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("*** controller完成更新")
        tableView.endUpdates()
    }
}
