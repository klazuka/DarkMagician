
import Foundation
import CoreData

protocol ImmutableWrapperType {
  init(managedObject: NSManagedObject)
  
  // TODO this property might be a bad idea (maybe use external bookkeeping instead?)
  var managedObjectID: NSManagedObjectID { get }
}

enum ResultsChangeType: UInt {
  case Insert
  case Delete
  case Move
  case Update
}

protocol ResultSetControllerDelegate {
  func controllerWillChangeContent()

  // TODO I'm currently hiding the object that changed since I don't need it right now
  // and it's tricky to do without fighting the type system
  func controllerDidChangeObjectAtIndexPath(indexPath: NSIndexPath?, forChangeType type: ResultsChangeType, newIndexPath: NSIndexPath?)
  
  func controllerDidChangeSectionAtIndex(sectionIndex: Int, forChangeType type: ResultsChangeType)
  
  func controllerDidChangeContent()
}

class ResultSetController<ResultType: ImmutableWrapperType> {
  
  let entityName: String
  let predicate: NSPredicate?
  let sortDescriptors: [NSSortDescriptor]?
  let sectionNameKeyPath: String?
  let moc: NSManagedObjectContext
  
  var sections = [SectionInfo<ResultType>]()
  
  var delegate: ResultSetControllerDelegate?
  
  init(entityName: String, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, sectionNameKeyPath: String?, moc: NSManagedObjectContext) {
    
    self.entityName = entityName
    self.predicate = predicate
    self.sortDescriptors = sortDescriptors
    self.sectionNameKeyPath = sectionNameKeyPath
    self.moc = moc
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "mocDidChangeNotification:", name: NSManagedObjectContextObjectsDidChangeNotification, object: self.moc)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func performFetch() throws {
    let fetchRequest = NSFetchRequest(entityName: entityName)
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = sortDescriptors
    let objects = try! moc.executeFetchRequest(fetchRequest)
    print("performFetch: found \(objects.count) objects")
    
    
    if let sectionNameKeyPath = sectionNameKeyPath {
      // partition the managed objects into sections
      var managedObjectSections = [SectionInfo<NSManagedObject>]()
      for object in objects as! [NSManagedObject] {
        
        let objectSectionName = object.valueForKey(sectionNameKeyPath) as! String
        
        if let idx = managedObjectSections.indexOf({ $0.name == objectSectionName }) {
          // update the section
          managedObjectSections[idx].objects.append(object)
        } else {
          // create a new section
          let newSection = SectionInfo<NSManagedObject>(name: objectSectionName, objects: [object])
          managedObjectSections.append(newSection)
        }
      }
      
      // create sections of the immutable wrapper model objects
      for managedObjectSection in managedObjectSections {
        var newSection = SectionInfo<ResultType>()
        newSection.name = managedObjectSection.name
        newSection.objects = managedObjectSection.objects.map { ResultType(managedObject: $0) }
        sections.append(newSection)
      }
    }
    else {
      // one section only
      var defaultSection = SectionInfo<ResultType>()
      defaultSection.name = "Untitled"
      defaultSection.objects = (objects as! [NSManagedObject]).map { ResultType(managedObject: $0) }
      sections.append(defaultSection)
    }
    
  }
  
  // TODO maybe it'd be better to make the `sections` conform to `SequenceType` so that
  // we get functions like `indexOf` for free.
  private func indexPathOfResultWithManagedObjectID(objectID: NSManagedObjectID) -> NSIndexPath {
    for (sectionIndex, section) in sections.enumerate() {
      if let rowIndex = section.objects.indexOf({ $0.managedObjectID == objectID }) {
        return NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
      }
    }
    fatalError("could not find a result for \(objectID)")
  }
  
  @objc func mocDidChangeNotification(note: NSNotification) {
    let userInfo = note.userInfo as! [String:AnyObject]
    
    delegate?.controllerWillChangeContent()
    
    if let inserts = userInfo[NSInsertedObjectsKey] {
      print("inserts: \(inserts)")
      for insertedManagedObject in inserts as! Set<NSManagedObject> {
      
        // Insert the wrapped value
        // (1) determine the section (creating it as necessary)
        // (2) determine the row within the section

        let newResult = ResultType(managedObject: insertedManagedObject)
        let newSectionIndex: Int
        let newRowIndex: Int

        
        // (1) determine the section
        if let sectionNameKeyPath = sectionNameKeyPath {
          // has sections
          let existingSectionNames = sections.map { $0.name }
          let insertedSectionName = insertedManagedObject.valueForKey(sectionNameKeyPath) as! String
          if let existingSectionIndex = existingSectionNames.indexOf(insertedSectionName) {
            // the section already exists
            newSectionIndex = existingSectionIndex
          }
          else {
            // need to create a new section
            let sortedSectionNames = (existingSectionNames + [insertedSectionName]).sort()
            newSectionIndex = sortedSectionNames.indexOf(insertedSectionName)!
            let newSectionInfo = SectionInfo<ResultType>(name: insertedSectionName, objects: [])
            sections.insert(newSectionInfo, atIndex: newSectionIndex)
            // and tell the delegate
            delegate?.controllerDidChangeSectionAtIndex(newSectionIndex, forChangeType: .Insert)
          }
        }
        else {
          // we're running without a keyPath to section on, so use the default section (create if necessary)
          newSectionIndex = 0
          if sections.isEmpty {
            var defaultSection = SectionInfo<ResultType>()
            defaultSection.name = "Untitled"
            defaultSection.objects = []
            sections.append(defaultSection)
            // and tell the delegate
            delegate?.controllerDidChangeSectionAtIndex(newSectionIndex, forChangeType: .Insert)
          }
        }

        // (2) determine the row within the section
        var foundRowToInsertIndex: Int?
        for (testIndex, testResult) in sections[newSectionIndex].objects.enumerate() {
          // TODO EVIL EVIL EVIL HACK until I can figure out a way to use the type system to workaround valueForKey
          // this completely couples this class to the Book result type, which is crazy wrong
          // AND it makes an evil assumption that we are sorting by title
          let testBook = unsafeBitCast(testResult, Book.self)
          let newBook = unsafeBitCast(newResult, Book.self)
          if testBook.title > newBook.title {
            foundRowToInsertIndex = testIndex
          }
        }
        
        if foundRowToInsertIndex == nil {
          foundRowToInsertIndex = sections[newSectionIndex].objects.count
        }
        newRowIndex = foundRowToInsertIndex!
        
        // do the row insert
        let newIndexPath = NSIndexPath(forRow: newRowIndex, inSection: newSectionIndex)
        sections[newIndexPath.section].objects.insert(newResult, atIndex: newIndexPath.row)
        delegate?.controllerDidChangeObjectAtIndexPath(nil, forChangeType: .Insert, newIndexPath: newIndexPath)
      }
    }
    
    if let deletes = userInfo[NSDeletedObjectsKey] {
      print("deletes: \(deletes)")
      for deletedManagedObject in deletes as! Set<NSManagedObject> {
        let deleteIndexPath = indexPathOfResultWithManagedObjectID(deletedManagedObject.objectID)
        sections[deleteIndexPath.section].objects.removeAtIndex(deleteIndexPath.row)
        delegate?.controllerDidChangeObjectAtIndexPath(deleteIndexPath, forChangeType: .Delete, newIndexPath: nil)
        
        // did this delete orphan a section? if so, remove the section and tell the delegate
        if sections[deleteIndexPath.section].objects.isEmpty {
          sections.removeAtIndex(deleteIndexPath.section)
          delegate?.controllerDidChangeSectionAtIndex(deleteIndexPath.section, forChangeType: .Delete)
        }
      }
    }
    
    if let updates = userInfo[NSUpdatedObjectsKey] {
      print("updates: \(updates)")
      for updatedManagedObject in updates as! Set<NSManagedObject> {
        let updateIndexPath = indexPathOfResultWithManagedObjectID(updatedManagedObject.objectID)
        let updatedResult = ResultType(managedObject: updatedManagedObject)
        sections[updateIndexPath.section].objects[updateIndexPath.row] = updatedResult
        delegate?.controllerDidChangeObjectAtIndexPath(updateIndexPath, forChangeType: .Update, newIndexPath: nil)
      }
    }
    
    delegate?.controllerDidChangeContent()
  }

  
}