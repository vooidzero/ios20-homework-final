//
//  DrawingImageView.swift
//  ImageSegmentation
//
//  Created by zero on 2021/1/26.
//

import UIKit
import opencv2

protocol DrawingImageViewDelegate {
    func drawingImageView(_ drawingImageView: DrawingImageView, drawLineFrom p1: CGPoint, to p2: CGPoint)
}


class DrawingImageView: UIImageView {
    
    private var lastPoint: CGPoint!
    private var touchMoved: Bool = false
    public var drawingDelegate: DrawingImageViewDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        touchMoved = false
        lastPoint = touch.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        touchMoved = true
        let currentPoint = touch.location(in: self)
        drawingDelegate?.drawingImageView(self, drawLineFrom: lastPoint, to: currentPoint)
        
        lastPoint = currentPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !touchMoved {
            drawingDelegate?.drawingImageView(self, drawLineFrom: lastPoint, to: lastPoint)
        }
        touchMoved = false
    }
}
