//
//  InpaintViewController.swift
//  ImageSegmentation
//
//  Created by zero on 2021/1/26.
//

import UIKit
import opencv2

class InpaintingViewController: UIViewController {

    @IBOutlet weak var photoLibraryButton: UIBarButtonItem!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var maskImageView: DrawingImageView!
    @IBOutlet weak var backendSegmentedControl: UISegmentedControl!
    @IBOutlet weak var penEnableSwitch: UISwitch!
    @IBOutlet weak var penWidthLabel: UILabel!
    @IBOutlet weak var penWidthStepper: UIStepper!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    enum Backend: Int {
        case openCV = 0
        case edgeConnect = 1
    }
    
    var penWidth: CGFloat = 14.0
    let dispatchQueue = DispatchQueue(label: "cn.edu.nju.cs.zero.image_process-queue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.maximumZoomScale = 4.0
        
        maskImageView.drawingDelegate = self
        maskImageView.layer.zPosition = 1.0
        
        penWidthStepper.value = Double(penWidth)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        adjustZoomScale()
    }
    

    func disableUserInterAction() {
        photoLibraryButton.isEnabled = false
        maskImageView.isUserInteractionEnabled = false
        backendSegmentedControl.isEnabled = false
        penEnableSwitch.isEnabled = false
        penWidthStepper.isEnabled = false
        clearButton.isEnabled = false
        applyButton.isEnabled = false
    }
    
    func enableUserInterAction() {
        photoLibraryButton.isEnabled = true
        maskImageView.isUserInteractionEnabled = penEnableSwitch.isOn
        backendSegmentedControl.isEnabled = true
        penEnableSwitch.isEnabled = true
        penWidthStepper.isEnabled = true
        clearButton.isEnabled = true
        applyButton.isEnabled = true
    }
    
    // MARK: - Actions
    @IBAction func photoLibraryButtonTapped(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let saveAction = UIAlertAction(title: "保存图片", style: .default) { _ in
            UIImageWriteToSavedPhotosAlbum(self.mainImageView.image!, nil, nil, nil)
        }
        let pickImageAction = UIAlertAction(title: "从图库选择图片", style: .default) { _ in
            self.present(imagePickerController, animated: true)
        }
        alertController.addAction(saveAction)
        alertController.addAction(pickImageAction)
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    @IBAction func penEnableSwitchValueChanged(_ sender: UISwitch) {
        if penEnableSwitch.isOn {
            scrollView.isScrollEnabled = false
            maskImageView.isUserInteractionEnabled = true
        } else {
            scrollView.isScrollEnabled = true
            maskImageView.isUserInteractionEnabled = false
        }
    }
    
    @IBAction func penWidthStepperValueChanged(_ sender: UIStepper) {
        let w = sender.value
        penWidthLabel.text = String(Int(w))
        penWidth = CGFloat(w)
    }
    
    @IBAction func clearButtonTapped(_ sender: Any) {
        maskImageView.image = nil
    }
    
    @IBAction func applyButtonTapped(_ sender: Any) {
        guard let mainImage = mainImageView.image else {
            return
        }
        guard let maskImage = maskImageView.image else {
            return
        }
        
        switch Backend(rawValue: backendSegmentedControl.selectedSegmentIndex)! {
        case .openCV:
// bogus in simulator(but fine with ipod touch 6), cant't figure out where is wrong
//            let imgMat = Mat(uiImage: mainImage.normalized())
//            let maskMat = Mat(uiImage: maskImage.normalized())
//            Imgproc.cvtColor(src: imgMat, dst: imgMat, code: ColorConversionCodes.COLOR_BGRA2BGR)
//            Imgproc.cvtColor(src: maskMat, dst: maskMat, code: ColorConversionCodes.COLOR_BGRA2GRAY)
//            Photo.inpaint(src: imgMat, inpaintMask: maskMat, dst: imgMat, inpaintRadius: 3.0, flags: Photo.INPAINT_NS)
//            mainImageView.image = imgMat.toUIImage()
//            maskImageView.image = nil
            
            let cgimg =  mainImage.normalized().cgImage!
            let imgArray = cgimg.arrayBGRA
            let imgData = Data(bytes: imgArray, count: imgArray.count)
            let maskArray = maskImage.cgImage!.arrayBGRA
            let maskData = Data(bytes: maskImage.cgImage!.arrayBGRA, count: maskArray.count)
            let imgMat = Mat(rows: Int32(cgimg.height), cols: Int32(cgimg.width), type: CvType.CV_8UC4, data: imgData)
            let maskMat = Mat(rows: Int32(cgimg.height), cols: Int32(cgimg.width), type: CvType.CV_8UC4, data: maskData)
            
            // it seem that opencv's BGRA is 0xAA_BB_GG_RR, different from my CGImage extension arrayBGRA
            Imgproc.cvtColor(src: imgMat, dst: imgMat, code: ColorConversionCodes.COLOR_RGBA2BGR)
            Imgproc.cvtColor(src: maskMat, dst: maskMat, code: ColorConversionCodes.COLOR_RGBA2GRAY)
            Photo.inpaint(src: imgMat, inpaintMask: maskMat, dst: imgMat, inpaintRadius: 3.0, flags: Photo.INPAINT_NS)
            mainImageView.image = imgMat.toUIImage()
            maskImageView.image = nil
            
        case .edgeConnect:
            disableUserInterAction()
            activityIndicator.startAnimating()
            dispatchQueue.async {
                let image = EdgeConnect.process(image: mainImage, mask: maskImage)
                DispatchQueue.main.async {
                    self.mainImageView.image = image
                    self.maskImageView.image = nil
                    self.activityIndicator.stopAnimating()
                    self.enableUserInterAction()
                }
            }
        } // end switch case
        
    }

}

// MARK: - Drawing
extension InpaintingViewController: DrawingImageViewDelegate {
    func drawingImageView(_ drawingImageView: DrawingImageView, drawLineFrom p1: CGPoint, to p2: CGPoint) {
        UIGraphicsBeginImageContextWithOptions(mainImageView.image!.size, false, mainImageView.image!.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        maskImageView.image?.draw(at: .zero)
        context.setLineCap(.round)
        context.addLines(between: [p1, p2])
        context.setLineWidth(penWidth)
        context.setStrokeColor(UIColor.white.cgColor)
        context.strokePath()
        maskImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}

// MARK: - Image Picker Controller Delegate
extension InpaintingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[.originalImage] as? UIImage else {
            return
        }
        mainImageView.image = pickedImage
        maskImageView.image = nil
        adjustZoomScale()
        dismiss(animated: true)
    }
}

// MARK: - Scroll View (Zooming)
extension InpaintingViewController: UIScrollViewDelegate {
    func adjustZoomScale() {
        var minScale: CGFloat = 1.0
        let imageSize = mainImageView.image!.size
        let scrollViewSize = scrollView.bounds.size
        if imageSize.width > scrollViewSize.width {
            minScale = scrollViewSize.width / imageSize.width
        }
        if imageSize.height > scrollViewSize.height {
            minScale = min(minScale, scrollViewSize.height / imageSize.height)
        }
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
        
        // adjust content inset so that image view is in the center
        let scaledSize = CGSize(width: imageSize.width * minScale, height: imageSize.height * minScale)
        scrollViewAdjustContentInset(scrollView, scaledContentSize: scaledSize)
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
        return scrollContentView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollViewAdjustContentInset(scrollView, scaledContentSize: view!.frame.size)
    }
}

