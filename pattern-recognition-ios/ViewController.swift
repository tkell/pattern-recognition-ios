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
    @IBOutlet weak var mainImageButton: UIButton!
    @IBOutlet weak var bottomImageButton: UIButton!
    @IBOutlet weak var bottomPostButton: UIButton!
    @IBOutlet weak var adventureSlider: UISlider!
    @IBOutlet weak var adventureSliderLeftLabel: UILabel!
    @IBOutlet weak var adventureSliderRightLabel: UILabel!
    @IBOutlet weak var bottomRedoButton: UIButton!
    @IBOutlet weak var mainPostButton: UIButton!
    @IBOutlet weak var mainTouchLabel: UILabel!

    var state: String = "splash"
    var buttonLocList: Array<[String: Any]> = []
    var buttonRefMap: [String: NoteButton] = [:] // Tacky stringmap with 'x---y', ah well.
    var midi = AKMIDI()
    var adventure: Int = 0
    
    var oscArray: Array<PatternSynth> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide the inputs
        self.bottomImageButton.isHidden = true
        self.adventureSlider.isHidden = true
        self.bottomPostButton.isHidden = true
        self.adventureSliderLeftLabel.isHidden = true
        self.adventureSliderRightLabel.isHidden = true
        self.bottomRedoButton.isHidden = true
        self.mainPostButton.isHidden = true
        self.mainTouchLabel.isHidden = true

        // Allow touches on the image
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(imageTapped(tapGestureRecognizer:)))

        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)

        // this is slow, will need to build some flair to distract it
        for index in 0...11 {
            oscArray.append(PatternSynth())
            AudioKit.output = oscArray[index].mixer
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // ** SLIDER FUNCTIONS
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        sender.setValue(sender.value.rounded(.down), animated: true)
        self.adventure = Int(sender.value.rounded(.down))
        print(adventure)
    }

    
    // ** BUTTON CLICK FUNCTIONS
    @objc func buttonNoteOn(sender: NoteButton) {
        if sender.clickable && self.state == "mapDone" {
            let synth = self.oscArray[sender.oscillatorIndex]
            playNote(midi: midi, oscs: synth.oscs, note: sender.noteNumber, vel: 90, freq: sender.freq)
            doButtonTouchAnimation(b: sender, otherButtons: self.buttonLocList, view: view)
         }
    }
    
    @objc func buttonNoteOff(sender:NoteButton) {
        if sender.clickable {
            let synth = self.oscArray[sender.oscillatorIndex]
            stopNote(midi: midi, oscs: synth.oscs, note: sender.noteNumber)
            finishButtonTouchAnimation(b: sender)
        }
    }
    
    // ** RESET BUTTONS CODE
    @IBAction func clearButtons(_ sender: Any) {
        print("clear button, stop audio")
        _ = buttonRefMap.values.map {b in
            b.oscillatorIndex = -1
            b.removeFromSuperview()
        }
        buttonRefMap = [:]
        buttonLocList = []
        AudioKit.stop()
        state = "photoTaken"
    }
    
    // ** POST REQUEST CODE
    @IBAction func sendPostRequest(_ sender: UIButton) {
        // Don't map twice unless we have an image, and have at least 3 buttons
        if self.state != "photoTaken" && self.state != "mapDone"  || self.buttonLocList.count < 3 {
            return
        }
        
        self.bottomImageButton.isHidden = false
        self.adventureSlider.isHidden = false
        self.bottomPostButton.isHidden = false
        self.adventureSliderLeftLabel.isHidden = false
        self.adventureSliderRightLabel.isHidden = false
        self.bottomRedoButton.isHidden = false
        self.mainPostButton.isHidden = true
        
        // This is the draw code
        // Looks ok, but thrashes with more than ~10 buttons!
        buttonLocList.forEach { b1 in
            /*
            let temp = b1["location"] as! [String : Int]
            let xLoc1 = temp["x"]!
            let yLoc1 = temp["y"]!
            buttonLocList.forEach { b2 in
                let path = UIBezierPath()
                path.move(to: CGPoint(x: xLoc1, y: yLoc1))
                let temp = b2["location"] as! [String : Int]
                let xLoc2 = temp["x"]!
                let yLoc2 = temp["y"]!
                path.addLine(to: CGPoint(x: xLoc2, y: yLoc2))
                
                path.close()
                
                let layer = CAShapeLayer()
                layer.strokeColor = UIColor.white.cgColor
                view.layer.addSublayer(layer)
                layer.path = path.cgPath
                
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                /* set up animation */
                animation.fromValue = 0.0
                animation.toValue = 1.0
                animation.duration = (drand48() * 3.5) + 0.5
                layer.add(animation, forKey: "drawLineAnimation")
                
                let fadeAnimation = CABasicAnimation(keyPath: "opacity")
                fadeAnimation.fromValue = 1.0
                fadeAnimation.toValue = 0.0
                fadeAnimation.duration = 3.5
                layer.add(fadeAnimation, forKey: "opacity")
                layer.opacity = 0.0
            }
            */
        }

        // Create request
        let request = makeRequest(buttons: buttonLocList, adventure: self.adventure)

        // Send & deal with the response
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error!")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
            }
            
            // in mapResponse, we'll send in the array of synths, and assign them
            mapResponse(data: data, buttonMap: self.buttonRefMap)
            AudioKit.start()
            self.midi.openOutput()
            self.state = "mapDone"
            print("we mapped things!")
        }
        task.resume()
    }

    
    // ** TAP + BUTTON CREATION CODE
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        _ = tapGestureRecognizer.view as! UIImageView
        // If we've done a mapping, or if we have not taken a picture, get out
        if self.state != "photoTaken" {
            return
        }

        let touchPoint = tapGestureRecognizer.location(in: self.view)
        let buttonSize = (self.view.frame.size.height + self.view.frame.size.width / 2) / 10

        let button = makeButton(touchPoint: touchPoint, buttonSize: buttonSize, viewController: self)
        view.addSubview(button)
        
        // Set up the JSON data
        let xInt = Int(floor(touchPoint.x))
        let yInt = Int(floor(touchPoint.y))
        let l = ["x": xInt, "y": yInt] as [String: Int]
        let location = ["location": l] as [String: Any]
        buttonLocList.append(location)

        // If we need to create a new synth, we do it here
        if buttonLocList.count > oscArray.count {
            oscArray.append(PatternSynth())
            AudioKit.output = oscArray[oscArray.count - 1].mixer
        }

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
    // Function to fade out the label
    func doFadeOut() {
        UIView.animate(withDuration: 5, animations: {
            self.mainTouchLabel.alpha = 0.0
        })
    }
    
    // Load the image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        self.dismiss(animated: true, completion: doFadeOut)
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            imageView.image = image

            // Remove any old buttons, update state
            _ = buttonRefMap.values.map {b in b.removeFromSuperview()}
            buttonRefMap = [:]
            buttonLocList = []
            if self.state == "mapDone" {
                self.mainTouchLabel.alpha = 1.0
                self.mainTouchLabel.isHidden = false
            } else {
                self.mainImageButton.isHidden = true
                self.mainPostButton.isHidden = false
                self.mainTouchLabel.isHidden = false
            }
            self.state = "photoTaken"
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

