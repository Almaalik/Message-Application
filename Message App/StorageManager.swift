//
//  StorageManager.swift
//  Message App
//
//  Created by macbook  on 24/02/21.
//  Copyright © 2021 Almaalik. All rights reserved.
//

import Foundation
import FirebaseStorage


class StorageManager {
    static let shared = StorageManager()
    private init() {}
    private let storage = Storage.storage().reference()
        
        public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
        //Upload picture to firebase and completion with url string to download
        public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
            storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
                
            guard let strongSelf = self else {
                return }
            guard error == nil else {
                ///failed
                print("failed to upload data to firebase for  picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
                strongSelf.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                    guard let url = url else {
                        print("failed to get download url")
                        completion(.failure(StorageErrors.failedToGetDowloadUrl))
                        return
                    }
                    
                    let urlString = url.absoluteString
                    print("download url returned: \(urlString)")
                    completion(.success(urlString))
                })
        })
    }
        ///Upload image taht will be sent in a conversation message
        public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
                storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
                guard error == nil else {
                    //failed
                    print("failed to upload data to firebase for  picture")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                    
                    self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                        guard let url = url else {
                            print("failed to get dowmload url")
                            completion(.failure(StorageErrors.failedToGetDowloadUrl))
                            return
                        }
                        
                        let urlString = url.absoluteString
                        print("download url returned: \(urlString)")
                        completion(.success(urlString))
                        
                    })
            })
        }
        
        ///Upload Video taht will be sent in a conversation message

        public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
            storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: {[weak self] metadata, error in
                guard error == nil else {
                    //failed
                    print("failed to upload Video file to firebase...")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                    
                    self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                        guard let url = url else {
                            print("failed to get download url")
                            completion(.failure(StorageErrors.failedToGetDowloadUrl))
                            return
                        }
                        
                        let urlString = url.absoluteString
                        print("download url returned: \(urlString)")
                        completion(.success(urlString))
                        
                    })
            })
        }
        
        public enum StorageErrors: Error {
            case failedToUpload
            case failedToGetDowloadUrl
        }
        
        public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
            let reference = storage.child(path)
            reference.downloadURL(completion: {url, error in
                guard let url = url, error == nil else {
                    completion((.failure(StorageErrors.failedToGetDowloadUrl)))
                    return
                }
                completion(.success(url))
            })
        }
    }

