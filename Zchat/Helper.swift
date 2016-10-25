import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseDatabase
class Helper {
    static let helper = Helper()
    func LoginAnonymously(){
        print("Anonymously Loggin")
        // Anonymously log users in
        // Switch view by setting navigation controller as root view controller
        FIRAuth.auth()?.signInAnonymously(completion: { (anonymousUser: FIRUser?, error: Error?) in
            if error == nil {
                print("User ID: \(anonymousUser!.uid)")
                self.switchToNavigationViewControler()
                let newUser = FIRDatabase.database().reference().child("users").child(anonymousUser!.uid)
                newUser.setValue(["displayname":"AnonymousUser", "id":"\(anonymousUser!.uid)", "profileUrl":""])
            }else {
                print(error?.localizedDescription)
                return
            }
        })
        
            }

    
    func logInWithGoogle(authentication: GIDAuthentication){
        print("Google Loggin")
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        FIRAuth.auth()?.signIn(with: credential, completion: { (user: FIRUser?, error: Error?) in
            if error != nil {
                print(error?.localizedDescription)
                return
            } else {
                print(user?.email)
                print(user?.displayName)
                print(user?.photoURL)
                
                let newUser = FIRDatabase.database().reference().child("users").child(user!.uid)
                newUser.setValue(["displayname":"\(user!.displayName!)", "id":"\(user!.uid)", "profileUrl":"\(user!.photoURL!)"])
                
                
                
                self.switchToNavigationViewControler()
            }
        })
    }
    
     func switchToNavigationViewControler(){
        // Create a main storyboard instance
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        // From main storyboard instantiate a navigation controller
        let naviVC = storyboard.instantiateViewController(withIdentifier: "NavigationVC") as! UINavigationController
        // Get the app delegate, old code was sharedApplication().delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        // Set navigation controller as root view controller
        appDelegate.window?.rootViewController = naviVC
    }
    
}

