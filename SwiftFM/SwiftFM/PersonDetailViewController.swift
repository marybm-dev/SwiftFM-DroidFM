//
//  PersonDetailViewController.swift
//  SwiftFM
//
//  Created by Mary Martinez on 1/11/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import UIKit
import MobileCoreServices

class PersonDetailViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var people = [Person]()
    var person : Person?
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "savePersonDetail" {
            person = Person(name: nameTextField.text!, email: emailTextField.text!, photo: "")
        }
    }

    // MARK: - Table view
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            nameTextField.becomeFirstResponder()
        }
        else if indexPath.section == 1 {
            emailTextField.becomeFirstResponder()
        }
        else if indexPath.section == 2 {
            self.uploadImage()
        }
    }
    
    // MARK: - Image picker
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // set the image in the view
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.image = selectedImage
        
        // convert to NSData
        let imageData = UIImagePNGRepresentation(selectedImage)
        print(imageData!.length)

        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func uploadImage() {
        // setup image picker
        let imagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        imagePickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
}
