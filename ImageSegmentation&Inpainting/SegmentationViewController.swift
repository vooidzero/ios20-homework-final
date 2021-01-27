//
//  ViewController.swift
//  ImageSegmentation
//
//  Created by zero on 2021/1/24.
//

import UIKit
import CoreML
import Vision

class SegmentationViewController: UIViewController {

    // MARK: - UI Properties
    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var displayOptionSegCtrl: UISegmentedControl!
    @IBOutlet weak var segmentInfoTableView: UITableView!
    
    enum DisplayOption: Int, CaseIterable {
        case originalImage = 0
        case segmentedImage = 1
        case backgroundReplaced = 2
    }

    enum BackgroundOption {
        case colorFill(ARGBColor)
        case image(UIImage)
        
        var uiImage: UIImage {
            switch self {
            case .colorFill(let color):
                return color.filledImage(size: CGSize(width: 1, height: 1))
            case .image(let img):
                return img
            }
        }
    }
    
    var displayOption: DisplayOption = .segmentedImage
    var backgroundOption: BackgroundOption = .colorFill(ARGBColor(r: 255, g: 0, b: 0))
    
    var displayImages = [UIImage?](repeating: nil, count: DisplayOption.allCases.count)
    var originalImage: UIImage! {
        get {
            displayImages[DisplayOption.originalImage.rawValue]
        } set {
            displayImages[DisplayOption.originalImage.rawValue] = newValue
        }
    }
    
    // MARK: - Core ML Preoperties
    var segmentResult: MLMultiArray!
    lazy var segmentRequest: VNCoreMLRequest = {
        do {
            let deepLab = try DeepLabV3(configuration: MLModelConfiguration())
            let model = try VNCoreMLModel(for: deepLab.model)
            let request = VNCoreMLRequest(model: model, completionHandler: self.segmentRequestDidComplete)
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch {
            fatalError("Failed to create request")
        }
    }()
    
    // MARK: DeepLabV3 Constants
    let ModelImageWidth: Int = 513
    let ModelImageHeight: Int = 513
    let ModelImageSize = CGSize(width: 513, height: 513)
    
    // MARK: - Miscellaneous
    var occurredClassArray = [Int]()
    var notOccurredClassArray = [Int]()
    var occurredClassSet = Set<Int>()
    var segmentClasses: [SegmentClass]!
    let dispatchQueue = DispatchQueue(label: "cn.edu.nju.cs.zero.image_process-queue")
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageScrollView.maximumZoomScale = 2.0
        imageScrollView.delegate = self
        
        activityIndicator.layer.zPosition = 1.0
        segmentClasses = SegmentClass.defaultClasses
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        adjustZoomScale()
    }

    func enableUserInteraction() {
        barButton.isEnabled = true
        imageView.isUserInteractionEnabled = true
        displayOptionSegCtrl.isEnabled = true
        segmentInfoTableView.isUserInteractionEnabled = true
    }
    
    func disableUserInteraction() {
        barButton.isEnabled = false
        imageView.isUserInteractionEnabled = false
        displayOptionSegCtrl.isEnabled = false
        segmentInfoTableView.isUserInteractionEnabled = false
    }
    
    func updateImageView() {
        if let image = self.displayImages[displayOption.rawValue] {
            imageView.image = image
        } else {
            disableUserInteraction()
            activityIndicator.startAnimating()
            dispatchQueue.async {
                let image = self.getDisplayingImage()
                self.displayImages[self.displayOption.rawValue] = image
                DispatchQueue.main.async {
                    self.imageView.image = image
                    self.activityIndicator.stopAnimating()
                    self.enableUserInteraction()
                }
            }
        }
    }
    
    func getDisplayingImage() -> UIImage {
        var getPixel: ((Int, Int) -> (UInt8, UInt8, UInt8, UInt8))!
        switch displayOption {
        case .originalImage:
            fatalError("No Image Selected")
        case .segmentedImage:
            getPixel = { _, seg in
                let c = self.segmentClasses[seg].color
                return (c.b, c.g, c.r, c.a)
            }
        case .backgroundReplaced:
            switch self.backgroundOption {
            case .colorFill(let color):
                getPixel = { _, seg in
                    if self.segmentClasses[seg].isForeground {
                        return (0, 0, 0, 0)
                    } else {
                        return (color.b, color.g, color.r, color.a)
                    }
                }
            case .image(let backgroundImage):
                let bytes = backgroundImage.cgImage!.resized(to: ModelImageSize).arrayBGRA
                getPixel = { idx, seg in
                    if self.segmentClasses[seg].isForeground {
                        return (0, 0, 0, 0)
                    } else {
                        return (bytes[idx * 4], bytes[idx * 4 + 1], bytes[idx * 4 + 2], bytes[idx * 4 + 3])
                    }
                }
            }
        }

        var pixelData = [UInt8](repeating: 0, count: 4 * ModelImageWidth * ModelImageHeight)
        for i in 0..<(ModelImageWidth * ModelImageHeight) {
            let seg = segmentResult[i].intValue
            let (byte0, byte1, byte2, byte3) = getPixel(i, seg)
            pixelData[i * 4] = byte0
            pixelData[i * 4 + 1] = byte1
            pixelData[i * 4 + 2] = byte2
            pixelData[i * 4 + 3] = byte3
        }
        let overlayCGImage = CGImage.fromArrayBGRA(pixelData, width: ModelImageWidth, height: ModelImageHeight)!
        let overlayUIImage = UIImage(cgImage: overlayCGImage).resized(to: originalImage.size)
        
        UIGraphicsBeginImageContext(originalImage.size)
        originalImage.draw(at: .zero)
        overlayUIImage.draw(at: .zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Actions
    @IBAction func imageViewTapped(_ sender: Any) {
        guard !activityIndicator.isAnimating else {
            return
        }
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photoLibraryAction = UIAlertAction(title: "从图库选择图片", style: .default) { _ in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true)
        }
        let cameraAction = UIAlertAction(title: "拍照", style: .default) { _ in
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true)
        }
        if self.originalImage != nil {
            let saveAction = UIAlertAction(title: "保存图片", style: .default) { _ in
                UIImageWriteToSavedPhotosAlbum(self.imageView.image!, nil, nil, nil)
            }
            alertController.addAction(saveAction)
        }
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        self.present(alertController, animated: true)
    }
    
    @IBAction func displyOptionSegCtrlValueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex != displayOption.rawValue {
            let tmp = displayOption.rawValue
            displayOption = DisplayOption(rawValue: sender.selectedSegmentIndex)!
            if [tmp, sender.selectedSegmentIndex].contains(DisplayOption.backgroundReplaced.rawValue) {
                segmentInfoTableView.reloadData()
            }
            updateImageView()
        }
    }
    
    @IBAction func classLayerSettingSegCtrlValueChanged(_ sender: UISegmentedControl) {
        segmentClasses[sender.tag].isForeground = (sender.selectedSegmentIndex == ClassLayerSettingCell.foregroundSegmentIndex)
        if occurredClassSet.contains(sender.tag) {
            displayImages[DisplayOption.backgroundReplaced.rawValue] = nil
            updateImageView()
        }
    }
    
    // MARK: - Navigation
    @IBAction func unwindToImageSegmentation(sender: UIStoryboardSegue) {
        guard let sourceController = sender.source as? BackgroundSelectionTableViewController else {
            return
        }
        guard let opt = sourceController.selection else {
            return
        }
        backgroundOption = opt
        displayImages[DisplayOption.backgroundReplaced.rawValue] = nil
        if displayOption == .backgroundReplaced {
            guard let cell = segmentInfoTableView.cellForRow(at: IndexPath(row: 0, section: 0))
                    as? BackgroundSelectionCell else {
                return
            }
            cell.selectedImageView.image = backgroundOption.uiImage
        }
        updateImageView()
    }
}

// MARK: - Image Picker Controller Delegate
extension SegmentationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[.originalImage] as? UIImage else {
            return
        }

        displayImages = [UIImage?](repeating: nil, count: self.displayImages.count)
        originalImage = pickedImage
        imageView.image = pickedImage
        adjustZoomScale()
        disableUserInteraction()
        activityIndicator.startAnimating()
        dispatchQueue.async {
            self.predict(with: pickedImage)
        }
        dismiss(animated: true)
    }
}

// MARK: - Core ML handler
extension SegmentationViewController {
    func predict(with image: UIImage) {
        let resizedImage = image.resized(to: ModelImageSize).cgImage!
        let handler = VNImageRequestHandler(cgImage: resizedImage, options: [:])
        try? handler.perform([segmentRequest])
    }
    
    func segmentRequestDidComplete(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
            fatalError()
        }
        guard let result = observations.first?.featureValue.multiArrayValue else {
            fatalError()
        }
        segmentResult = result
        
        occurredClassSet.removeAll()
        for i in 0..<(ModelImageWidth * ModelImageHeight) {
            occurredClassSet.insert(result[i].intValue)
        }
        occurredClassArray = occurredClassSet.sorted()
        notOccurredClassArray = Set<Int>(0..<segmentClasses.count).subtracting(occurredClassSet).sorted()
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.segmentInfoTableView.reloadData()
            self.enableUserInteraction()
            self.updateImageView()
        }
    }
}

// MARK: - Scroll View (Zooming)
extension SegmentationViewController: UIScrollViewDelegate {
    func adjustZoomScale() {
        var minScale: CGFloat = 1.0
        let imageSize = imageView.image!.size
        let scrollViewSize = imageScrollView.bounds.size
        if imageSize.width > scrollViewSize.width {
            minScale = scrollViewSize.width / imageSize.width
        }
        if imageSize.height > scrollViewSize.height {
            minScale = min(minScale, scrollViewSize.height / imageSize.height)
        }
        imageScrollView.minimumZoomScale = minScale
        imageScrollView.zoomScale = minScale
        
        // adjust content inset so that image view is in the center
        let scaledSize = CGSize(width: imageSize.width * minScale, height: imageSize.height * minScale)
        scrollViewAdjustContentInset(imageScrollView, scaledContentSize: scaledSize)
    }
    
    func scrollViewAdjustContentInset(_ scrollView: UIScrollView, scaledContentSize: CGSize) {
        let widthDiff: CGFloat = max(0, scrollView.bounds.size.width - scaledContentSize.width)
        let heightDiff: CGFloat = max(0, scrollView.bounds.size.height - scaledContentSize.height)
        scrollView.contentInset = UIEdgeInsets(
            top: heightDiff / 2,
            left: widthDiff / 2,
            bottom: 0,
            right: 0
        )
    }
    
    // MARK: - Protocol UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollViewAdjustContentInset(scrollView, scaledContentSize: view!.frame.size)
    }
}



// MARK: - TableView
class ClassColorTipCell: UITableViewCell {
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
}

class BackgroundSelectionCell: UITableViewCell {
    @IBOutlet weak var selectedImageView: UIImageView!
}

class ClassLayerSettingCell: UITableViewCell {
    static let backgroundSegmentIndex = 0
    static let foregroundSegmentIndex = 1
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
}

extension SegmentationViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if originalImage == nil {
            return 0
        }
        
        switch displayOption {
        case .originalImage, .segmentedImage:
            return 2
        case .backgroundReplaced:
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch displayOption {
        case .originalImage, .segmentedImage:
            return (section == 1 ? "未出现的分类" : "")
        case .backgroundReplaced:
            switch section {
            case 1: return "分类前背景设置"
            case 2: return "未出现的分类"
            default: return ""
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch displayOption {
        case .originalImage, .segmentedImage:
            let tmp = occurredClassArray.count - (occurredClassArray.first == 0 ? 1 : 0)
            if section == 0 {
                return tmp
            } else {
                return self.segmentClasses.count - 1 - tmp
            }
        case .backgroundReplaced:
            switch section {
            case 1: return occurredClassArray.count
            case 2: return segmentClasses.count - occurredClassArray.count
            default: return 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.displayOption {
        case .originalImage, .segmentedImage:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ClassColorTipCell", for: indexPath)
                    as? ClassColorTipCell else {
                fatalError()
            }
            var classIndex = 0
            if occurredClassArray.first == 0 {
                if indexPath.section == 0 {
                    classIndex = occurredClassArray[indexPath.row + 1]
                } else {
                    classIndex = notOccurredClassArray[indexPath.row]
                }
            } else {
                if indexPath.section == 0 {
                    classIndex = occurredClassArray[indexPath.row]
                } else {
                    classIndex = notOccurredClassArray[indexPath.row + 1]
                }
            }
            cell.classLabel.text = segmentClasses[classIndex].label
            cell.colorView.backgroundColor = segmentClasses[classIndex].color.uiColor
            cell.colorView.layer.cornerRadius = 5.0
            return cell
        case .backgroundReplaced:
            if indexPath.section == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "BackgroundSelectionCell", for: indexPath)
                        as? BackgroundSelectionCell else {
                    fatalError()
                }
                cell.selectedImageView.image = backgroundOption.uiImage
                cell.selectedImageView.layer.borderColor = UIColor.gray.cgColor
                cell.selectedImageView.layer.borderWidth = 0.5
                cell.isUserInteractionEnabled = true
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ClassLayerSettingCell", for: indexPath)
                        as? ClassLayerSettingCell else {
                    fatalError()
                }
                var classIndex = 0
                if indexPath.section == 1 {
                    classIndex = occurredClassArray[indexPath.row]
                } else {
                    classIndex = notOccurredClassArray[indexPath.row]
                }
                cell.classLabel.text = segmentClasses[classIndex].label
                cell.segmentedControl.tag = classIndex
                if segmentClasses[classIndex].isForeground {
                    cell.segmentedControl.selectedSegmentIndex = ClassLayerSettingCell.foregroundSegmentIndex
                } else {
                    cell.segmentedControl.selectedSegmentIndex = ClassLayerSettingCell.backgroundSegmentIndex
                }
                return cell
            }

        }
    }
    
}
