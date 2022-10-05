//
// Created by 张环宇 on 2022/10/5.
//

import UIKit

class CategoryPickerViewController: UITableViewController {
    var selectedCategoryName = ""

    let categories = [
        "无标签",
        "魔仙堡",
        "日暮里",
        "超市",
        "公园",
        "学校",
        "家",
        "公司",
        "医院",
        "游乐场",
    ]

    var selectedIndexPath = IndexPath()

    override func viewDidLoad() {
        super.viewDidLoad()

        for i in 0..<categories.count {
            if categories[i]  == selectedCategoryName {
                selectedIndexPath = IndexPath(row: i, section: 0)
                break
            }
        }
    }

    // region Delegates

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let categoryName = categories[indexPath.row]
        cell.textLabel!.text = categoryName

        if categoryName == selectedCategoryName {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != selectedIndexPath.row {
            // 新的选择  老的取消选择
            if let newCell = tableView.cellForRow(at: indexPath) {
                newCell.accessoryType = .checkmark
            }
            if let oldCell = tableView.cellForRow(at: selectedIndexPath) {
                oldCell.accessoryType = .none
            }
            selectedIndexPath = indexPath
        }
    }

    // endregion


    // region Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickedCategory" {
            let cell = sender as! UITableViewCell
            if let indexPath = tableView.indexPath(for: cell) {
                selectedCategoryName = categories[indexPath.row]
            }
        }
    }

    // endregion
}