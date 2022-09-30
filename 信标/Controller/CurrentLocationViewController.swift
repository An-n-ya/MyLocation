//
//  ViewController.swift
//  信标
//
//  Created by 张环宇 on 2022/9/29.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!

    let locationManager = CLLocationManager()
    var location: CLLocation?

    // region Actions
    @IBAction func getLocation() {
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

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }
    // endregion

    // region Delegate

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        location = newLocation
        updateLabels()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error.localizedDescription)")
    }

    // endregion

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
    }

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
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            messageLabel.text = "请点击[获取我的位置]"
        }
    }

    // endregion


}

