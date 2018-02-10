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
        // Set up audio signal paths
        self.oscillatorIndex = -1 // dummy value

//        self.osc1 = createOsc(shape: "square", a: 0.125, d: 0.25, s: 0.2, r: 0.1)
  //      self.osc2 = createOsc(shape: "triangle", a: 0.1, d: 0.2, s: 0.25, r: 0.2)
        
       // self.audioOut = AKMixer(createAudioPath(osc: self.osc1, f: 6500, res: 0.1, t: 0.166, fb: 0.35, mix: 0.1),
       //                           createAudioPath(osc: self.osc2, f: 8000, res: 0.1, t: 0.15, fb: 0.4, mix: 0.2)
       //                        )
       // AudioKit.output = self.audioOut
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
