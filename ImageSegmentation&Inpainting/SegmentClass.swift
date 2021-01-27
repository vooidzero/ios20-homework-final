//
//  SegmentClass.swift
//  ImageSegmentation
//
//  Created by zero on 2021/1/24.
//

import Foundation

struct SegmentClass {
    let label: String
    var isForeground: Bool
    let color: ARGBColor
    
    static var defaultClasses: [SegmentClass] {
        [
            SegmentClass(label: "Background", isForeground: false,
                color: ARGBColor(r: 0, g: 0, b: 0, a: 0)
            ),
            SegmentClass(label: "Aeroplane", isForeground: true,
                color: ARGBColor(r: 0x80, g: 0x00, b: 0x00, a: 0x99)
            ),
            SegmentClass(label: "Bicycle", isForeground: false,
                color: ARGBColor(r: 0x00, g: 0x80, b: 0x02, a: 0x99)
            ),
            SegmentClass(label: "Bird", isForeground: true,
                color: ARGBColor(r: 0x80, g: 0x80, b: 0x00, a: 0x99)
            ),
            SegmentClass(label: "Boat", isForeground: false,
                color: ARGBColor(r: 0x05, g: 0x00, b: 0x80, a: 0x99)
            ),
            SegmentClass(label: "Bottle", isForeground: true,
                color: ARGBColor(r: 0x80, g: 0x00, b: 0x80, a: 0x99)
            ),
            SegmentClass(label: "Bus", isForeground: false,
                color: ARGBColor(r: 0x00, g: 0x80, b: 0x80, a: 0x99)
            ),
            SegmentClass(label: "Car", isForeground: false,
                color: ARGBColor(r: 0x80, g: 0x80, b: 0x80, a: 0x99)
            ),
            SegmentClass(label: "Cat", isForeground: true,
                color: ARGBColor(r: 0x40, g: 0x00, b: 0x00, a: 0x99)
            ),
            SegmentClass(label: "Chair", isForeground: false,
                color: ARGBColor(r: 0xC0, g: 0x00, b: 0x00, a: 0x99)
            ),
            SegmentClass(label: "Cow", isForeground: true,
                color: ARGBColor(r: 0x3F, g: 0x80, b: 0x01, a: 0x99)
            ),
            SegmentClass(label: "Dining Table", isForeground: false,
                color: ARGBColor(r: 0xC0, g: 0x80, b: 0x02, a: 0x99)
            ),
            SegmentClass(label: "Dog", isForeground: true,
                color: ARGBColor(r: 0x40, g: 0x02, b: 0x80, a: 0x99)
            ),
            SegmentClass(label: "Horse", isForeground: true,
                color: ARGBColor(r: 0xC0, g: 0x01, b: 0x80, a: 0x99)
            ),
            SegmentClass(label: "Motorbike", isForeground: false,
                color: ARGBColor(r: 0x40, g: 0x80, b: 0x80, a: 0x99)
            ),
            SegmentClass(label: "Person", isForeground: true,
                color: ARGBColor(r: 0xC0, g: 0x80, b: 0x7F, a: 0x99)
            ),
            SegmentClass(label: "Potted Plant", isForeground: true,
                color: ARGBColor(r: 0x00, g: 0x3F, b: 0x00, a: 0x99)
            ),
            SegmentClass(label: "Sheep", isForeground: true,
                color: ARGBColor(r: 0x80, g: 0x40, b: 0x01, a: 0x99)
            ),
            SegmentClass(label: "Sofa", isForeground: false,
                color: ARGBColor(r: 0x00, g: 0xC0, b: 0x00, a: 0x99)
            ),
            SegmentClass(label: "Train", isForeground: true,
                color: ARGBColor(r: 0x7F, g: 0xC0, b: 0x02, a: 0x99)
            ),
            SegmentClass(label: "TV or Monitor", isForeground: false,
                color: ARGBColor(r: 0x01, g: 0x40, b: 0x80, a: 0x99)
            )
        ]
    }
}
