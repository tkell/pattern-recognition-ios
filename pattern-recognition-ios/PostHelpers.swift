//
//  PostHelpers.swift
//  pattern-recognition-ios
//
//  Created by Thor Kell on 1/29/18.
//  Copyright © 2018 Thor Kell. All rights reserved.
//

import UIKit

func makeRequest(buttons: Array<[String : Any]>, adventure: Int) -> URLRequest {
    var request = URLRequest(url: URL(string: "http://tide-pool.link/pattern-rec/analysis")!)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    let jsonBody = ["adventure": adventure, "buttonData": buttons] as [String: Any]
    let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody, options: .prettyPrinted)
    request.httpBody = jsonData
    return request
}

func mapResponse(data: Data, buttonMap: [String : UIButton]) -> Void {
    do {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        for b in json!["mapping"] as! [AnyObject] {
            let loc = b["location"]! as! [String: Int]
            let xVal = loc["x"]!
            let yVal = loc["y"]!
            let key = "\(xVal)---\(yVal)"
            let theButton = buttonMap[key] as! NoteButton
            let f = b["noteFreq"] as! Double
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
