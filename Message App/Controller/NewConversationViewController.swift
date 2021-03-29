
//  NewConversationViewController.swift
//  Message App
//
//  Created by macbook  on 26/02/21.
//  Copyright © 2021 Almaalik. All rights reserved.


import UIKit
//import JGProgressHUD

struct SearchResult {
        let name: String
        let email: String
    }

class NewConversationViewController: UIViewController {

   
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet weak var noUsersLabel: UILabel!
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
       
        navigationController?.popViewController(animated: true)
    }
  
    private var users = [[String: String]]()
    private var results = [SearchResult]()
    private var hasFetched = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true

        let nib = UINib.init(nibName: "SearchCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "SearchCell")
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        
            }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchCell
        cell.searchUserName?.text = model.name


        let path = "images/\(model.email)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: {  result in
            switch result {
            case.success(let url):

                DispatchQueue.main.async {
                    cell.searchUserImg?.sd_setImage(with: url, completed: nil)
                }
            case.failure(let error):
                    print("failed to get image url: \(error)")

                }
        })

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        //stsrt Conversation
        let targetuserData = results[indexPath.row]
        
        
        let currentConversations = ConversationViewController().conversations
                  
                   if let targetConversation = currentConversations.first(where: {
                       $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: targetuserData.email)
                       
                   }) {
                       let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                       vc.isNewConversation = false
                       vc.title = targetConversation.name
                       vc.navigationItem.largeTitleDisplayMode = .never
                      self.navigationController?.pushViewController(vc, animated: true)
                       
                   }else {
                      
                            let name =  targetuserData.name
                            let email = DatabaseManager.safeEmail(emailAddress: targetuserData.email)
                            print("NAME IS:\(name) AND EMAIL IS:\(email)")

                            DatabaseManager.shared.conversationExists(with: email, completion: { [weak self] result in
                    
                                switch result {
                                case.success(let conversationId):
                                  let vc = ChatViewController(with: email, id: conversationId)
                                    vc.isNewConversation = false
                                    vc.title = name
                                    vc.navigationItem.largeTitleDisplayMode = .never
                                    self?.navigationController?.pushViewController(vc, animated: true)
                                    
                                case.failure(_):
                                   let vc = ChatViewController(with: email, id: nil)
                                    vc.isNewConversation = true
                                    vc.title = name
                                    vc.navigationItem.largeTitleDisplayMode = .never
                                   self?.navigationController?.pushViewController(vc, animated: true)
                                }
                            })
                        }
                  
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}


extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        searchUsers(query: text)
    }

    func searchUsers(query: String) {
        // check if array has firebase result
        if hasFetched {
            //if it does, filter
            filterUsers(with: query)
        } else {
            //if not,fetch then filter
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result  {
                case .success(let usersColletion):
                    self?.hasFetched = true
                    self?.users = usersColletion
                    self?.filterUsers(with: query)
                case.failure(let error):
                    print("Failed to get users: \(error)")
                }
            })
        }
    }

    func filterUsers(with term: String) {
        //update the UI: either show results or show no results label
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,  hasFetched else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
     //   self.spinner.dismiss()

        let results: [SearchResult] = self.users.filter({
            
            guard let email = $0["email"],
                email != safeEmail else {
                    return false
            }
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"],
                let name = $0["name"] else {
                    return nil
            }
            
            return SearchResult(name: name, email: email)
        })
        self.results = results
        
       
        if results.isEmpty {
            noUsersLabel.isHidden = false
            tableView.isHidden = true
        } else {
          noUsersLabel.isHidden = true
           tableView.isHidden = false
           tableView.reloadData()
        }
    }
    
       
    

}





        
      

     
  
