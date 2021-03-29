//
//  ChatViewController.swift
//  Message App
//
//  Created by macbook  on 26/02/21.
//  Copyright © 2021 Almaalik. All rights reserved.

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}
struct Sender: SenderType {
   public var photoURL: String
   public var  senderId: String
   public var displayName: String
}
struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
           return "photo"
        case .video(_):
           return "video"
        case .location(_):
          return  "location"
        case .emoji(_):
           return "emoji"
        case .audio(_):
           return "audio"
        case .contact(_):
          return  "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        
        }
    }
}

class ChatViewController: MessagesViewController {
    
    public var isNewConversation = false
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    public var otherUserEmail: String = ""
    private var conversationId: String?
    private var message = [Message]()
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email")  as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    }

    init(with email: String, id: String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()

    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//                messageInputBar.inputTextView.becomeFirstResponder()
//        if let conversationId = self.conversationId {
//             self.listenForMessages(id: conversationId, shouldScrollToBottom: true)
//        }
//        
//    }
    override func viewWillAppear(_ animated: Bool) {
         messageInputBar.inputTextView.becomeFirstResponder()
               if let conversationId = self.conversationId {
                    self.listenForMessages(id: conversationId, shouldScrollToBottom: true)
               }
    }
   
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
       view.backgroundColor = .red
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
        
    }
  
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 40, height: 40), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside({ [weak self] _ in
            self?.presentInputActionSheet()
        })
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)

    }
    
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: {  _ in
            self.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {  _ in
            self.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }

    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a photo from", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {  _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Librery", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
        
    }
    
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attach a Video from", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {  _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Librery", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case.success(let message):
             
                self?.message = message
                DispatchQueue.main.async {
                        self?.messagesCollectionView.reloadDataAndKeepOffset()
                        if shouldScrollToBottom {
                            self?.messagesCollectionView.scrollToLastItem()                            
                       }
                }
                print("success in getting Messages:")
                             guard !message.isEmpty else {
                                 print("messages are empty")
                                 return
                             }
            case.failure(let error):
                print("failed to get Messages: \(error)")
                self?.messagesCollectionView.reloadData()

                
            }
        })
       
       }
}



extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
        let conversationId = conversationId,
            let name = self.title,
            let selfSender = selfSender else {
            return
        }
        if let image = info[.editedImage] as? UIImage,
            let imageData = image.pngData() {
            
            let fileName = "photo_message" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            //upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case.success(let urlString):
                    //Ready to send Message
                    print("upload message Photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else {
                            return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .photo(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: strongSelf.otherUserEmail, newMessage: message, completion: { success in
                        
                        if success {
                            print("send photo message")
                        } else  {
                            print("failed to send photo image")
                        }
                    })
                    
                case.failure(let error):
                    print("message photo upload error: \(error)")
                }
            })
            
        } else  if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "photo_message" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            //Upload Video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case.success(let urlString):
                    //Ready to send Message
                    print("upload message Video: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else {
                            return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .video(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: strongSelf.otherUserEmail, newMessage: message, completion: { success in
                        
                        if success {
                            print("send photo message")
                        } else  {
                            print("failed to send photo image")
                        }
                    })
                case.failure(let error):
                    print("message photo upload error: \(error)")
                }
            })
        }
    }
}



extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = self.selfSender,
            let messageId = createMessageId() else {
            return
        }
        
        print("Sending: \(text)")
        let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        //Send message
        if isNewConversation {
            // create Convo in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "user", firstMessage: message, completion: { [weak self] success in
                if success {
                    print("Message send")
                    self?.isNewConversation = false
                    let newConversationId = "conversation _\(message.messageId)"
                    self?.conversationId = newConversationId
                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                } else {
                        print("Message faild to send")
                }
            })
        } else {
            //append to existing conversation
            guard let conversationId = conversationId,
                
                let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: otherUserEmail, newMessage: message, completion: { [weak self] success in
                if success {
                    self?.messageInputBar.inputTextView.text = nil
                    print("message sent \(conversationId)")
                } else {
                    print("failed to send")
                }
            })
        }
    }

    private func createMessageId() -> String? {
        //date, otherUserEmail and sender email random int
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("Created message ID:\(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource,MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender =  selfSender {
            return sender
        }
        fatalError("Self sender is nil email should be catched")
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return message[indexPath.section]
        
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return message.count
    }

    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexpath: IndexPath, in messageCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case.photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }

    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            //our message that we've sent
            return.link
        }
        return .secondarySystemBackground
    }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            //show our image
            if let currentUserImageURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImageURL, completed: nil)

            } else {
                //images/as_profile_picture.png

                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                //fetch url

                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result {
                    case.success(let url):
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)

                        }
                    case.failure(let error):
                        print("little image\(error)")
                    }
                })
            }

        } else {
            //other use image

            if let otherUserPhotoURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserPhotoURL, completed: nil)

            } else {

                //fetch url
                let email = self.otherUserEmail
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                //fetch url

                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result {
                    case.success(let url):
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)

                        }
                    case.failure(let error):
                        print("Little Image \(error)")
                    }
                })
            }
        }
    }
}


extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let mmessage = message[indexPath.section]
        switch mmessage.kind {
        case.photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViwerViewController(with: imageUrl)
                    navigationController?.pushViewController(vc, animated: true)
                    case.video(let media):
                    guard let videoUrl = media.url else {
                        return
                    }
                    let vc = AVPlayerViewController()
                    vc.player = AVPlayer(url: videoUrl)
                    present(vc, animated: true)
                default:
                    break
                }
            }
}


