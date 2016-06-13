# Swift iOS Object Storage Sample for Bluemix Mobile Services
---
This project is a sample photo sharing application which fetches images from an Object Storage container and displays them to a user. The user can upload a photo from either the photo library or the camera directly to Object Storage.

This project contains:

1. A swift iOS project to help familiarize yourself with the Object Storage SDK
2. A simple custom identity provider to be used in conjunction with the Mobile Client Access service on Bluemix

### Before you begin
Before you begin, ensure you have a [Bluemix](http://bluemix.net) account.

### Download this Sample
Clone the sample from GitHub using the following command:

`git clone https://github.com/ibm-bluemix-mobile-services/`

### Configure the custom identity provider
Before running the sample iOS application an instance of the Mobile Client Access service will need to be created along with an instance of the Object Storage service. This identity provider will need to be configured in order to work with the Object Storage instance you created in the previous step.

Open `custom-identity-provider/app.js` and edit the userRepository object to contain the iOS application 'users.'

### Set-up Mobile Client Access
Deploy the custom identity provider to Bluemix. After successfully deploying the custom identity provider an instance of Mobile Client Access will need to be created and bound to the identity provider

Create an instance of Mobile Client Access:

1. From the Mobile section of the Bluemix Catalog, create an instance of the Mobile Client Access service
2. Bind the service instance to the custom identity provider just deployed
3. Setup the custom identity provider with Mobile Client Access

### Create Object Storage instance
Object Storage credentials are used by both the sample iOS app and the custom identity provider. Before setting up either of these, an instance of the Object Storage service will need to be created.

Create an instance of the Object Storage service:

1. From the Storage section of the Bluemix Catalog, create an instance of the Object Storage service and bind it the custom identity provider previously deployed
2. When the service has been created, navigate to the Service Credentials tab
3. Make note of the projectId

### Configure the sample iOS application
Build the project and necessary dependencies using either Cocoapods. Edit the `Podfile` as follows:
```
target 'object-storage-sample-ios' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for object-storage-sample-ios
  pod 'BluemixObjectStorage'
  pod 'BMSSecurity'
end
```

Now run `pod install` and open the `.xcworkspace` that is generated.

Edit the following line in `AppDelegate.swift` with the appropriate app GUID, region, and URL:

```swift
BMSClient.sharedInstance.initializeWithBluemixAppRoute("<application-url>", bluemixAppGUID: "<appGuid>", bluemixRegion: "<region>")
```

Edit the following line in `LoginViewController.swift` to match the realm name used when the custom identity provider was setup with Mobile Client Access:

```swift
let customRealm = "<realmName>"
```

Edit the follwoing function in `PhotoListController.swift` by replacing `<projectId>` with the project id obtained from the Object Storage credentials earlier:

```swift
func connect() {

    let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    let token = defaults.stringForKey("token");
    self.objectStorage = ObjectStorage(projectId: "<projectId>");

    if let objectStorage = objectStorage {

        objectStorage.connect(token: token, region: ObjectStorage.REGION_DALLAS, completionHandler: { (error) in

            ...
        })
    }
}
```

Edit the follwoing function in `PhotoListController.swift` by replacing `<container>` with the container name you wish to work with:

```swift
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
```


### Run the sample iOS application
When you run the sample iOS application the first screen presented is a login screen. The login screen authenticates a user using the `userRepository` defined in the custom identity provider. If the user identity is verified, then the custom identity provider proceeds to authenticate with OpenStack Identity (Keystone) returning an auth token to the client to be used with calls to Object Storage.

### License
This package contains sample code provided in source code form. The samples are licensed under the under the Apache License, Version 2.0 (the "License"). You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 and may also view the license in the license.txt file within this package. Also see the notices.txt file within this package for additional notices.