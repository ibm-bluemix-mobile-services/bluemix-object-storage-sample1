/*
 *     Copyright 2016 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

import UIKit
import BMSCore
import BMSSecurity
import BluemixObjectStorage

class PhotoListController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let logger = Logger.logger(forName: "PhotoListController")
    
    let theFuture = NSDate.distantFuture().timeIntervalSince1970
    
    var objectStorage: ObjectStorage?
    var objectStorageContainer: ObjectStorageContainer?
    var objectList: [ObjectStorageObject]?
    
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    
    override func viewWillAppear(animated: Bool) {
        
        if objectStorage == nil {
            self.connect()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBarHidden = true
        self.navigationController!.toolbarHidden = false

        
        cameraButton.enabled  = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        guard let objectList = objectList else {
            
            return 0
        }
        
        return objectList.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        let cell = tableView.dequeueReusableCellWithIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        guard let objectList = objectList else {
            
            return cell
        }
        
        let objectStorageObject = objectList[indexPath.row]
        
        guard let data = objectStorageObject.data else {
            
            return cell
        }
        let image = UIImage(data: data)
        
        cell.objectImage.image = image
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        
    }
    
    func connect() {
        
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let token = defaults.stringForKey("token");
        self.objectStorage = ObjectStorage(projectId: "<projectId");
        
        if let objectStorage = objectStorage {
            
            objectStorage.connect(token!, region: ObjectStorage.REGION_DALLAS, completionHandler: {
                (error) in
                
                if let error = error {
                    print("connect error :: \(error)")
                } else {
                    print("connect success")
                    self.setContainer()
                }
                
            })
        }
    }
    
    func setContainer() {
        
        self.objectStorage!.retrieveContainer(name: "<container>", completionHandler: { (error, container) in
            
            if let error = error {
                self.logger.error("The following error occurred while attempting to objtain the object storage container: \(error)")
            } else {
                self.objectStorageContainer = container;
                self.setObjectsList()
            }
        })
    }
    
    func setObjectsList() {
        
        guard let objectStorageContainer = objectStorageContainer else {
            
            return
        }
        
        objectStorageContainer.retrieveObjectsList { (error, objects) in
            
            if let error = error {
                self.logger.error("The following error occurred while retrieving the list of objects from object storage: \(error)")
            } else {
                self.objectList = objects
                
                for object in objects! {
                    self.loadData(object)
                }
            }
        }
    }
    
    func loadData(forObject: ObjectStorageObject) {
        
        forObject.load(shouldCache: true) { (error, data) in
            
            if let error = error {
                self.logger.error("The following error occurred while loading an object from the object storage service: \(error)")
            } else {
                self.performSelectorOnMainThread(#selector(PhotoListController.loadView), withObject: nil, waitUntilDone: false)
            }
        }
    }
    
    @IBAction func onPhotoLibrary(sender: AnyObject) {
        
        let imagePicker:UIImagePickerController = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.delegate = self
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }

    @IBAction func onCamera(sender: AnyObject) {
        
        let imagePicker:UIImagePickerController = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        imagePicker.delegate = self
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController){
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let now = NSDate().timeIntervalSince1970
        let imageName = (theFuture - now) * 1000
        
        objectStorageContainer?.storeObject(name: "\(imageName)", data: UIImageJPEGRepresentation(image, 0.7)!, completionHandler: { (error, object) in
            
            if let error = error {
                self.logger.error("The following error occurred while loading an image into the object storage service: \(error)")
            } else {
                
                self.setObjectsList()
            }
        })
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}
