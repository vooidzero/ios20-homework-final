//
//  CGImage+ArrayBGRA.swift
//  ImageSegmentation
//
//  Created by zero on 2021/1/25.
//

import UIKit

extension CGImage {
    // byte[0..3]: B G R A
    var arrayBGRA: [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4 * self.height * self.width)
        bytes.withUnsafeMutableBytes { ptr in
            let context = CGContext(
                data: ptr.baseAddress,
                width: self.width,
                height: self.height,
                bitsPerComponent: 8,
                bytesPerRow: self.width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue + CGImageAlphaInfo.premultipliedFirst.rawValue
            )
            if let context = context {
                let rect = CGRect(x: 0, y: 0, width: self.width, height: self.height)
                context.draw(self, in: rect)
            }
        }
        return bytes
    }
    
    static func fromArrayBGRA(_ bytes: [UInt8], width: Int, height: Int) -> CGImage? {
        CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 4 * width,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue + CGImageAlphaInfo.premultipliedFirst.rawValue),
            provider: CGDataProvider(data: CFDataCreate(nil, bytes, bytes.count))!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
