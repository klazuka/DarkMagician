
import CoreData

let kstoreType = "com.circle38.KStore"

// TODO cleanup metadata
var dummyMetadata: [String:AnyObject] = [
  NSStoreTypeKey: kstoreType,
  NSStoreUUIDKey: "1234-5678-abcd-efgh",
  "objectCounter": 1 // monotonically increasing
]

class KStore: NSAtomicStore {
  
    // TODO override?
//  init(persistentStoreCoordinator coordinator: NSPersistentStoreCoordinator?,
//    configurationName configurationName: String?,
//    URL url: NSURL,
//    options options: [NSObject : AnyObject]?)
  
  
  // MARK- required overrides for NSAtomicStore subclasses
  
  override func load() throws {
    
    if !NSFileManager.defaultManager().fileExistsAtPath(URL!.path!) {
      print("no data on disk")
      return
    }
    
    guard let data = NSData(contentsOfURL: URL!),
          let topLevel = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String:AnyObject] else {
      fatalError("failed to decode data on disk")
    }
    
    print(topLevel)
    
    dummyMetadata = topLevel["metadata"] as! [String:AnyObject]
    
    let objects = topLevel["objects"] as! [NSMutableDictionary]
    for obj in objects {
      let entityName = obj["__entityName"] as! String
      let entity = persistentStoreCoordinator!.managedObjectModel.entitiesByName[entityName]!
      let referenceID = obj["__referenceID"]!
      let objectID = objectIDForEntity(entity, referenceObject: referenceID)
      let node = NSAtomicStoreCacheNode(objectID: objectID)
      node.propertyCache = obj
      addCacheNodes(Set([node]))
    }
  }
  
  override func save() throws {
    
    let objectsToSave = cacheNodes().map { (node) -> NSMutableDictionary in
      let props = node.propertyCache!
      props["__entityName"] = node.objectID.entity.name!
      props["__referenceID"] = referenceObjectForObjectID(node.objectID)
      for (k,v) in props {
        let k2 = k as! String
        props[k2] = v
        // TODO handle relationships
      }
      return props
    }

    let rootObject = ["objects": objectsToSave,
                      "metadata": dummyMetadata]
    let data = NSKeyedArchiver.archivedDataWithRootObject(rootObject)
    data.writeToURL(URL!, atomically: true)
  }
  
  override func newReferenceObjectForManagedObject(managedObject: NSManagedObject) -> AnyObject {
    let counter = metadata["objectCounter"] as! Int
    metadata["objectCounter"] = counter + 1
    return counter
  }

  override func newCacheNodeForManagedObject(managedObject: NSManagedObject) -> NSAtomicStoreCacheNode {
    // at this point the managed object (and its relationships) all have permanent objectIDs
    let objectID = managedObject.objectID
    let node = NSAtomicStoreCacheNode(objectID: objectID)
    
    for (keyPath, newValue) in managedObject.changedValues() {
      node.setValue(newValue, forKey: keyPath)
    }
    
    // TODO I don't think I need to do add the cache node here since I'm returning it to the framework/caller
    addCacheNodes(Set([node]))
    
    return node
  }
  
  override func updateCacheNode(node: NSAtomicStoreCacheNode, fromManagedObject managedObject: NSManagedObject) {
    for (keyPath, newValue) in managedObject.changedValues() {
      node.setValue(newValue, forKey: keyPath)
    }
  }
  
  
  // MARK:- required overrides for NSPersistentStore subclasses
  
  override var type: String { return kstoreType }
  
  override var metadata: [String : AnyObject]! {
    get { return dummyMetadata }
    set { dummyMetadata = newValue }
  }

  override class func metadataForPersistentStoreWithURL(url: NSURL) throws -> [String : AnyObject] {
    print("get metadata for store at \(url)")
    return dummyMetadata
  }

  /* Set the metadata of the store at url to metadata. Must be overriden by subclasses. */
  override class func setMetadata(metadata: [String : AnyObject]?, forPersistentStoreWithURL url: NSURL) throws {
    print("setMetadata \(metadata) for store at \(url)")
    if let newMetadata = metadata {
        dummyMetadata = newMetadata
    } else {
        // TODO what to do if it's null?
    }
  }
  
}
