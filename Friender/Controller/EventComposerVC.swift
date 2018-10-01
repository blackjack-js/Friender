//
//  AddEventVC.swift
//  Friender
//
//  Created by mac on 8/29/18.
//  Copyright © 2018 storm. All rights reserved.
//

import UIKit
import MaterialComponents
import Firebase
import FirebaseDatabase
import FirebaseStorage
import CoreLocation
import GoogleSignIn

class EventComposerVC: UIViewController, UITextFieldDelegate {
    
    let tapRec = UITapGestureRecognizer()
    
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var addEventButton: UIButton!
    @IBOutlet weak var eventTitleTextField: MDCTextField!
    @IBOutlet weak var addImageButton: UIBarButtonItem!
    @IBOutlet weak var progressView: UIProgressView!
    
    fileprivate let picker = UIImagePickerController()
    fileprivate var storageImagePath = ""
    fileprivate var ref: DatabaseReference!
    fileprivate var storageRef: StorageReference!
    fileprivate var storageUploadTask: StorageUploadTask!
    fileprivate var endDate: TimeInterval!
    fileprivate var imageData: Data!
    let color = UIColor(red:0.65, green:0.42, blue:0.95, alpha:1.0)
    
    var eventCoords: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        storageRef = Storage.storage().reference()
        picker.delegate = self
        eventTitleTextField.placeholder = "Tell people about your event"
        eventTitleTextField.cursorColor = UIColor(red:0.65, green:0.42, blue:0.95, alpha:1.0)
        eventTitleTextField.delegate = self
        progressView.progress = 0
        addEventButton.isUserInteractionEnabled = false
        addEventButton.isEnabled = false
        addEventButton.alpha = 0.5
       
        self.setupHideKeyboardOnTap()


    }
    
    // Setup for activity indicator to be shown when uploading image
    fileprivate var showNetworkActivityIndicator = false {
        didSet {
            UIApplication.shared.isNetworkActivityIndicatorVisible = showNetworkActivityIndicator
        }
    }
    
    // MARK: - Functions
    fileprivate func writeEventToDatabase(_ event: Event, _ autoID: DatabaseReference) {
        // Access the "unicorns" child reference and then access (create) a unique child reference within it and finally set its value
        autoID.setValue(event.toAnyObject())
    }
    
    fileprivate func uploadSuccess(_ storagePath: String) {
        
        if eventTitleTextField.text != "" {
            addEventButton.isUserInteractionEnabled = true
            addEventButton.isEnabled = true
            addEventButton.alpha = 1
        }

        // Updated global variable for the storage path for the selected image
        storageImagePath = storagePath
        
    }

    
    func camera()
    {
        let myPickerController = UIImagePickerController()
        myPickerController.delegate = self;
        myPickerController.sourceType = UIImagePickerController.SourceType.camera
        
        self.present(myPickerController, animated: true, completion: nil)
        
    }
    
    func photoLibrary()
    {
        
        let myPickerController = UIImagePickerController()
        myPickerController.delegate = self;
        myPickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        self.present(myPickerController, animated: true, completion: nil)
        
    }
    
    func showActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: UIAlertAction.Style.default, handler: { (alert:UIAlertAction!) -> Void in
            self.camera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: UIAlertAction.Style.default, handler: { (alert:UIAlertAction!) -> Void in
            self.photoLibrary()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    
     func textFieldDidBeginEditing(_ textField: UITextField) {
        if eventTitleTextField.text != "" && eventImage.image != nil {
            addEventButton.isUserInteractionEnabled = true
            addEventButton.isEnabled = true
            addEventButton.alpha = 1

        } else {
            addEventButton.isUserInteractionEnabled = false
            addEventButton.isEnabled = false
            addEventButton.alpha = 0.5

        }
        }
    
    @IBAction func addEventButtonWasPressed(_ sender: Any) {
        // Get properties for the unicorn-to-be-created
        let title = self.eventTitleTextField.text ?? ""
        let eventRef = ref.child("events").child(user!.uid).childByAutoId()
        let autoID = eventRef.key
        // 2. Create a unique image path for image. In the case I am using the googleAppId of my account appended to the interval between 00:00:00 UTC on 1 January 2001 and the current date and time as an Integer and then I append .jpg. You can use whatever you prefer as long as it ends up unique.
        let storageRef = Storage.storage().reference()
        let uid = user?.uid
        let imagePath = storageRef.child("/events/"+(autoID)+"/event_pic.jpg")
        
        // 3. Set up metadata with appropriate content type
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // 4. Show activity indicator
        showNetworkActivityIndicator = true
        // To make the activity indicator appear:
        let activityIndicator = MDCActivityIndicator()
        activityIndicator.sizeToFit()
        activityIndicator.cycleColors = [.blue, .red, .green, .yellow]
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        
        // To make the activity indicator appear:
        activityIndicator.startAnimating()
        // 5. Start upload task
        
        storageUploadTask = imagePath.putData(imageData, metadata: metadata, completion: { (metadata, error) in
            // 6. Hide activity indicator because uploading is done with or without an error
            self.showNetworkActivityIndicator = false
            // To make the activity indicator disappear:
            activityIndicator.stopAnimating()
            
            guard error == nil else {
                print("Error uploading: \(error!)")
                return
            }
            
            self.uploadSuccess(uid!)
        })
        
        let event = Event(imagePath: autoID, title: title, addedBy: (GIDSignIn.sharedInstance()?.currentUser.profile.name)!, key: autoID, userPicture: (user?.uid)!)
        // Create the unicorn and record it
        writeEventToDatabase(event, eventRef)
        ref.child("events").child(user!.uid).child(autoID).child("endDate").setValue(endDate)
        pushLocation.instance.pushAnnotationLocation(eventCoords!, key: autoID)
    }
    
    @IBAction func addImageButtonWasPressed(_ sender: Any) {
        showActionSheet()
    }
    
    
    @IBAction func datePickerWasPressed(_ sender: Any) {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        
        let alert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)

        
        let ok = UIAlertAction(title: "ok", style: .default) { (action) in
            let dateFormatter = DateFormatter()
            
            dateFormatter.dateStyle = DateFormatter.Style.short
            dateFormatter.timeStyle = DateFormatter.Style.short
            self.endDate = datePicker.date.timeIntervalSince1970

        }
        
        let cancel = UIAlertAction(title: "cancel", style: .default, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
}
    

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension EventComposerVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        picker.dismiss(animated: true, completion: nil)
        
        // 1. Get image data from selected image
        guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage,
            let imageData = image.jpegData(compressionQuality: 0.5) else {
                
                print("Could not get Image JPEG Representation")
                addEventButton.isUserInteractionEnabled = false
                addEventButton.isEnabled = false
                addEventButton.alpha = 0.5
                
                return
        }
        eventImage.image = image
        self.imageData = imageData
        if eventImage.image != nil && eventTitleTextField.text != "" {
            addEventButton.isUserInteractionEnabled = true
            addEventButton.isEnabled = true
            addEventButton.alpha = 1
        }
    
}
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

}

extension UIViewController {
    /// Call this once to dismiss open keyboards by tapping anywhere in the view controller
    func setupHideKeyboardOnTap() {
        self.view.addGestureRecognizer(self.endEditingRecognizer())
        self.navigationController?.navigationBar.addGestureRecognizer(self.endEditingRecognizer())
    }
    
    /// Dismisses the keyboard from self.view
    private func endEditingRecognizer() -> UIGestureRecognizer {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(self.view.endEditing(_:)))
        tap.cancelsTouchesInView = false
        return tap
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
