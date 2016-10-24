//
//  ChatViewController.swift
//  Zchat
//
//  Created by QIAN ZHU on 10/16/16.
//  Copyright © 2016 ZchatON. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class ChatViewController: JSQMessagesViewController {
    var messages = [JSQMessage]()
    var messageRef = FIRDatabase.database().reference().child("messages")
    var avatarDict = [String: JSQMessagesAvatarImage]()
    let photoCache = NSCache<AnyObject,AnyObject>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
  
        observeMessages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func barbtnLogOutAction(_ sender: AnyObject) {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let error {
            print(error)
        }
        print(FIRAuth.auth()?.currentUser)
        
        // Create a main storyboard instance
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        // From main storyboard instantiate a View controller
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LogInVC") as! LoginViewController
        // Get the app delegate, it was sharedApplication().delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        // Set LogIn controller as root view controller
        appDelegate.window?.rootViewController = loginVC
    }
    
    func observeUser(id: String){
        FIRDatabase.database().reference().child("users").child(id).observe(.value, with: {
            snapshot in
            if let dict = snapshot.value as? [String:AnyObject] {
                print("THIS IS FOR DICT: \(dict)") // only print for ones who has sent messages, cuz: function call (id: senderId)
                
                let avatarUrl = dict["profileUrl"] as! String
                self.setupAvatar(url: avatarUrl, messageId: id)
                
            }
        })
    }
    
    func setupAvatar(url: String, messageId : String){
        if url != ""{
            let fileUrl = URL(string: url)
            let data = NSData(contentsOf: fileUrl!)
            let image = UIImage(data: data! as Data)
            let userImg = JSQMessagesAvatarImageFactory().avatarImage(withPlaceholder: image!)
            avatarDict[messageId] = userImg
        }else{
           avatarDict[messageId] = JSQMessagesAvatarImageFactory().avatarImage(withPlaceholder: UIImage(named:"profileImage")!)
        }
        collectionView?.reloadData()
    }
    
    
    
    func observeMessages() {
        messageRef.observe(.childAdded, with: { snapshot in
            if let dict = snapshot.value as? [String: AnyObject] {
                let mediaType = dict["MediaType"] as! String
                let senderId = dict["senderId"] as! String
                let senderName = dict["senderName"] as! String
                
                self.observeUser(id: senderId)
                
                
                
                
//                if let text = dict["text"] as? String {
//                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
//                } else if let fireUrl = dict["fileUrl"] as? String{
//                    let fileUrl = dict["fileUrl"] as! String
//                    let data = NSData(contentsOf: URL(string: fileUrl)!)
//                    let picture = UIImage(data: data! as Data)
//                    let photo = JSQPhotoMediaItem(image: picture)
//                    self.messages.append(JSQMessage(senderId: senderId, displayName: self.senderDisplayName(), media: photo))
//                }
//                
//                self.collectionView?.reloadData()

                
     
                
                switch mediaType {
                    case "TEXT":
                        if let text = dict["text"] as? String {
                            self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text)) }
                    case "PHOTO":
                        if let fileUrl = dict["fileUrl"] as? String {
                            let url = NSURL(string: fileUrl)
                            let data = NSData(contentsOf: url as! URL)
                            let picture = UIImage(data: data! as Data)
                            let photo = JSQPhotoMediaItem(image: picture)
                            self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: photo))
                            if self.senderId() == senderId {
                                photo.appliesMediaViewMaskAsOutgoing = true
                            } else {
                                photo.appliesMediaViewMaskAsOutgoing = false
                            }
                            
                    }
                    
                    case "VIDEO":
                        if let fileUrl = dict["fileUrl"] as? String {
                        let video = NSURL(string: fileUrl)
                        let videoItem = JSQVideoMediaItem(fileURL: video as URL?, isReadyToPlay: true)
                            self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: videoItem))
                            if self.senderId() == senderId {
                                videoItem.appliesMediaViewMaskAsOutgoing = true
                            } else {
                                videoItem.appliesMediaViewMaskAsOutgoing = false
                            }
                    }
                default:
                    print("unknow data type")
                }
                    self.collectionView?.reloadData()
                
                
//                if let text = dict["text"] as? String {
//            self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
//                } else {
//                    let fileUrl = dict["fileUrl"] as! String
//                    let data = NSData(contentsOf: URL(string: fileUrl)!)
//                    let picture = UIImage(data: data! as Data)
//                    let photo = JSQPhotoMediaItem(image: picture)
//                    self.messages.append(JSQMessage(senderId: senderId, displayName: self.senderDisplayName(), media: photo))
//                }
//                
//           self.collectionView?.reloadData()
            }
        })
    }
    
    
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
//        messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
//        collectionView?.reloadData()
//        print(messages)
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text": text, "senderId": senderId, "senderName": senderDisplayName, "MediaType": "TEXT"]
        newMessage.setValue(messageData)
        self.finishSendingMessage()
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        print("AccessoryBTNpressed")
        let sheet = UIAlertController(title: "Media Stuff", message: "Please select a media", preferredStyle: UIAlertControllerStyle.actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alert: UIAlertAction) in
        }
        let photoStuff = UIAlertAction(title: "Photo Stuff", style: UIAlertActionStyle.default) { (alert: UIAlertAction) in
            self.getMediaFrom(type: kUTTypeImage)
        }
        let videoStuff = UIAlertAction(title: "Video Stuff", style: UIAlertActionStyle.default) { (alert: UIAlertAction) in
            self.getMediaFrom(type: kUTTypeMovie)
        }
        
        sheet.addAction(videoStuff)
        sheet.addAction(photoStuff)
        sheet.addAction(cancel)
        self.present(sheet, animated: true, completion: nil)
        
        //let imagePicker = UIImagePickerController()
        //imagePicker.delegate = self
        //self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func getMediaFrom(type: CFString){
        print(type)
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource? {
        let message = messages[indexPath.item]
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        if message.senderId == self.senderId(){
            return bubbleFactory.outgoingMessagesBubbleImage(with: UIColor.orange) }
        else {return bubbleFactory.incomingMessagesBubbleImage(with: UIColor(red: 0/255, green: 89/255, blue: 11/255, alpha: 1.0))}
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        
        let message = messages[indexPath.item]
        
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 36, height:36 )
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 36, height:36)
        
//        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault )
//        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault )
// two commented statements above can also be cut to viewDidLoad()
        
        return avatarDict[message.senderId]
//        return JSQMessagesAvatarImageFactory().avatarImage(withPlaceholder: UIImage(named:"profileImage")!)
       
    }

// this works:     return JSQMessagesAvatarImageFactory().avatarImage(withUserInitials: "AU", backgroundColor: UIColor.jsq_messageBubbleBlue(), textColor: UIColor.white, font: UIFont.systemFont(ofSize: 12))

// or:       return JSQMessagesAvatarImageFactory.avatarImage()(with: UIImage(named:"profileImage")!)
    

//   outDated: JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "profileImage"), diameter: 30)

    

    
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("THIS IS MESSAGE COUNT \(messages.count)")
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, didTapMessageBubbleAt indexPath: IndexPath) {
        print("didTapMessageBubbleAtIndexPath: \(indexPath.item)")
        let message = messages[indexPath.item]
        if message.isMediaMessage {
            if let mediaItem = message.media as? JSQVideoMediaItem {
                let player = AVPlayer(url: mediaItem.fileURL!)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true, completion: nil)
            }
        }
    }
    
    override func senderId() -> String {
        if let currentUser = FIRAuth.auth()?.currentUser {
        print("ShowMeUid: \(currentUser.uid)")
            return (currentUser.uid)
            }
        else {return ""}
    }
    
    override func senderDisplayName() -> String {
        let currentUser = FIRAuth.auth()?.currentUser
        if currentUser?.isAnonymous == true {
            return "Anonymous User"
        } else {
            return (currentUser?.displayName)!
        }
    }
    
    func sendMedia(picture: UIImage?, video: URL?){
        print(picture)
        print(FIRStorage.storage().reference())
        if let picture = picture{
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(NSDate.timeIntervalSinceReferenceDate)"
            print(filePath)
            let data = UIImageJPEGRepresentation(picture, 1)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpg"
            FIRStorage.storage().reference().child(filePath).put(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error?.localizedDescription)
                    return
                }
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId(), "senderName": self.senderDisplayName(),"MediaType":"PHOTO"]
                newMessage.setValue(messageData)}
        } else if let video = video{
            
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(NSDate.timeIntervalSinceReferenceDate)"
            print(filePath)
            let data = NSData(contentsOf: video)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "video/mp4"
            FIRStorage.storage().reference().child(filePath).put(data! as Data, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error?.localizedDescription)
                    return
                }
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId(), "senderName": self.senderDisplayName(),"MediaType":"VIDEO"]
                newMessage.setValue(messageData) }
            
        }
        
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("DID FINISH PICKING")
        print(info)
      if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
//        let photo = JSQPhotoMediaItem(image: picture)
//        messages.append(JSQMessage(senderId: senderId(), displayName: senderDisplayName(), media: photo))
        sendMedia(picture: picture, video: nil)
      }
      else if let video = info[UIImagePickerControllerMediaURL] as? URL{
//        let videoItem = JSQVideoMediaItem(fileURL: video , isReadyToPlay: true)
//        messages.append(JSQMessage(senderId: senderId(), displayName: senderDisplayName(), media: videoItem))
        sendMedia(picture: nil,video:video)
        }

        
        self.dismiss(animated: true, completion: nil)
        collectionView?.reloadData()
    }
}
