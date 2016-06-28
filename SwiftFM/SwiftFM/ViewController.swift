//
//  ViewController.swift
//  SwiftFM
//
//  Created by Mary Martinez on 1/7/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import UIKit
import Alamofire
import Haneke

class ViewController: UITableViewController {

    var refreshPullControl: UIRefreshControl!
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    var people = [Person]()
    var xmlData = NSData()
    var uploadImage : UIImage!
    
    @IBAction func cancelToPersonViewController(segue: UIStoryboardSegue) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func savePersonDetail(segue: UIStoryboardSegue) {
        //add the new person to the people array
        if let personDetailViewController = segue.sourceViewController as? PersonDetailViewController {
            
            self.showSpinner(true)

            //add the new player to the players array
            if let p = personDetailViewController.person {
                
                // create record on bg queue
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                    self.uploadImageFile(personDetailViewController.imageView.image!, completion: { (imagePath, error) -> Void in

                        // we've got the image now let FileMaker create the record and upload from url
                        if imagePath != nil {
                            let person = Person(name: p.name, email: p.email, photo: imagePath)
                            self.createRecord(person.name, email: person.email, image: imagePath, completion: { (error) -> Void in
                                
                                // got the data, now reload the cells
                                dispatch_async(dispatch_get_main_queue(), {
                                    if error == nil { // no error
                                        self.showSpinner(false)
                                        
                                        //update the tableView
                                        self.people.append(person)
                                        let indexPath = NSIndexPath(forRow: self.people.count-1, inSection: 0)
                                        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                                    }
                                    else {
                                        // TODO: handle error - display popup dialog
                                    }
                                })
                            })
                        }
                    })
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // query the db for records
        self.getData()
        
        // setup for pull-to-refresh
        self.refreshPullControl = UIRefreshControl()
        self.refreshPullControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshPullControl)
    }
    
    override func viewWillAppear(animated: Bool) {
        activityIndicator.frame = self.view.frame
        activityIndicator.center = self.view.center
        activityIndicator.backgroundColor = UIColor.clearColor()
        activityIndicator.hidesWhenStopped = true
    }
    
    func showSpinner(display: Bool) {
        if display {
            if !activityIndicator.isAnimating() {
                activityIndicator.startAnimating()
                self.view.addSubview(activityIndicator)
            }
        }
        else {
            if activityIndicator.isAnimating() {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    func getData() {

        // fetch data in background process
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            
            Alamofire.request(.GET, Variables.myPeople)
                .response {  request, response, data, error in
                    let xml = SWXMLHash.parse(data!)
                    print(xml)
                    
                    // parse the XML resultset data
                    self.xmlData = data!
                    self.people.removeAll()
                    for elem in xml["fmresultset"]["resultset"]["record"] {
                        let name : String? = elem["field"][2]["data"].element!.text!
                        let email : String? = elem["field"][3]["data"].element!.text
                        
                        // store the photo url if there is one
                        let url : String? = elem["field"][1]["data"].element!.text
                        var photo = ""
                        if (url != nil) {
                            photo = Variables.fmIP + url!
                        }
                        
                        // create a Person object to cache record data
                        self.people.append(Person(name: name, email: email, photo: photo))
                    }
                    
                    // got the data, now reload the cells
                    dispatch_async(dispatch_get_main_queue(), {
                        self.tableView.reloadData()
                    })
            }
        })
    }

    func createRecord(name: String?, email: String?, image: String?, completion:(error: NSError?) -> Void) {
        
        // ensure we character encode any parameters in the URL
        let recordParams = name! + "|" + email! + "|" + image!
        let escapedParams = recordParams.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        
        // create parameters for POST request
        let params = Variables.fmScript + escapedParams! + Variables.findall
        let newRecord = "\(Variables.myPeople)&\(params)"
        
        Alamofire.request(.POST, newRecord)
            .responseData { response -> Void in
                debugPrint(response.result.description)
                switch response.result {
                case .Success:
                    completion(error: nil)
                case .Failure(let error):
                    print(error)
                    completion(error: error as NSError)
                }
        }
    }
    
    func uploadImageFile(image: UIImage, completion:(imagePath: String?, error: NSError?) -> Void) {

        let imageName = createImageTimestamp()
        
        let parameters : Dictionary<String,AnyObject> = [
            "file"   : NetData(jpegImage: image, compressionQuanlity: 1.0, filename: imageName)
        ]
        
        let urlRequest = self.urlRequestWithComponents("\(Variables.hostIP)\(Variables.phpScript)", parameters: parameters)
        
        Alamofire.upload(urlRequest.0, data: urlRequest.1)
            .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
            }
            .responseJSON { response in
                switch response.result {
                case .Success(let data):
                    let json = JSON(data)
                    let path = json["path"].string
                    completion(imagePath: path, error: nil)
                case .Failure(let error):
                    print(error)
                    completion(imagePath: nil, error: error as NSError)
                }
        }
    }
    
    func createImageTimestamp() -> String {
        let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        let removedSpace = timestamp.stringByReplacingOccurrencesOfString(" ", withString: "")
        let removedCommas = removedSpace.stringByReplacingOccurrencesOfString(",", withString: "")
        let result = removedCommas.stringByReplacingOccurrencesOfString(":", withString: "")
        return result + ".jpg"
    }
    
    func urlRequestWithComponents(urlString:String, parameters:NSDictionary) -> (URLRequestConvertible, NSData) {
        
        // create url request to send
        let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        mutableURLRequest.HTTPMethod = Alamofire.Method.POST.rawValue
        //let boundaryConstant = "myRandomBoundary12345"
        let boundaryConstant = "NET-POST-boundary-\(arc4random())-\(arc4random())"
        let contentType = "multipart/form-data;boundary="+boundaryConstant
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // create upload data to send
        let uploadData = NSMutableData()
        
        // add parameters
        for (key, value) in parameters {
            
            uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            
            if value is NetData {
                // add image
                let postData = value as! NetData
                
                // append content disposition
                let filenameClause = " filename=\"\(postData.filename)\""
                let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\";\(filenameClause)\r\n"
                let contentDispositionData = contentDispositionString.dataUsingEncoding(NSUTF8StringEncoding)
                uploadData.appendData(contentDispositionData!)
                
                // append content type
                let contentTypeString = "Content-Type: \(postData.mimeType.getString())\r\n\r\n"
                let contentTypeData = contentTypeString.dataUsingEncoding(NSUTF8StringEncoding)
                uploadData.appendData(contentTypeData!)
                uploadData.appendData(postData.data)
                
            }else{
                uploadData.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".dataUsingEncoding(NSUTF8StringEncoding)!)
            }
        }
        uploadData.appendData("\r\n--\(boundaryConstant)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        // return URLRequestConvertible and NSData
        return (Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: nil).0, uploadData)
    }
    
    
    // MARK: - Refresh Control
    func refresh(sender:AnyObject) {
        
        // fetch data in background process
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            self.getData()
            
            // got the data, now reload the cells
            dispatch_async(dispatch_get_main_queue(), {
                // done loading
                self.refreshPullControl.endRefreshing()
            })
        })
        
    }
    
    // MARK: - TableView delegate
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("PersonCell", forIndexPath: indexPath) as! PersonCell
        let person = people[indexPath.row] as Person
        
        // set the labels
        cell.name.text = person.name
        cell.email.text = person.email
        
        // configure the image
        if person.photo != "" {
            let url = NSURL(string: person.photo!)
            cell.photo.hnk_setImageFromURL(url!)
        }
        else {
            cell.photo.image = UIImage(named: "Person")
        }

        cell.photo.layer.masksToBounds = false
        cell.photo.layer.cornerRadius = cell.photo.frame.size.width / 2
        cell.photo.layer.borderWidth = 1.0
        cell.photo.layer.borderColor = UIColor.lightGrayColor().CGColor
        cell.photo.clipsToBounds = true

        return cell
    }
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as! UINavigationController
        let personDetailVC = navigationController.topViewController as! PersonDetailViewController
        personDetailVC.people = self.people
    }
}

