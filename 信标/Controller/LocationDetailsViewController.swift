//
//  LocationDetailsViewController.swift
//  信标
//
//  Created by 张环宇 on 2022/10/5.
//

import UIKit
import CoreLocation
import CoreData

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()


class LocationDetailsViewController: UITableViewController {
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!

    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?

    // 默认值
    var categoryName = "无标签"
    var date = Date()
    var descriptionText = ""
    var locationToEdit: Location? {
        didSet {
            if let location = locationToEdit {
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                placemark = location.placemark
            }
        }
    }


    // core data context
    var managedObjectContext: NSManagedObjectContext!


    // region Actions

    @IBAction func done() {
        // 完成时展示HUD动画
        guard let mainView = navigationController?.parent?.view else {return}
        let hudView = HudView.hud(inView: mainView, animated: true)

        let location: Location
        if let tmp = locationToEdit {
            hudView.text = "已更新"
            location = tmp
        } else {
            hudView.text = "已标记"
            location = Location(context: managedObjectContext)
        }

        do {
        // core data 的实例
            location.locationDescription = descriptionTextView.text
            location.category = categoryName
            location.latitude = coordinate.latitude
            location.longitude = coordinate.longitude
            location.date = date
            location.placemark = placemark

            try managedObjectContext.save()
            afterDelay(0.6) {
                hudView.hide()
                self.navigationController?.popViewController(animated: true)
            }

        } catch {
            // 把错误信息发送给NotificationCenter
            fatalCoreDataError(error)
        }


    }

    @IBAction func cancel() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func categoryPickerDidPickCategory(
            _ segue: UIStoryboardSegue
    ) {
        let controller = segue.source as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }

    // endregion

    // region overrides
    @objc func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.location(in: tableView)
        // 获取当前触摸点对应的indexPath
        let indexPath = tableView.indexPathForRow(at: point)

        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 {
            // 如果已经在输入框内， 就什么都不做
            return
        }

        // 取消聚焦
        descriptionTextView.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let location = locationToEdit {
            // 如果locationToEdit有值，说明是修改cell
            title = "编辑位置"
        }
        descriptionTextView.text = descriptionText
        dateLabel.text = format(date: date)
        categoryLabel.text = categoryName

        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)

        if let placemark = placemark {
            addressLabel.text = string(from: placemark)
        } else {
            addressLabel.text = "未找到位置"
        }

        dateLabel.text = format(date: Date())

        // 隐藏键盘的条件
        let gestureRecognizer = UITapGestureRecognizer(
                target: self, action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)

    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
            // 只有前两个section包含可编辑的项目
            return indexPath
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            // 增大输入框的聚焦范围
            descriptionTextView.becomeFirstResponder()
        } else if (indexPath.section == 1 && indexPath.row == 0) {
            // 添加照片
//            takePhotoWithCamera()
//            choosePhotoFromLibrary()
            pickPhoto()
            tableView.deselectRow(at: indexPath, animated: true)
        }

    }

    // endregion

    // region helper

    func string(from placemark: CLPlacemark) -> String {
        var text = ""
        if let tmp = placemark.subThoroughfare {
            text += tmp + " "
        }
        if let tmp = placemark.thoroughfare {
            text += tmp + ", "
        }
        if let tmp = placemark.locality {
            text += tmp + ", "
        }
        if let tmp = placemark.administrativeArea {
            text += tmp + " "
        }
        if let tmp = placemark.postalCode {
            text += tmp + ", "
        }
        if let tmp = placemark.country {
            text += tmp
        }
        return text
    }

    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    // endregion

    // region Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }

    // endregion

}

extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // region 帮助函数

    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            // 如果相机可用
            // 弹出选择框让用户选择
            showPhotoMenu()
        } else {
            // 如果不可用，就从相册寻找
            choosePhotoFromLibrary()
        }
    }

    func showPhotoMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let actCancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let actPhoto = UIAlertAction(title: "拍摄照片", style: .default) {_ in
            self.takePhotoWithCamera()
        }
        let actLibrary = UIAlertAction(title: "从相册中选择", style: .default) {_ in
            self.choosePhotoFromLibrary()
        }

        alert.addAction(actCancel)
        alert.addAction(actPhoto)
        alert.addAction(actLibrary)

        present(alert, animated: true, completion: nil)
    }

    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }

    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)

    }



    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true, completion: nil)
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }


    // endregion
}
