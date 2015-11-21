
import Foundation

struct Book: ImmutableWrapperType {
  let title: String
  let author: String
  let copyright: NSDate?

  // MARK:- ImmutableWrapperType conformance
  
  let managedObjectID: NSManagedObjectID
  
  init(managedObject: NSManagedObject) {
    guard let managedBook = managedObject as? MOBook else { fatalError() }
    self.title = managedBook.title
    self.author = managedBook.author
    self.copyright = managedBook.copyright
    
    self.managedObjectID = managedBook.objectID
  }
}
