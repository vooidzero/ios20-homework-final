//
//  UIImage+Resize.swift
//  ImageSegmentation
//
//  Created by zero on 2021/1/25.
//

import UIKit

extension UIImage {
    
    // return an image with scale set to 1 (scaled if necessary)
    //     and imageOrientation set to .up (The original pixel data matches the image's intended display orientation.)
    func normalized() -> UIImage {
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 1)
        self.draw(in: CGRect(origin: .zero, size: scaledSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // scaled to new size (property UIImage.scale would lost)
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        self.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func resized(width: CGFloat, height: CGFloat) -> UIImage {
        return resized(to: CGSize(width: width, height: height))
    }
    
    func resized(width: Int, height: Int) -> UIImage {
        return resized(width: CGFloat(width), height: CGFloat(height))
    }
}

extension CGImage {
    func resized(width: Int, height: Int) -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue + CGImageAlphaInfo.premultipliedFirst.rawValue
        )!
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(self, in: rect)
        return context.makeImage()!
    }
    
    func resized(to size: CGSize) -> CGImage {
        return self.resized(width: Int(size.width), height: Int(size.height))
    }
}
