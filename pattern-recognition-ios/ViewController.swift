//
//  ViewController.swift
//  pattern-recognition-ios
//
//  Created by Thor Kell on 11/10/17.
//  Copyright © 2017 Thor Kell. All rights reserved.
//

import UIKit
import MobileCoreServices
import AudioKit


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    var newMedia: Bool?
    var hasMapped: Bool?
    var buttonLocList: Array<[String: Any]> = []
    var buttonRefMap: [String: UIButton] = [:] // Tacky stringmap with 'x---y', ah well.
    // var context: CGContext? = nil
    var midi = AKMIDI()
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Awkward booleans for my own state
        newMedia = false
        hasMapped = false
        
        // Allow touches on the image
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // ** CUSTOM BUTTON CLASS
    class NoteButton: UIButton {
        var freq: Double
        var noteNumber: MIDINoteNumber
        var clickable: Bool

        var osc1: AKOscillatorBank
        var filter1: AKLowPassFilter
        var delay1: AKDelay
        var osc2: AKOscillatorBank
        var filter2: AKLowPassFilter
        var delay2: AKDelay
        
        var lineLayers: Array<CAShapeLayer>

        
        required init(freq: Double = 0, noteNumber: UInt8 = 0, frame: CGRect) {
            self.freq = freq
            self.noteNumber = noteNumber
            self.clickable = false
            self.lineLayers = []
            
            // Set up audio signal paths
            self.osc1 = AKOscillatorBank(waveform: AKTable(.square),
                                        attackDuration: 0.125,
                                        decayDuration: 0.25,
                                        sustainLevel: 0.2,
                                        releaseDuration: 0.1
            )
            self.filter1 = AKLowPassFilter(osc1, cutoffFrequency: 6500.0, resonance: 0.1)
            self.delay1 = AKDelay(filter1, time: 0.166, feedback: 0.35, dryWetMix: 0.1)

            self.osc2 = AKOscillatorBank(waveform: AKTable(.triangle),
                                        attackDuration: 0.1,
                                        decayDuration: 0.20,
                                        sustainLevel: 0.25,
                                        releaseDuration: 0.2
            )
            self.filter2 = AKLowPassFilter(osc2, cutoffFrequency: 8000.0, resonance: 0.1)
            self.delay2 = AKDelay(filter1, time: 0.15, feedback: 0.4, dryWetMix: 0.2)

            // Assign to output
            AudioKit.output = AKMixer(self.delay1, self.delay2)
            super.init(frame: frame)
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    

    
    // ** BUTTON CLICK FUNCTIONS
    @objc func buttonNoteOn(sender:NoteButton) {
        if (sender.clickable && hasMapped!) {
            midi.sendEvent(AKMIDIEvent(noteOn: sender.noteNumber, velocity: 90, channel: 1))
            sender.osc1.play(noteNumber: sender.noteNumber, velocity: 90, frequency: sender.freq)
            sender.osc2.play(noteNumber: sender.noteNumber, velocity: 90, frequency: sender.freq)

            sender.backgroundColor = UIColor(white: 0.0, alpha: 0.75)
            sender.layer.borderColor = UIColor(white: 1.0, alpha: 1.0).cgColor
            

            self.buttonLocList.forEach { loc in
                let path = UIBezierPath()
                path.move(to: CGPoint(x: sender.frame.midX, y: sender.frame.midY))
                let temp = loc["location"] as! [String : Int]
                let xLoc = temp["x"]!
                let yLoc = temp["y"]!
                path.addLine(to: CGPoint(x: xLoc, y: yLoc))
                path.close()
                let layer = CAShapeLayer()
                layer.strokeColor = UIColor.white.cgColor
                sender.lineLayers.append(layer)
                
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
    }
    
    @objc func buttonNoteOff(sender:NoteButton) {
        if (sender.clickable) {
            midi.sendEvent(AKMIDIEvent(noteOff: sender.noteNumber, velocity: 0, channel: 1))
            sender.osc1.stop(noteNumber: sender.noteNumber)
            sender.osc2.stop(noteNumber: sender.noteNumber)
            
            sender.backgroundColor = UIColor(white: 0.0, alpha: 0.35)
            sender.layer.borderColor = UIColor(white: 1.0, alpha: 0.75).cgColor
            
            sender.lineLayers.forEach { layer in
                layer.removeFromSuperlayer()
            }

        }
    }
    
    
    // ** POST REQUEST CODE
    @IBAction func sendPostRequest(_ sender: UIButton) {
        // Don't map twice, don't map if we have no image
        if (hasMapped! || !newMedia!) {
            return
        }
        
        // Test data!
        /*
        let l1 = ["x": 450, "y": 100] as [String: Int]
        let l2 = ["x": 450, "y": 210] as [String: Int]
        let l3 = ["x": 450, "y": 320] as [String: Int]

        let location1 = ["location": l1] as [String: Any]
        let location2 = ["location": l2] as [String: Any]
        let location3 = ["location": l3] as [String: Any]
        let locationArray = [location1, location2, location3]
        let testDict = ["adventure": 0, "buttonData": locationArray] as [String: Any]
        */
        
        // Create request
        var request = URLRequest(url: URL(string: "http://tide-pool.link/pattern-rec/analysis")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let jsonBody = ["adventure": 0, "buttonData": buttonLocList] as [String: Any]
        let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody, options: .prettyPrinted)
        request.httpBody = jsonData

        // Send & deal with the response
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                // check for fundamental networking error
                print("Network error!")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                AudioKit.start()
                self.midi.openOutput()

                self.hasMapped = true
                for b in json!["mapping"] as! [AnyObject] {
                    let loc = b["location"]! as! [String: Int]
                    let xVal = loc["x"]!
                    let yVal = loc["y"]!
                    let key = "\(xVal)---\(yVal)"
                    let theButton = self.buttonRefMap[key] as! NoteButton
                    let f = b["noteFreq"] as! Double
                    let m = b["noteMIDI"] as! UInt8
                    theButton.freq = f
                    theButton.noteNumber = m
                    theButton.clickable = true
                }
                print("we mapped things!")
            } catch {
                print("Error deserializing JSON: \(error)")
            }
        }
        task.resume()
    }

    
    // ** TAP + BUTTON CREATION CODE
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        _ = tapGestureRecognizer.view as! UIImageView
        // If we've done a mapping, or if we have not taken a picture, get out
        // Don't forget to add back `|| !newMedia!` once we are off the sim!
        if (hasMapped! || !newMedia!) {
            return
        }
        
        let touchPoint = tapGestureRecognizer.location(in: self.view)
        
        // Create the button
        // Take one-tenth of the average of the height and width to be the size of each button
        let buttonSize = (self.view.frame.size.height + self.view.frame.size.width / 2) / 10
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
        button.addTarget(self, action:#selector(self.buttonNoteOn), for: .touchDown)
        button.addTarget(self, action:#selector(self.buttonNoteOff), for: .touchUpInside)
        button.addTarget(self, action:#selector(self.buttonNoteOff), for: .touchUpOutside)
        view.addSubview(button)
        
        let xInt = Int(floor(touchPoint.x))
        let yInt = Int(floor(touchPoint.y))
        
        // Set up the JSON data
        let l = ["x": xInt, "y": yInt] as [String: Int]
        let location = ["location": l] as [String: Any]
        buttonLocList.append(location)

        // Store the button by location so we can assign to it later on
        let key = "\(xInt)---\(yInt)"
        buttonRefMap[key] = button
        
        // This is also a good place to add flair, draw those lines, etc
    }
    
    
    // ** CAMERA CODE **
    @IBAction func useCamera(_ sender: Any) {
        // All this code is called when the camera is used, as you would hope.
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // Load the image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        self.dismiss(animated: true, completion: nil)
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            imageView.image = image
            
            // Remove old buttons, reset state booleans
            _ = buttonRefMap.values.map {b in b.removeFromSuperview()}
            buttonRefMap = [:]
            buttonLocList = []
            hasMapped = false
            newMedia = true
        }
    }
    
    // Strange boilerplate for loading the image.
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            let ac = UIAlertController(title: "Saved!", message: "Image saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(ac, animated: true, completion: nil)
        } else {
            let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(ac, animated: true, completion: nil)
        }
    }
    
    // More strange boilterplate for loading the image
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }   
}

