
import UIKit
import CoreData

func createAccount(emailAddress: String, moc: NSManagedObjectContext) -> NSManagedObject {
  let account = NSEntityDescription.insertNewObjectForEntityForName("Account", inManagedObjectContext: moc)
  account.setValuesForKeysWithDictionary([
    "accountID": NSUUID().UUIDString,
    "email": emailAddress
    ])
  return account
}

func createFolder(name: String, inAccount account: NSManagedObject, moc: NSManagedObjectContext) -> NSManagedObject {
  let folder = NSEntityDescription.insertNewObjectForEntityForName("Folder", inManagedObjectContext: moc)
  folder.setValuesForKeysWithDictionary([
    "folderID": NSUUID().UUIDString,
    "name": name,
    "account": account
    ])
  return folder
}

func createMessage(body: String, timestamp: NSDate, inFolder folder: NSManagedObject, moc: NSManagedObjectContext) -> NSManagedObject {
  let message = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: moc)
  message.setValuesForKeysWithDictionary([
    "messageID": NSUUID().UUIDString,
    "body": body,
    "timestamp": timestamp,
    "folder": folder
    ])
  return message
}

func lorem(numWords: Int) -> String {
  let ipsum = "Phasellus ullamcorper justo in lorem molestie, sed ultricies nunc vehicula. Nunc vel arcu massa. Donec nec aliquam augue. In accumsan convallis lacus quis fringilla. Nullam vitae tempus dolor, eget sollicitudin erat. Sed dui massa, rhoncus eget lectus sit amet, molestie hendrerit dui. Donec iaculis a neque in faucibus. Donec non diam metus. Praesent aliquet magna sed magna sagittis, nec mattis nulla volutpat. Etiam sed libero hendrerit ante blandit elementum et vel lectus. Vivamus at maximus metus. Duis aliquam lorem in commodo consectetur. Aenean efficitur risus eget placerat aliquet. Duis semper pretium lectus ut sagittis. Donec bibendum nulla odio, nec commodo."
  let wordsSlice = ipsum.componentsSeparatedByString(" ").prefix(numWords)
  return (Array(wordsSlice) as NSArray).componentsJoinedByString(" ")
}

func bootstrapDatabase(moc: NSManagedObjectContext) {
  print("re-populating the database")
  let account1 = createAccount("klazuka@gmail.com", moc: moc)
  let folder1 = createFolder("Inbox", inAccount: account1, moc: moc)
  let _ = createMessage(lorem(40), timestamp: NSDate().dateByAddingTimeInterval(-1000), inFolder: folder1, moc: moc)
  let _ = createMessage("work from home", timestamp: NSDate().dateByAddingTimeInterval(-2000), inFolder: folder1, moc: moc)
}

func numAccountsInDatabase(moc: NSManagedObjectContext) -> Int {
  let fetch = NSFetchRequest(entityName: "Account")
  return moc.countForFetchRequest(fetch, error: nil)
}

func dumpDatabase(moc: NSManagedObjectContext) {
  let fetch = NSFetchRequest(entityName: "Account")
  let accounts = try! moc.executeFetchRequest(fetch) as! [NSManagedObject]
  for account in accounts {
    print("account is \(account.valueForKey("email"))")
    
    for folder in account.valueForKey("folders") as! Set<NSManagedObject> {
      print("folder is \(folder.valueForKey("name"))")
      
      for message in folder.valueForKey("messages") as! Set<NSManagedObject> {
        print("message is \(message.valueForKey("body"))")
        
      }
    }
  }
}

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
      fatalError("bad app delegate")
    }
    
    let moc = appDelegate.managedObjectContext
    
    if numAccountsInDatabase(moc) == 0 {
      bootstrapDatabase(moc)
      appDelegate.saveContext()
    }
    
    dumpDatabase(moc)
  }
}

