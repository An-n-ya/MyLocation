//
//  ViewController.swift
//  信标
//
//  Created by 张环宇 on 2022/9/29.
//

import UIKit
import CoreLocation
import CoreData
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!

    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?

    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?

    var soundID: SystemSoundID = 0

    // core data context
    var managedObjectContext: NSManagedObjectContext!

    var logoVisible = false

    lazy var logoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(
                UIImage(named: "Logo"), for: .normal)
        button.sizeToFit()
        button.addTarget(
                self, action: #selector(getLocation), for: .touchUpInside)
        button.center.x = self.view.bounds.midX
        button.center.y = 220
        return button
    }()

    // region Actions
    @IBAction func getLocation() {

        if logoVisible {
            hideLogoView()
        }

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
                        if self.placemark == nil {
                            // 在第一次请求成功的时候播放音效
                            self.playSoundEffect()
                        }
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
        // 加载音效
        loadSoundEffect("Sound.caf")
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
            // 隐藏标签
            latitudeTextLabel.isHidden = false
            longitudeTextLabel.isHidden = false
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
            latitudeTextLabel.isHidden = true
            longitudeTextLabel.isHidden = true
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
                showLogoView()
            }
            messageLabel.text = statusMessage
        }
        configureGetButton()
    }

    func showLogoView() {
        if !logoVisible {
            logoVisible = true
            containerView.isHidden = true
            view.addSubview(logoButton)
        }
    }

    func hideLogoView() {
        if !logoVisible {return}
        logoVisible = false
        containerView.isHidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2

        let centerX = view.bounds.midX

        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.isRemovedOnCompletion = false
        panelMover.fillMode = CAMediaTimingFillMode.forwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(cgPoint: containerView.center)
        panelMover.toValue = NSValue(
                cgPoint: CGPoint(x: centerX, y: containerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(
                name: CAMediaTimingFunctionName.easeOut)
        panelMover.delegate = self
        containerView.layer.add(panelMover, forKey: "panelMover")

        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.isRemovedOnCompletion = false
        logoMover.fillMode = CAMediaTimingFillMode.forwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(cgPoint: logoButton.center)
        logoMover.toValue = NSValue(
                cgPoint: CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(
                name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoMover, forKey: "logoMover")

        let logoRotator = CABasicAnimation(
                keyPath: "transform.rotation.z")
        logoRotator.isRemovedOnCompletion = false
        logoRotator.fillMode = CAMediaTimingFillMode.forwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * Double.pi
        logoRotator.timingFunction = CAMediaTimingFunction(
                name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoRotator, forKey: "logoRotator")
    }

    // animation

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        containerView.layer.removeAllAnimations()
        containerView.center.x = view.bounds.size.width / 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
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
        let spinnerTag = 1000
        if updatingLocation {
            getButton.setTitle("停止", for: .normal)

            if view.viewWithTag(spinnerTag) == nil {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.center = messageLabel.center
                spinner.center.y += spinner.bounds.size.height / 2 + 25
                spinner.startAnimating()
                spinner.tag = spinnerTag
                containerView.addSubview(spinner)
            }
        } else {
            getButton.setTitle("获取我的位置", for: .normal)

            if let spinner = view.viewWithTag(spinnerTag) {
                spinner.removeFromSuperview()
            }
        }
    }

    func string(from placemark: CLPlacemark) -> String {
        var line1 = ""
        line1.add(text: placemark.subThoroughfare)
        line1.add(text: placemark.thoroughfare, separateBy: ", ")
        line1.add(text: placemark.locality, separateBy: ", ")

        var line2 = ""
        line2.add(text: placemark.administrativeArea, separateBy: " ")
        line2.add(text: placemark.postalCode, separateBy: ", ")
        line2.add(text: placemark.country)
        return line1 + "\n" + line2
    }

    // endregion


    // region 声音效果

    func loadSoundEffect(_ name: String) {
        if let path = Bundle.main.path(forResource: name, ofType: nil) {
            let fileURL = URL(fileURLWithPath: path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
            if error != kAudioServicesNoError {
                print("Error code \(error) loading sound: \(path)")
            }
        }
    }

    func unloadSoundEffect() {
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0
    }

    func playSoundEffect() {
        AudioServicesPlaySystemSound(soundID)
    }

    // endregion

}

