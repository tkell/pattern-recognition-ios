//
//  AnimationHelpers.swift
//  pattern-recognition-ios
//
//  Created by Thor Kell on 1/21/18.
//  Copyright © 2018 Thor Kell. All rights reserved.
//

import Foundation
import UIKit

func doButtonTouchAnimation(b: NoteButton, otherButtons: Array<[String: Any]>, view: UIView) -> Void {
    b.backgroundColor = UIColor(white: 0.0, alpha: 0.75)
    b.layer.borderColor = UIColor(white: 1.0, alpha: 1.0).cgColor
    otherButtons.forEach { loc in
        let path = UIBezierPath()
        path.move(to: CGPoint(x: b.frame.midX, y: b.frame.midY))
        let temp = loc["location"] as! [String : Int]
        let xLoc = temp["x"]!
        let yLoc = temp["y"]!
        path.addLine(to: CGPoint(x: xLoc, y: yLoc))
        path.close()
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        b.lineLayers.append(layer)
        
        view.layer.addSublayer(layer)
        layer.path = path.cgPath
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        /* set up animation */
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = 0.225
        layer.add(animation, forKey: "drawLineAnimation")
    }
}


func finishButtonTouchAnimation(b: NoteButton) -> Void {
    b.backgroundColor = UIColor(white: 0.0, alpha: 0.35)
    b.layer.borderColor = UIColor(white: 1.0, alpha: 0.75).cgColor

    b.lineLayers.forEach { layer in
        layer.removeFromSuperlayer()
    }
}

