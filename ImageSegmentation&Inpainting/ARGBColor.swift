//
//  ARGBColor.swift
//  ImageSegmentation
//
//  Created by zero on 2021/1/25.
//

import UIKit

struct ARGBColor {
    let b: UInt8
    let g: UInt8
    let r: UInt8
    let a: UInt8
    
    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.b = b
        self.g = g
        self.r = r
        self.a = a
    }
    
    init(_ uiColor: UIColor) {
        var b: CGFloat = 0.0
        var g: CGFloat = 0.0
        var r: CGFloat = 0.0
        var a: CGFloat = 0.0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        if b < 0 { b = 0 } else if b > 1 { b = 1 }
        if g < 0 { g = 0 } else if g > 1 { g = 1 }
        if r < 0 { r = 0 } else if r > 1 { r = 1 }
        if a < 0 { a = 0 } else if a > 1 { a = 1 }
        self.init(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255), a: UInt8(a * 255))
    }
    
    var uiColor: UIColor {
        return UIColor(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
    
    func filledImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        self.uiColor.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
