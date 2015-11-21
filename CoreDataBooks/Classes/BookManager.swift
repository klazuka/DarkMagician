
import Foundation
import CoreData

class BookManager {
  
  let moc: NSManagedObjectContext
  
  var didInsert: (Void->Void)?
  var didDelete: (Void->Void)?
  var didUpdate: (Void->Void)?
  
  typealias BookCallback = Book -> Void
  
  var bookObservers = [NSManagedObjectID:[BookCallback]]()
  
  init(moc: NSManagedObjectContext) {
    self.moc = moc
    
    //NSNotificationCenter.defaultCenter().addObserver(self, selector: "mocDidChangeNotification:", name: NSManagedObjectContextObjectsDidChangeNotification, object: self.moc)
  }
  
  deinit {
    //NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func findAllBooks() -> [Book] {
    let fetchRequest = NSFetchRequest(entityName: "MOBook")
    let objects = try! moc.executeFetchRequest(fetchRequest)
    print("findAllBooks: found \(objects.count) books")
    return (objects as! [MOBook]).map { Book(managedObject: $0) }
  }
  
  func deleteBook(book: Book) throws {
    let objectToDelete = moc.objectWithID(book.managedObjectID)
    moc.deleteObject(objectToDelete)
    try moc.save()
  }
  
  func observeChangesToBook(book: Book, callback: BookCallback) {
    let key = book.managedObjectID
    if bookObservers[key] == nil {
      bookObservers[key] = [BookCallback]()
    }
    
    bookObservers[key]!.append(callback)
  }
  
  @objc func mocDidChangeNotification(note: NSNotification) {
    let userInfo = note.userInfo as! [String:AnyObject]
    
    if let inserts = userInfo[NSInsertedObjectsKey] {
      print("inserts: \(inserts)")
      didInsert?()
    }
    
    if let deletes = userInfo[NSDeletedObjectsKey] {
      print("deletes: \(deletes)")
      didDelete?()
    }
    
    if let updates = userInfo[NSUpdatedObjectsKey] {
      print("updates: \(updates)")
      didUpdate?()
      
      for mobook in userInfo[NSUpdatedObjectsKey] as! Set<MOBook> {
        if let callbacks = bookObservers[mobook.objectID] {
          for callback in callbacks {
            callback(Book(managedObject: mobook))
          }
        }
      }
      
    }
  }
  
}
