//
//  ProfileViewController.swift
//  Message App
//
//  Created by macbook  on 21/03/21.
//  Copyright © 2021 Almaalik. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    @IBOutlet var image: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var mailLabel: UILabel!
    @IBAction func logout(_ sender: UIButton) {
        
  
        let alertController = UIAlertController(title: "Logout", message: "Logout the account", preferredStyle: .alert)
               
               let OKAction = UIAlertAction(title: "Logout", style: .default) { (action:UIAlertAction!) in
                   
                   // Code in this block will trigger when OK button tapped.
                do {
                       try FirebaseAuth.Auth.auth().signOut()
                    print("Sucessfully Logout the User")
                    self.performSegue(withIdentifier: "Logout", sender: self)
                        }
                   catch {
                   }
                   
               }
               alertController.addAction(OKAction)
               
               // Create Cancel button
               let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction!) in
                   print("Cancel button tapped");
               }
               alertController.addAction(cancelAction)
               
               // Present Dialog message
               self.present(alertController, animated: true, completion:nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        image?.layer.cornerRadius = 25


       let name = UserDefaults.standard.value(forKey: "name") as? String
             let userEmail = UserDefaults.standard.value(forKey: "email") as? String
        


            guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                return

            }
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            let filename = safeEmail + "_profile_picture.png"
            
            let path = "images/"+filename
            
            StorageManager.shared.downloadURL(for: path, completion: { result in
                switch result {
                case .success(let url):
                    
                    DispatchQueue.main.async {
                            self.image.sd_setImage(with: url, completed: nil)
                        self.nameLabel.text = name
                        self.mailLabel.text = userEmail

                    }
                    
                case .failure(let error):
                    print("failed to get download url: \(error)")
                }
            })
        }
    
}
    

   


