//
//  ViewController.swift
//  pattern-recognition-ios
//
//  Created by Thor Kell on 11/10/17.
//  Copyright © 2017 Thor Kell. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    var newMedia: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
    
    @IBAction func sendPostRequest(_ sender: UIButton) {
        print("we have pressed the POST button")
    }
    
    // ** TAP + BUTTON CREATION CODE
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        _ = tapGestureRecognizer.view as! UIImageView
        // we can wrap this in `if (newMedia)`,
        // but we won't do it yet because then we can't test it on the simulator.
        let touchPoint = tapGestureRecognizer.location(in: self.view)
        let button = UIButton(frame: CGRect(x: touchPoint.x, y: touchPoint.y, width: 50, height: 50))
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        button.backgroundColor = UIColor.red
        button.alpha = 0.5
        view.addSubview(button)
        // We should also keep a list of buttons somewhere, but we can wait on that.
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
            newMedia = true
        }
    }
    
    // Load the image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        self.dismiss(animated: true, completion: nil)
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            imageView.image = image
            
            if (newMedia == true) {
                UIImageWriteToSavedPhotosAlbum(image,
                                               self,
                                               #selector(image(_:didFinishSavingWithError:contextInfo:)),
                                               nil)
            } else if mediaType.isEqual(to: kUTTypeMovie as String) {
                // Code to support video here - not for this project!
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
    
    // More Strange boilterplate for loading the image
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }   
}

