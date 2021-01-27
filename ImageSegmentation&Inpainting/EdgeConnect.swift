//
//  EdgeConnect.swift
//  ImageSegmentation
//
//  Created by zero on 2021/1/26.
//

import UIKit
import CoreML
import opencv2

class EdgeConnect {
    
    static let ImageWidth = 320
    static let ImageHeight = 320
    static let PixelCount = 320 * 320

    static var predictionOptions: MLPredictionOptions {
        let opt = MLPredictionOptions()
        opt.usesCPUOnly = true
        return opt
    }

    private static func getMaskArray(mask: UIImage) -> [UInt8] {
        let resizedMask = mask.resized(width: ImageWidth, height: ImageHeight)
        let maskBGRA = resizedMask.cgImage!.arrayBGRA
        var mask = [UInt8](repeating: 0, count: PixelCount)
        for i in 0..<PixelCount {
            if maskBGRA[i * 4] != 0, maskBGRA[i * 4 + 1] != 0, maskBGRA[i * 4 + 2] != 0 {
                mask[i] = 1
            }
        }
        return mask
    }
    
    static func process(image: UIImage, mask: UIImage) -> UIImage {
        // pre-process
        let resizedImage = image.resized(width: ImageWidth, height: ImageHeight)
        let imageBGRA = resizedImage.cgImage!.arrayBGRA
        let maskArray = getMaskArray(mask: mask)
        
        // model predict
        let edgeOutput = edgePrediction(image: imageBGRA, mask: maskArray)
        let inpaintingOutput = inpaintingPrediction(image: imageBGRA, mask: maskArray, edgeOutput: edgeOutput)
        
        // mix inpaint region to image of original size, probably unefficient
        var inpaintBGRA = [UInt8](repeating: 0, count: 4 * PixelCount)
        let cStride = inpaintingOutput.strides[0].intValue
        for i in 0..<PixelCount {
            if maskArray[i] != 0 {
                inpaintBGRA[i * 4 + 0] = UInt8(inpaintingOutput[i + 0 * cStride].floatValue * 255.0)
                inpaintBGRA[i * 4 + 1] = UInt8(inpaintingOutput[i + 1 * cStride].floatValue * 255.0)
                inpaintBGRA[i * 4 + 2] = UInt8(inpaintingOutput[i + 2 * cStride].floatValue * 255.0)
                inpaintBGRA[i * 4 + 3] = 255
            }
        }
        let inpaintCGImage = CGImage.fromArrayBGRA(inpaintBGRA, width: ImageWidth, height: ImageHeight)!
        let inpaintUIImage = UIImage(cgImage: inpaintCGImage).resized(to: image.size)
        
        UIGraphicsBeginImageContext(image.size)
        image.draw(at: .zero)
        inpaintUIImage.draw(at: .zero)
        let result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
    }
    
    private static func edgePrediction(image: [UInt8], mask: [UInt8]) -> MLMultiArray {
        let model = try! Edge(configuration: MLModelConfiguration())
        let input = getEdgeInput(image: image, mask: mask)
        let output = try! model.prediction(input: input, options: predictionOptions)
        return output._153
    }
    
    private static func inpaintingPrediction(image: [UInt8], mask: [UInt8], edgeOutput: MLMultiArray) -> MLMultiArray {
        let model = try! Inpainting(configuration: MLModelConfiguration())
        let input = getInpaintingInput(image: image, mask: mask, edgeOutput: edgeOutput)
        let output = try! model.prediction(input: input, options: predictionOptions)
        return output._173
    }
    
    private static func getGray(image: [UInt8]) -> [UInt8] {
        var gray = [UInt8](repeating: 0, count: PixelCount)
        for i in 0..<PixelCount {
            let b = image[i * 4]
            let g = image[i * 4 + 1]
            let r = image[i * 4 + 2]
            gray[i] = UInt8(0.299 * Float(r) + 0.587 * Float(g) + 0.114 * Float(b))
        }
        return gray
    }

    private static func getEdge(gray: [UInt8]) -> [UInt8] {
        var edge = [UInt8](repeating: 0, count: PixelCount)
        let imgData = Data(bytes: gray, count: PixelCount)
        let imgMat = Mat(rows: Int32(ImageHeight), cols: Int32(ImageWidth), type: CvType.CV_8UC1, data: imgData)
        Imgproc.Canny(image: imgMat, edges: imgMat, threshold1: 25.5, threshold2: 51.0)
        var tmp = [Int8](repeating: 0, count: PixelCount)
        try! imgMat.get(row: 0, col: 0, data: &tmp)
        for i in 0..<PixelCount {
            edge[i] = (tmp[i] == 0 ? 0 : 255)
        }
        return edge
    }

    private static func getEdgeInput(image: [UInt8], mask: [UInt8]) -> EdgeInput {
        let gray = getGray(image: image)
        let edge = getEdge(gray: gray)

        let shape = [3, ImageWidth, ImageHeight] as [NSNumber]
        let edgeInput = try! MLMultiArray(shape: shape, dataType: .float32)
        let cStride = edgeInput.strides[0].intValue
        for i in 0..<PixelCount {
            if mask[i] != 0 {
                edgeInput[0 * cStride + i] = NSNumber(value: Float(1))
                edgeInput[1 * cStride + i] = NSNumber(value: Float(0))
                edgeInput[2 * cStride + i] = NSNumber(value: Float(1))
            } else {
                edgeInput[0 * cStride + i] = NSNumber(value: Float(gray[i]) / 255.0)
                edgeInput[1 * cStride + i] = NSNumber(value: Float(edge[i]) / 255.0)
                edgeInput[2 * cStride + i] = NSNumber(value: Float(0))
            }
        }
        return EdgeInput(input_1: edgeInput)
    }


    private static func getInpaintingInput(image: [UInt8], mask: [UInt8], edgeOutput: MLMultiArray) -> InpaintingInput {
        let shape = [4, ImageWidth, ImageHeight] as [NSNumber]
        let inpaintingInput = try! MLMultiArray(shape: shape, dataType: .float32)
        let cStride = inpaintingInput.strides[0].intValue
        for i in 0..<PixelCount {
            if mask[i] != 0 {
                inpaintingInput[0 * cStride + i] = NSNumber(value: Float(1.0))
                inpaintingInput[1 * cStride + i] = NSNumber(value: Float(1.0))
                inpaintingInput[2 * cStride + i] = NSNumber(value: Float(1.0))
            } else {
                inpaintingInput[0 * cStride + i] = NSNumber(value: Float(image[i * 4]) / 255.0)
                inpaintingInput[1 * cStride + i] = NSNumber(value: Float(image[i * 4 + 1]) / 255.0)
                inpaintingInput[2 * cStride + i] = NSNumber(value: Float(image[i * 4 + 2]) / 255.0)
            }
            inpaintingInput[3 * cStride + i] = edgeOutput[i]
        }
        return InpaintingInput(input_1: inpaintingInput)
    }
    
}
