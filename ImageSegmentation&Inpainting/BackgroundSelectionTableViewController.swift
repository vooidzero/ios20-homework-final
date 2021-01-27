//
//  BackgroundSelectionTableViewController.swift
//  ImageSegmentation
//
//  Created by zero on 2021/1/25.
//

import UIKit

class FillColorCell: UITableViewCell {
    var color: ARGBColor!
    @IBOutlet weak var colorImageView: UIImageView!
    @IBOutlet weak var colorLabel: UILabel!
}

class BackgroundSelectionTableViewController: UITableViewController {

    var selection: SegmentationViewController.BackgroundOption?

    fileprivate struct Item {
        let label: String
        let color: ARGBColor
    }

    fileprivate let items = [
        Item(label: "红色", color: ARGBColor(r: 255, g: 0, b: 0)),
        Item(label: "白色", color: ARGBColor(r: 255, g: 255, b: 255)),
        Item(label: "浅蓝", color: ARGBColor(r: 0, g: 191, b: 243)),
        Item(label: "深蓝", color: ARGBColor(r: 0, g: 0, b: 255)),
        Item(label: "绿色", color: ARGBColor(r: 0, g: 255, b: 0)),
        Item(label: "黑色", color: ARGBColor(r: 0, g: 0, b: 0))
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "图片"
        } else {
            return "颜色填充"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if #available(iOS 14.0, *) {
            return items.count + 1
        } else {
            return items.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "ImageFromPhotoLibraryCell", for: indexPath)
        } else if #available(iOS 14.0, *), indexPath.row == items.count {
            return tableView.dequeueReusableCell(withIdentifier: "MoreColorCell", for: indexPath)
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "FillColorCell", for: indexPath)
                    as? FillColorCell else {
                fatalError()
            }
            let item = items[indexPath.row]
            cell.tag = indexPath.row
            cell.color = item.color
            cell.colorLabel.text = item.label
            cell.colorImageView.image = item.color.filledImage(size: CGSize(width: 1, height: 1))
            cell.colorImageView.layer.cornerRadius = 5.0
            cell.colorImageView.layer.borderColor = UIColor.gray.cgColor
            cell.colorImageView.layer.borderWidth = 0.5
            return cell
        }
    }
    
    // MARK: - Actions
    @IBAction func tappedOnPhotoLibrary(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }
    
    @available(iOS 14.0, *)
    @IBAction func tappedOnMoreColor(_ sender: Any) {
        let colorPickerController = UIColorPickerViewController()
        colorPickerController.delegate = self
        present(colorPickerController, animated: true)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "unwindFromSomeColor" {
            guard let indexPath = tableView.indexPathForSelectedRow else {
                fatalError()
            }
            selection = .colorFill(items[indexPath.row].color)
        }
    }

}

// MARK: - Color Picker View Controller Delegate
@available(iOS 14.0, *)
extension BackgroundSelectionTableViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        selection = .colorFill(ARGBColor(viewController.selectedColor))
        performSegue(withIdentifier: "unwindFromPickerVC", sender: self)
    }
}

// MARK: - Image Picker Controller Delegate
extension BackgroundSelectionTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[.originalImage] as? UIImage else {
            fatalError()
        }
        selection = .image(pickedImage)
        performSegue(withIdentifier: "unwindFromPickerVC", sender: self)
    }
}
