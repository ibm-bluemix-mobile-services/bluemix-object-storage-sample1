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

class LoginViewController: UIViewController {

    let logger = Logger.logger(forName: "LoginViewController")

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    let authenticationRealm = "<realmName>"
    var authDelegate: MyAuthDelegate?

    override func viewDidLoad() {

        super.viewDidLoad()
        Logger.sdkDebugLoggingEnabled = true

        self.usernameField.enabled = false
        self.passwordField.enabled = false
        self.loginButton.enabled = false
		self.indicator.startAnimating()

        let tapRecognizer = UITapGestureRecognizer(target:self, action: #selector(LoginViewController.handleBackgroundTap(_:)))

        tapRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapRecognizer)

        self.authDelegate = MyAuthDelegate(loginViewController: self)

        MCAAuthorizationManager.sharedInstance.registerAuthenticationDelegate(self.authDelegate!, realm: authenticationRealm)
        BMSClient.sharedInstance.authorizationManager.obtainAuthorization { (response, error) in
			self.dispatchOnMainQueueAfterDelay(0, closure: {
				self.indicator.stopAnimating()
				if let error = error{
					self.logger.error("The following error was returned in obtainAuthorization: \(error)")
					self.handleError()
				} else {
					self.logger.debug("obtainAuthorization complete")
					self.handleSuccessfulLogin()
				}
			})
        }
    }

	@IBAction func onLogin(sender: AnyObject) {
		if let username = self.usernameField.text, let password = self.passwordField.text{
			self.usernameField.resignFirstResponder()
			self.passwordField.resignFirstResponder()
			indicator.startAnimating()
			self.authDelegate?.submitCredentials(username, password: password)
		}
	}

    func onAuthChallengeReceived(challenge:AnyObject){
        self.dispatchOnMainQueueAfterDelay(0) {
			self.indicator.stopAnimating()
			self.usernameField.enabled = true
			self.passwordField.enabled = true
			self.loginButton.enabled = true
		}
    }

    func handleSuccessfulLogin() {
		performSegueWithIdentifier("showNavigationController", sender: nil)
    }

    func handleUnsuccessfulLogin() {
		dispatchOnMainQueueAfterDelay(0) {
			self.indicator.stopAnimating()
			let alert = UIAlertController(title: "", message: "Login unsuccesfull", preferredStyle: UIAlertControllerStyle.Alert)
			alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
			self.presentViewController(alert, animated: true, completion: nil)
		}
    }

    func handleError() {
        let alert = UIAlertController(title: "", message: "An error occurred", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Destructive, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

	func dispatchOnMainQueueAfterDelay(delay:Double, closure:()->()) {
		dispatch_after(
			dispatch_time(
				DISPATCH_TIME_NOW,
				Int64(delay * Double(NSEC_PER_SEC))+100
			),
			dispatch_get_main_queue(), closure)
	}

	func handleBackgroundTap(sender: UITapGestureRecognizer) {
		usernameField.resignFirstResponder()
		passwordField.resignFirstResponder()
	}

}
