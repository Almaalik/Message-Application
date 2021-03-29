//
//  NewAccountViewController.swift
//  Message App
//
//  Created by macbook  on 21/02/21.
//  Copyright © 2021 Almaalik. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class NewAccountViewController: UIViewController {

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBAction func CreateAccount(_ sender: UIButton) {
        guard let firstName = firstName.text,let lastName = lastName.text, let email = email.text, let password = password.text,
            !email.isEmpty, !password.isEmpty, !firstName.isEmpty, !lastName.isEmpty, password.count >= 6 else {
                alertUserLoginError()
                return
        }
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exists in
            guard !exists else {
                //User already exists
                self?.alertUserLoginError(message: "Looks like a user account for that email address already exist.")
                return
            }
            //If user not exist Create new Account
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let e = error {
                    print("Error occur while creating account: \(e.localizedDescription)")
                } else {
                    ///Navigate to the ChartViewController
                    self?.performSegue(withIdentifier: "CreateToChat", sender: self)
                    print("Sucessfully Create New User")
                    
        UserDefaults.standard.setValue(email, forKey: "email")
        UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")

            let chatUser = MessageApp(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            //upload image
            guard let image = self?.profilePicture.image,
            let data = image.pngData() else {
                return }
                let fileName = chatUser.profilePictureFileName
                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                    switch result {
                    case.success(let downloadUrl):
                    UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                    print(downloadUrl)
                    case.failure(let error):
                    print("Storage manager error: \(error)")
                                }
                            })
                        }
                    })
                }
            }
        })
    }
  
    func alertUserLoginError(message: String = "Please enter all information to Create new Account") {
        let alert = UIAlertController(title: "woops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
         present(alert, animated: true)
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        profilePicture?.layer.cornerRadius = 25

        profilePicture.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
          profilePicture.addGestureRecognizer(gesture)
    }
}

extension NewAccountViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func didTapChangeProfilePic() {
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a  picture", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self]_ in
            self?.presentCamer()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { [weak self]_ in
            self?.presentPhotoPicker()
        }))
        present(actionSheet, animated: true)
    }
    
    func presentCamer() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        print(info)
     guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.profilePicture.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.isNavigationBarHidden = false
        }
    
    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.isNavigationBarHidden = true
        }
}

struct MessageApp {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}


