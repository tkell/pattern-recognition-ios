//
//  PostHelpers.swift
//  pattern-recognition-ios
//
//  Created by Thor Kell on 1/29/18.
//  Copyright © 2018 Thor Kell. All rights reserved.
//

import UIKit
import AudioKit

func makeRequest(buttons: Array<[String : Any]>, adventure: Int) -> URLRequest {
    var request = URLRequest(url: URL(string: "http://pattern-rec.tide-pool.link/pattern-rec/analysis")!)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    let jsonBody = ["adventure": adventure, "buttonData": buttons] as [String: Any]
    let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody, options: .prettyPrinted)
    request.httpBody = jsonData
    return request
}

func midiToFreq(note: Int) -> Double {
    let semitone = pow(2.0, (1.0/12.0))
    // haha wow, type conversion in Swift
    return Double(truncating: 440.0 * pow(semitone, (note - 69.0)) as NSNumber)
}

func makeOfflineScale(numNotes: Int) -> Array<Dictionary<String, Any>> {
    let steps = [2, 2, 3, 2, 3]
    var scale: [Dictionary<String, Any>] = []
    var midiNumbers: [Int] = []
    for i in 0...numNotes - 1 {
        var note: [String: Any] = [:]
        var nextNum = 60
        if midiNumbers.count != 0 {
            nextNum = midiNumbers.last! + steps[i % steps.count]
        }
        midiNumbers.append(nextNum)
        note["freq"] = midiToFreq(note: nextNum)
        note["midi"] = UInt8(nextNum)
        scale.append(note)
    }
    return scale
}

func offlineMap(buttonMap: [String: NoteButton]) -> Void {
    let noteFreqs = makeOfflineScale(numNotes: buttonMap.count)
    print("the notes", noteFreqs)
    var oscIndex = 0
    for theButton in buttonMap.values {
        theButton.oscillatorIndex = oscIndex
        theButton.freq = noteFreqs[oscIndex]["freq"] as! Double
        theButton.noteNumber = noteFreqs[oscIndex]["midi"] as! UInt8
        oscIndex = oscIndex + 1
        theButton.clickable = true
        }
    }


func mapResponse(data: Data, buttonMap: [String : UIButton]) -> Void {
    do {
        var oscIndex = 0
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        for b in json!["mapping"] as! [AnyObject] {
            let loc = b["location"]! as! [String: Int]
            let xVal = loc["x"]!
            let yVal = loc["y"]!
            let key = "\(xVal)---\(yVal)"
            let theButton = buttonMap[key] as! NoteButton
            let f = b["noteFreq"] as! Double
            
            theButton.oscillatorIndex = oscIndex
            oscIndex = oscIndex + 1
            
            theButton.freq = f
            // Sometimes we don't have a midi number
            theButton.noteNumber = 100
            let m = b["noteMIDI"]
            if m! != nil {
                theButton.noteNumber = m as! UInt8
            }
            theButton.clickable = true
        }
    } catch {
        print("Error deserializing JSON: \(error)")
    }
}
