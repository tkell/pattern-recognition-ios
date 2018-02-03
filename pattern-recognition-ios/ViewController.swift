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

    var state: String = "splash"
    var buttonLocList: Array<[String: Any]> = []
    var buttonRefMap: [String: UIButton] = [:] // Tacky stringmap with 'x---y', ah well.
    var midi = AKMIDI()
    var adventure: Int = 0
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the inputs
        if state == "splash" {
            self.bottomImageButton.isHidden = true
            self.adventureSlider.isHidden = true
            self.bottomPostButton.isHidden = true
        }
        
        // Allow touches on the image
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
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
            playNote(midi: midi, oscs: [sender.osc1, sender.osc2], note: sender.noteNumber, vel: 90, freq: sender.freq)
            doButtonTouchAnimation(b: sender, otherButtons: self.buttonLocList, view: view)
         }
    }
    
    @objc func buttonNoteOff(sender:NoteButton) {
        if sender.clickable {
            stopNote(midi: midi, oscs: [sender.osc1, sender.osc2], note: sender.noteNumber)
            finishButtonTouchAnimation(b: sender)
        }
    }
    
    
    // ** POST REQUEST CODE
    @IBAction func sendPostRequest(_ sender: UIButton) {
        // Don't map twice, don't map if we have no image
        if self.state != "photoTaken" && self.state != "mapDone" {
            return
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
            
            // Remove old buttons, update state
            _ = buttonRefMap.values.map {b in b.removeFromSuperview()}
            buttonRefMap = [:]
            buttonLocList = []
            state = "photoTaken"
            if state == "photoTaken" {
                self.mainImageButton.isHidden = true
                self.bottomImageButton.isHidden = false
                self.adventureSlider.isHidden = false
                self.bottomPostButton.isHidden = false
            }
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

