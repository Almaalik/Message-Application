//
//  ConversationViewController.swift
//  Message App
//
//  Created by macbook  on 25/02/21.
//  Copyright © 2021 Almaalik. All rights reserved.
//

import UIKit
//import FirebaseDatabase
import FirebaseAuth

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
     }
struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}

class ConversationViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var noConvoLabel: UILabel!
    private var loginObserver: NSObjectProtocol?
    public var conversations = [Conversation]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if FirebaseAuth.Auth.auth().currentUser == nil {
                   performSegue(withIdentifier: "CovoToWelcome", sender: self)
               }
        }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()

        startListeningForConversation()
        
        let nib = UINib.init(nibName: "ConversationCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "ConversationCell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
       
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name("didLogInNotification"), object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startListeningForConversation()
        })
    }

    
    private func startListeningForConversation() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }

        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        print("starting conversations...")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail, completion:  { [weak self] result in
            
            switch result {
            case.success(let conversations):
                print("sucessfully got conversation models....")
                guard  !conversations.isEmpty else {
                    self?.tableView.isHidden = false
                    self?.noConvoLabel.isHidden = false
                    return
                }
                self?.noConvoLabel.isHidden = true
                self?.tableView.isHidden = false
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case.failure(let error):
                self?.tableView.isHidden = true
                self?.noConvoLabel.isHidden = false
                print("failed to get conveos: \(error)")
            }
        })
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    @objc private func didTapComposeButton() {
        self.performSegue(withIdentifier: "ConvoToNewConvo", sender: self)
    }

}


extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! ConversationCell
        cell.latestMessage?.text = model.latestMessage.text
        cell.otherUserName?.text = model.name
        
            let path = "images/\(model.otherUserEmail)_profile_picture.png"
        
            StorageManager.shared.downloadURL(for: path, completion: { result in
                switch result {
                case.success(let url):

                    DispatchQueue.main.async {
                        cell.otherUserPic?.sd_setImage(with: url, completed: nil)
                    }
                case.failure(let error):
                        print("failed to get Image url: \(error)")
                    print("path for the image is \(path)")
                    }
            })
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
            let model = conversations[indexPath.row]
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
        
    }
   
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            //being delete
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
             self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: { success in
                if !success {
                    print("Failed to delete")
                }
            })
            tableView.endUpdates()
        }
    }
}


