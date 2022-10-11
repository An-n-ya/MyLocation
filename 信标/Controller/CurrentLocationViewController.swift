//
//  ViewController.swift
//  信标
//
//  Created by 张环宇 on 2022/9/29.
//

import UIKit
import CoreLocation
import CoreData

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!

    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?

    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?

    // core data context
    var managedObjectContext: NSManagedObjectContext!

    // region Actions
    @IBAction func getLocation() {
        if updatingLocation {
            // 如果正在获取位置，说明点击了 "停止"
            stopLocationManager()
        } else {
            // 通过delegate调用获取位置方法

            // 获取权限
            let authStatus = locationManager.authorizationStatus
            if authStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
                return
            }

            if authStatus == .denied || authStatus == .restricted {
                // 当位置权限被禁用时，调用showLocationServicesDeniedAlert方法
                showLocationServicesDeniedAlert()
                return
            }

            startLocationManager()
        }
        updateLabels()
    }
    // endregion

    // region Delegate

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!

        // 让定位服务请求不那么快
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }

        // 过滤掉无效数据
        if newLocation.horizontalAccuracy < 0 {
            return
        }

        // 如果更精确了，就更新location
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy{
            location = newLocation
            lastLocationError = nil

            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                // 如果精度足够了，就让定位服务停下来
                stopLocationManager()
            }
            updateLabels()

            // 经纬度转地址
            if !performingReverseGeocoding {
                print("*** 开始转换经纬度 ***")
                performingReverseGeocoding = true

                geocoder.reverseGeocodeLocation(newLocation) { placemark, error in
                    self.lastLocationError = error
                    if error == nil, let places = placemark, !places.isEmpty {
                        self.placemark = places.last!
                    } else {
                        self.placemark = nil
                    }
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                }
            }
        }

    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error.localizedDescription)")
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            // 如果Core Location还在尝试
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }

    // endregion

    // region overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    // endregion


    // region Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagLocation" {
            let controller = segue.destination as! LocationDetailsViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            // 把core data context传递过去
            controller.managedObjectContext = managedObjectContext
        }
    }
    // endregion

    // region helper
    func showLocationServicesDeniedAlert() {
        // 位置权限被禁用时的弹窗
        let alert = UIAlertController(
                title: "位置权限被禁用", message: "请在设置中打开此应用的位置权限", preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "好", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    func updateLabels() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""

            // 解析地址
            if let placemark = placemark {
                addressLabel.text = string(from: placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "定位中..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "定位错误"
            } else {
                addressLabel.text = "无效地址"
            }
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
//            messageLabel.text = "请点击[获取我的位置]"
            let statusMessage: String
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "定位服务被禁用"
                } else {
                    statusMessage = "定位时发生错误"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "定位服务被禁用"
            } else if updatingLocation {
                statusMessage = "定位中..."
            } else {
                statusMessage = "请点击[获取我的位置]"
            }
            messageLabel.text = statusMessage
        }
        configureGetButton()
    }

    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }

    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            // 10m的目标精确度
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }

    func configureGetButton() {
        if updatingLocation {
            getButton.setTitle("停止", for: .normal)
        } else {
            getButton.setTitle("获取我的位置", for: .normal)
        }
    }

    func string(from placemark: CLPlacemark) -> String {
        var line1 = ""
        if let tmp = placemark.subThoroughfare {
            line1 += tmp + " "
        }
        if let tmp = placemark.thoroughfare {
            line1 += tmp
        }

        var line2 = ""
        if let tmp = placemark.locality {
            line2 += tmp + " "
        }
        if let tmp = placemark.administrativeArea {
            line2 += tmp + " "
        }
        if let tmp = placemark.postalCode {
            line2 += tmp
        }
        print(line1)
        print(line2)
        return line1 + "\n" + line2
    }

    // endregion


}

