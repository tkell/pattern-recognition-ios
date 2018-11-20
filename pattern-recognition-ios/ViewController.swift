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
    @IBOutlet weak var adventureSlider: UISlider!
    @IBOutlet weak var adventureSliderLeftLabel: UILabel!
    @IBOutlet weak var adventureSliderRightLabel: UILabel!
    @IBOutlet weak var bottomRedoButton: UIButton!
    @IBOutlet weak var mainPostButton: UIButton!
    @IBOutlet weak var mainTouchLabel: UILabel!
    @IBOutlet weak var firstPostButton: UIButton!
    
    var state: String = "splash"
    var buttonLocList: Array<[String: Any]> = []
    var buttonRefMap: [String: NoteButton] = [:] // Tacky stringmap with 'x---y', ah well.
    var midi = AKMIDI()
    var adventure: Int = 0
    var oscArray: Array<PatternSynth> = []
    
    // The slowness here _appears_ to be debug-load related?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the inputs
        self.bottomImageButton.isHidden = true
        self.adventureSlider.isHidden = true
        self.adventureSliderLeftLabel.isHidden = true
        self.adventureSliderRightLabel.isHidden = true
        self.bottomRedoButton.isHidden = true
        self.mainPostButton.isHidden = true
        self.mainTouchLabel.isHidden = true
        self.firstPostButton.isHidden = true
        
        // Put buttons in the right damn places
        let yGridSize = self.view.frame.size.height / 12
        let xGridSize = self.view.frame.size.width / 12
        let bigFontSize = (yGridSize / 2) - 2
        let mediumFontSize = (yGridSize / 3)
        let smallFontSize = (yGridSize / 5)

        // Splash screen layout
        mainImageButton.frame = CGRect(x: 0, y: yGridSize * 4, width: xGridSize * 12, height: yGridSize)
        mainImageButton.titleLabel?.font = mainImageButton.titleLabel?.font.withSize(bigFontSize)
        
        // Button Assignment screen layout
        self.mainTouchLabel.frame = CGRect(x: 0, y: yGridSize * 4, width: xGridSize * 12, height: yGridSize)
        self.mainTouchLabel.font = self.mainTouchLabel.font.withSize(bigFontSize)
        self.firstPostButton.frame = CGRect(x: xGridSize * 3, y: yGridSize * 10.5, width: xGridSize * 6, height: yGridSize)
        self.firstPostButton.titleLabel?.font = self.firstPostButton.titleLabel?.font.withSize(mediumFontSize)
        
        // Main screen layout
        // Upper level
        self.adventureSlider.frame = CGRect(x: xGridSize * 3, y: yGridSize * 10, width: xGridSize * 6, height: yGridSize / 2)
        self.adventureSliderLeftLabel.frame = CGRect(x: xGridSize * 0, y: yGridSize * 10, width: xGridSize * 3, height: yGridSize / 2)
        self.adventureSliderLeftLabel.font = self.adventureSliderLeftLabel.font.withSize(smallFontSize)
        self.adventureSliderRightLabel.frame = CGRect(x: xGridSize * 9, y: yGridSize * 10, width: xGridSize * 3, height: yGridSize / 2)
        self.adventureSliderRightLabel.font = self.adventureSliderRightLabel.font.withSize(smallFontSize)

        // Lower level
        self.mainPostButton.frame = CGRect(x: xGridSize * 4, y: yGridSize * 11, width: xGridSize * 4, height: yGridSize / 2)
        self.mainPostButton.titleLabel?.font = mainPostButton.titleLabel?.font.withSize(smallFontSize)
        self.bottomImageButton.frame = CGRect(x: xGridSize * 0.5, y: yGridSize * 11, width: xGridSize * 3.0, height: yGridSize / 2)
        self.bottomImageButton.titleLabel?.font = bottomImageButton.titleLabel?.font.withSize(smallFontSize)
        self.bottomRedoButton.frame = CGRect(x: xGridSize * 8.5, y: yGridSize * 11, width: xGridSize * 3.0, height: yGridSize / 2)
        self.bottomRedoButton.titleLabel?.font = bottomRedoButton.titleLabel?.font.withSize(smallFontSize)
        
        // Load the synths async
        let background = DispatchQueue.global()
        background.async {
            for index in 0...11 {
                self.oscArray.append(PatternSynth())
                AudioKit.output = self.oscArray[index].mixer
                print(index, "added synth")
            }
        }

        // Allow touches on the image
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(imageTapped(tapGestureRecognizer:)))

        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        
        let width = UInt32(self.view.frame.size.width)
        let height = UInt32(self.view.frame.size.height)
        doSplashAnimation(width: width, height: height, self: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // ** SLIDER FUNCTIONS
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        sender.setValue(sender.value.rounded(.down), animated: true)
        self.adventure = Int(sender.value.rounded(.down))
        print(adventure)
        
        // re-do the map here too!
        sendPostRequest(mainImageButton) // A dummy button.
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
        do {
            try AudioKit.stop()
        } catch is Error {
            print("AudioKit failed to stop!")
        }
        state = "photoTaken"
    }
    
    // ** POST REQUEST CODE
    func startAudioAfterPost() -> Void {
        do {
            try AudioKit.start()
        } catch is Error {
            print("AudioKit failed to start!")
        }
        self.midi.openOutput()
        self.state = "mapDone"
    }
    
    @IBAction func sendPostRequest(_ sender: UIButton) {
        // Don't map twice unless we have an image, and have at least 3 buttons
        if self.state != "photoTaken" && self.state != "mapDone"  || self.buttonLocList.count < 3 {
            return
        }
        
        self.bottomImageButton.isHidden = false
        self.adventureSlider.isHidden = false
        self.adventureSliderLeftLabel.isHidden = false
        self.adventureSliderRightLabel.isHidden = false
        self.bottomRedoButton.isHidden = false
        self.mainPostButton.isHidden = false
        self.firstPostButton.isHidden = true

        doMapAnimation(buttonLocList: buttonLocList, view: view, reverse: false)
        doMapAnimation(buttonLocList: buttonLocList, view: view, reverse: true)

        // Create request
        let request = makeRequest(buttons: buttonLocList, adventure: self.adventure)

        // Send & deal with the response
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error, falling back to offline mapping")
                offlineMap(buttonMap: self.buttonRefMap)
                self.startAudioAfterPost()
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("falling back to offline mapping")
                offlineMap(buttonMap: self.buttonRefMap)
                self.startAudioAfterPost()
                return
            }
            
            // in mapResponse, we'll send in the array of synths, and assign them
            mapResponse(data: data, buttonMap: self.buttonRefMap)
            print("online mapping successful")
            self.startAudioAfterPost()
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
    }
    
    // ** CAMERA CODE **
    func doFadeOut() {
        // Function to fade out the label, used by camera code
        UIView.animate(withDuration: 5, animations: {
            self.mainTouchLabel.alpha = 0.0
        })
    }
    
    @IBAction func useCamera(_ sender: Any) {
        // All this code is called when the camera is used, as you would hope.
        if TARGET_OS_SIMULATOR == 1 {
            print("We are on the simulator, going direct to the next state")
            // Remove any old buttons, update state
            _ = buttonRefMap.values.map {b in b.removeFromSuperview()}
            buttonRefMap = [:]
            buttonLocList = []
            if self.state == "mapDone" {
                self.mainTouchLabel.alpha = 1.0
                self.mainTouchLabel.isHidden = false
            } else {
                self.mainImageButton.isHidden = true
                self.firstPostButton.isHidden = false
                self.mainTouchLabel.isHidden = false
            }
            self.state = "photoTaken"
            // We could maybe load a static or programmatic image here, but let's fix all of our layouts first, god
        } else {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                imagePicker.mediaTypes = [kUTTypeImage as String]
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
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
                self.firstPostButton.isHidden = false
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

