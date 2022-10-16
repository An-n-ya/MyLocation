//
// Created by 张环宇 on 2022/10/16.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    @IBOutlet var mapView: MKMapView!

    // core data context
    var managedObjectContext: NSManagedObjectContext! {
        didSet {
            NotificationCenter.default.addObserver(
                    forName: Notification.Name.NSManagedObjectContextObjectsDidChange,
                    object: managedObjectContext,
                    queue: OperationQueue.main
            ) { _ in
                if self.isViewLoaded {
                    // 修改location后进行更新
                    // 这里是进行全局更新（可能效率会很低）
                    // 可以通过这里的闭包函数的参数得到notification
                    // 通过notification.userInfo得知是哪个location发生了更新
                    // 从而实现单点更
                    self.updateLocations()
                }
            }
        }
    }

    // location
    var locations = [Location]()

    // region overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocations()
        showLocations()
    }

    // endregion

    // region Actions

    @IBAction func showUser() {
        // 缩放坐标尺到1000*1000
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }

    @IBAction func showLocations() {
        let theRegion = region(for: locations)
        mapView.setRegion(theRegion, animated: true)
    }

    // endregion

    // region 帮助函数

    func updateLocations() {
        // 先清除之前的locations
        mapView.removeAnnotations(locations)

        let entity = Location.entity()

        let fetchRequest = NSFetchRequest<Location>()
        fetchRequest.entity = entity

        // 使用try! 用来断言下面的语句不会出错（因为是系统函数，出错可能性小）
        // 获得数据库里的所有locations
        locations = try! managedObjectContext.fetch(fetchRequest)
        // 添加标签
        mapView.addAnnotations(locations)
    }

    func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
        let region: MKCoordinateRegion

        switch annotations.count {
        case 0:
            // 如果没有location就显示user位置
            region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        case 1:
            // 如果只有一个location，就显示这个locatin
            let annotation = annotations[0]
            region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        default:
            var topLeft = CLLocationCoordinate2D(latitude: -90, longitude: 180)
            var bottomRight = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            // 找到最左上角和最右下角的点
            for annotation in annotations {
                topLeft.latitude = max(topLeft.latitude, annotation.coordinate.latitude)
                topLeft.longitude = min(topLeft.longitude, annotation.coordinate.longitude)
                bottomRight.latitude = min(bottomRight.latitude, annotation.coordinate.latitude)
                bottomRight.longitude = max(bottomRight.longitude, annotation.coordinate.longitude)
            }

            let center = CLLocationCoordinate2D(latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude) / 2, longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude))

            let extraSpace = 1.1
            let span = MKCoordinateSpan(
                    latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace,
                    longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)

            region = MKCoordinateRegion(center: center, span: span)
        }

        return mapView.regionThatFits(region)
    }

    @objc func showLocationDetails(_ sender: UIButton) {
        // 手动segue
        performSegue(withIdentifier: "EditLocation", sender: sender)
    }

    // endregion

    // region Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocation" {
            let controller = segue.destination as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext

            let button = sender as! UIButton
            // 从tag中得知是哪个location被选择
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }

    // endregion

}

extension MapViewController: MKMapViewDelegate {
    // 要想使delegate生效，需要在storyboard上添加delegate到viewController
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        print("annotation \(annotation)")
        // 创建每一个pin view，相当于table 的 table cell
        guard annotation is Location else {
            return nil
        }
        print("location inner")
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView.isEnabled = true
            pinView.canShowCallout = true
            pinView.animatesDrop = false
            pinView.pinTintColor = UIColor(
                    red: 0.32,
                    green: 0.82,
                    blue: 0.4,
                    alpha: 1
            )

            // 创建几个button view
            let rightButton = UIButton(type: .detailDisclosure)
            rightButton.addTarget(self, action: #selector(showLocationDetails(_:)), for: .touchUpInside)
            // 加到pinView的右边
            pinView.rightCalloutAccessoryView = rightButton

            annotationView = pinView
        }

        if let annotationView = annotationView {
            annotationView.annotation = annotation
            let button = annotationView.rightCalloutAccessoryView as! UIButton
            if let index = locations.firstIndex(of: annotation as! Location) {
                // 给每个button编号，这个编号用来跳转到编辑页面
                button.tag = index
            }
        }

        return annotationView

    }
}
