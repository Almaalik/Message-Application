//
//  ViewController.swift
//  Message App
//
//  Created by macbook  on 20/02/21.
//  Copyright © 2021 Almaalik. All rights reserved.
//

import UIKit
import CLTypingLabel
import Firebase

//import GoogleSignIn

class WelcomeViewController: UIViewController {
    


    @IBOutlet weak var titleLabel: CLTypingLabel!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet var label: UILabel!
    
    @IBAction func loginButton(_ sender: UIButton) {
       
        guard  let email = emailTextfield.text,
           let password = passwordTextfield.text,
        !email.isEmpty, !password.isEmpty else {
                alertUserLoginError()
                return
        }
        //Firebase login
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in

            guard let result = authResult, error == nil else {

                print("Failed to log IN user WITH email \(email)")
                self?.label.text = "Failed to login with the user \(email).Please enter the vaild username and password!!!"

                return
            }
            
            let user = result.user
            print("value for the current login User is :\(user)")

            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case.success(let data):
                    guard let userData = data as? [String: Any],
                        let firstName = userData["first_name"] as? String,
                    let lastName = userData["last_name"]as? String
                    else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName)\(lastName)", forKey: "name")
                    
                case.failure(let error):
                    print("Failed to read data with error: \(error)")

                }
            })
            
            UserDefaults.standard.set(email, forKey: "email")

            print("Logged in User:\(user)")
                self?.performSegue(withIdentifier: "LoginToChat", sender: self)

        })
                }
        func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops", message: "Please enter all information for login", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name("didLogInNotification"), object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })

        navigationItem.hidesBackButton = true
        let name = "Message App 💬"
        titleLabel?.text? = name
    }
        override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.isNavigationBarHidden = true
        }
    
    private var loginObserver: NSObjectProtocol?
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

}


