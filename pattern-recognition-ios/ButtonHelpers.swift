//
//  ButtonHelpers.swift
//  pattern-recognition-ios
//
//  Created by Thor Kell on 1/21/18.
//  Copyright © 2018 Thor Kell. All rights reserved.
//

import UIKit

func makeButton(touchPoint: CGPoint, buttonSize: CGFloat, viewController: ViewController) -> NoteButton {
    let buttonFrame = CGRect(x: touchPoint.x - CGFloat(buttonSize / 2),
                             y: touchPoint.y - CGFloat(buttonSize / 2),
                             width: CGFloat(buttonSize),
                             height: CGFloat(buttonSize))
    let button = NoteButton(freq: 0, frame: buttonFrame)
    button.layer.cornerRadius = 0.5 * button.bounds.size.width
    button.clipsToBounds = true
    button.backgroundColor = UIColor(white: 0.0, alpha: 0.35)
    button.layer.borderWidth = 5
    button.layer.borderColor = UIColor(white: 1.0, alpha: 0.75).cgColor
    
    // Add button events
    button.addTarget(viewController, action:#selector(viewController.buttonNoteOn), for: .touchDown)
    button.addTarget(viewController, action:#selector(viewController.buttonNoteOff), for: .touchUpInside)
    button.addTarget(viewController, action:#selector(viewController.buttonNoteOff), for: .touchUpOutside)
    
    return button
}
