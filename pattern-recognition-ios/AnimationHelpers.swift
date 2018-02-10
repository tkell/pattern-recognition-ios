//
//  AnimationHelpers.swift
//  pattern-recognition-ios
//
//  Created by Thor Kell on 1/21/18.
//  Copyright © 2018 Thor Kell. All rights reserved.
//

import Foundation
import UIKit

func doMapAnimation(buttonLocList: Array<[String: Any]>, view: UIView, reverse: Bool) -> Void {
    let myPath = UIBezierPath()
    let layer = CAShapeLayer()
    layer.strokeColor = UIColor.white.cgColor

    var buttonList: Array<[String: Any]> = []
    if reverse == true {
        buttonList = Array(buttonLocList.reversed())
    } else {
        buttonList = buttonLocList
    }

    // if we have a ton of buttons, only draw lines from some of them
    var stop = 0
    if buttonList.count <  16 {
        stop = buttonList.count - Int(buttonList.count / 4)
    } else if buttonList.count >=  15 {
        stop = buttonList.count / 2
    } else if buttonList.count >  18 {
        stop = buttonList.count / 3
    }

    for i in 0...buttonList.count - 1 {
        if i > stop {
            continue
        }

        let b1 = buttonList[i]
        let temp = b1["location"] as! [String : Int]
        let xLoc1 = temp["x"]!
        let yLoc1 = temp["y"]!
        for j in 0...buttonList.count - 1 {
            let b2 = buttonList[j]
            let path = UIBezierPath()
            path.move(to: CGPoint(x: xLoc1, y: yLoc1))
            let temp = b2["location"] as! [String : Int]
            let xLoc2 = temp["x"]!
            let yLoc2 = temp["y"]!
            path.addLine(to: CGPoint(x: xLoc2, y: yLoc2))
            myPath.append(path)
        }
    }
    
    let animation = CABasicAnimation(keyPath: "strokeEnd")
    /* set up animation */
    animation.fromValue = 0.0
    animation.toValue = 1.0
    animation.duration = (drand48() * 2.5) + 0.5
    layer.add(animation, forKey: "strokeEndAnimation")

    let fadeAnimation = CABasicAnimation(keyPath: "opacity")
    fadeAnimation.fromValue = 1.0
    fadeAnimation.toValue = 0.0
    fadeAnimation.duration = 4.0
    layer.add(fadeAnimation, forKey: "opacity")
    layer.opacity = 0.0

    view.layer.addSublayer(layer)
    layer.path = myPath.cgPath
}


func doButtonTouchAnimation(b: NoteButton, otherButtons: Array<[String: Any]>, view: UIView) -> Void {
    b.backgroundColor = UIColor(white: 0.0, alpha: 0.75)
    b.layer.borderColor = UIColor(white: 1.0, alpha: 1.0).cgColor

    // This gets a _bit_ ugly when drawing from 10+ buttons, but it is fine for now
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

