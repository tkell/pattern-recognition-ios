//
//  NoteButton.swift
//  pattern-recognition-ios
//
//  Created by Thor Kell on 1/21/18.
//  Copyright © 2018 Thor Kell. All rights reserved.
//

import UIKit
import AudioKit

class NoteButton: UIButton {
    var freq: Double
    var noteNumber: MIDINoteNumber
    var clickable: Bool
    
    var oscillatorIndex: Int
    
    var lineLayers: Array<CAShapeLayer>
    
    required init(freq: Double = 0, noteNumber: UInt8 = 0, frame: CGRect) {
        self.freq = freq
        self.noteNumber = noteNumber
        self.clickable = false
        self.lineLayers = []
        self.oscillatorIndex = -1 // dummy value
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
