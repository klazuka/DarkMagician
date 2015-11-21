
import Foundation
import CoreData

class BookListVC: UITableViewController {
  
  var moc: NSManagedObjectContext!
  
  var resultsController: ResultSetController<Book>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Swift"
    
//    let predicate = NSPredicate(format: "author == %@", "Douglas Coupland")
    let predicate: NSPredicate? = nil
    
    let sectionNameKeyPath = "author"
//    let sectionNameKeyPath: String? = nil
    
    let authorDescriptor = NSSortDescriptor(key: "author", ascending: true)
    let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
    let sortDescriptors = [authorDescriptor, titleDescriptor]
    resultsController = ResultSetController<Book>(entityName: "MOBook", predicate: predicate, sortDescriptors: sortDescriptors, sectionNameKeyPath: sectionNameKeyPath, moc: moc)
    
    resultsController.delegate = self
    
    try! resultsController.performFetch()
  }
  
  func bookAtIndexPath(indexPath: NSIndexPath) -> Book {
    return resultsController.sections[indexPath.section].objects[indexPath.row]
  }
  
  func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
    let book = bookAtIndexPath(indexPath)
    cell.textLabel?.text = book.title
  }
}

// MARK:- UITableViewDataSource

extension BookListVC {

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return resultsController.sections.count
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return resultsController.sections[section].objects.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
    configureCell(cell, atIndexPath: indexPath)
    return cell
  }
  
  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return resultsController.sections[section].name
  }
}

// MARK:- UITableViewDelegate

extension BookListVC {

  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    
    if editingStyle == .Delete {
      // TODO
//      let bookToDelete = bookAtIndexPath(indexPath)
//      try! bookManager.deleteBook(bookToDelete)
    }
  }
}

extension BookListVC: ResultSetControllerDelegate {
  func controllerWillChangeContent() {
    print("will change content")
    tableView.beginUpdates()
  }
  
  func controllerDidChangeContent() {
    print("did change content")
    tableView.endUpdates()
  }
  
  func controllerDidChangeObjectAtIndexPath(indexPath: NSIndexPath?, forChangeType type: ResultsChangeType, newIndexPath: NSIndexPath?) {
    
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
    
    case .Delete:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
    
    case .Update:
      self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
    
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
      
    }
    
  }
  
  func controllerDidChangeSectionAtIndex(sectionIndex: Int, forChangeType type: ResultsChangeType) {
    switch type {
    case .Insert:
      tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
    
    case .Delete:
      tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
    
    case .Move:
      print("ignored section move")
    
    case .Update:
      print("ignored section update")
      
    }
  }
}






// MARK:- NSFetchedResultsControllerDelegate


//    try! fetchedResultsController.performFetch()


//  lazy var fetchedResultsController: NSFetchedResultsController = {
//    let fetchRequest = NSFetchRequest(entityName: "MOBook")
//    let authorDescriptor = NSSortDescriptor(key: "author", ascending: true)
//    let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
//    fetchRequest.sortDescriptors = [authorDescriptor, titleDescriptor]
//
//    let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.moc, sectionNameKeyPath: "author", cacheName:"Root")
//    frc.delegate = self
//    return frc
//  }()


//extension BookListVC: NSFetchedResultsControllerDelegate {
//
//  func controllerWillChangeContent(controller: NSFetchedResultsController) {
//    tableView.beginUpdates()
//  }
//  
//  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//    
//    switch type {
//    case .Insert:
//      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
//      
//    case .Delete:
//      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
//    
//    case .Update:
//      self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
//      
//    case .Move:
//      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
//      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
//      
//    }
//    
//  }
//  
//  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
//    switch type {
//    case .Insert:
//      tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
//      
//    case .Delete:
//      tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
//      
//    case .Move:
//      print("ignored section move")
//      
//    case .Update:
//      print("ignored section update")
//      
//    }
//  }
//  
//  func controllerDidChangeContent(controller: NSFetchedResultsController) {
//    tableView.endUpdates()
//  }
//
//}




































