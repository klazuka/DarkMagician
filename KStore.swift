
import CoreData

let kstoreType = "com.circle38.KStore"

class KStore: NSAtomicStore {
  
  class KNode: NSAtomicStoreCacheNode {
    var plistData: NSDictionary?
    
    override func valueForKey(key: String) -> AnyObject? {
      if plistData != nil {
        resolvePlistData()
      }
      return super.valueForKey(key)
    }
    
    func resolvePlistData() {
      guard let plistData = self.plistData else { return }
      
      propertyCache?.removeAllObjects()
      let entity = objectID.entity
      let resolvedProps = NSMutableDictionary()
      
      // resolve the attributes
      for (attribName, _) in entity.attributesByName {
        // TODO handle transformable
        resolvedProps[attribName] = plistData.valueForKey(attribName)
      }
      
      // resolve relationships
      for (relationshipName, relationshipMetadata) in entity.relationshipsByName {
        // each foreign key is an array "pair" (entityName: String, referenceID: Int)
        let foreignKeys = plistData.valueForKey(relationshipName) as! [NSArray]
        let atomicStore = objectID.persistentStore as! NSAtomicStore
        let storeEntities = atomicStore.persistentStoreCoordinator!.managedObjectModel.entitiesByName
        
        // convert the foreign key references to cache nodes
        let destNodes = foreignKeys.map { foreignKey -> NSAtomicStoreCacheNode in
          let entityName = foreignKey[0] as! String
          let refID = foreignKey[1] as! Int
          let entity = storeEntities[entityName]!
          let objectID = atomicStore.objectIDForEntity(entity, referenceObject: refID)
          guard let destNode = atomicStore.cacheNodeForObjectID(objectID) else {
            fatalError("referential integrity failure: couldn't find node for \(objectID)")
          }
          return destNode
        }
        
        if destNodes.count > 0 {
          resolvedProps[relationshipName] = relationshipMetadata.toMany
            ? Set(destNodes)
            : destNodes[0]
        }
      }
      
      self.propertyCache = resolvedProps
      self.plistData = nil
    }
  }
  
  override init(persistentStoreCoordinator coordinator: NSPersistentStoreCoordinator?, configurationName: String?, URL url: NSURL, options: [NSObject : AnyObject]?) {
    
    super.init(persistentStoreCoordinator: coordinator, configurationName: configurationName, URL: url, options: options)
    
    metadata = [
      NSStoreTypeKey: kstoreType,
      NSStoreUUIDKey: NSUUID().UUIDString,
      "objectCounter": 1 // monotonically increasing
    ]
  }
  
  private func convertManagedObjectToPlistRepresentation(managedObject: NSManagedObject) -> NSDictionary {
    return convertKVCObjectToPlistRepresentation(managedObject, entity: managedObject.entity)
  }
  
  private func convertCacheNodeToPlistRepresentation(node: NSAtomicStoreCacheNode) -> NSDictionary {
    let entity = node.objectID.entity
    return convertKVCObjectToPlistRepresentation(node, entity: entity)
  }
  
  private func convertKVCObjectToPlistRepresentation(kvcObject: NSObject, entity: NSEntityDescription) -> NSDictionary {
    let plistDict = NSMutableDictionary()
    
    // store the attributes in a plist-safe way
    for (attribName, _) in entity.attributesByName {
      // TODO handle transformable
      plistDict[attribName] = kvcObject.valueForKey(attribName)
    }
    
    // make the relationship values plist-safe by creating foreign-key references
    for (relationshipName, relationshipMetadata) in entity.relationshipsByName {
      // I have to use the Foundation collections here because we're doing the whole plist thing
      var foreignKeys = [NSArray]() // array of "pairs" (entityName: String, refID: Int)
      let destObjects = NSMutableArray()
      if relationshipMetadata.toMany {
        destObjects.addObjectsFromArray(kvcObject.valueForKey(relationshipName)!.allObjects)
      }
      else {
        destObjects.addObject(kvcObject.valueForKey(relationshipName)!)
      }
      
      let entityName = relationshipMetadata.destinationEntity!.name!
      for destObject in destObjects {
        let objectID = destObject.valueForKey("objectID") as! NSManagedObjectID
        let pair = NSMutableArray()
        pair.addObject(entityName)
        pair.addObject(referenceObjectForObjectID(objectID))
        foreignKeys.append(pair)
      }
      
      plistDict[relationshipName] = foreignKeys
    }
    
    return plistDict
  }
  
  
  // MARK:- required overrides for NSAtomicStore subclasses
  
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
    
    metadata = topLevel["metadata"] as! [String:AnyObject]
    
    let objects = topLevel["objects"] as! [NSMutableDictionary]
    var loadedNodes = Set<KNode>()
    for obj in objects {
      let entityName = obj["entityName"] as! String
      let entity = persistentStoreCoordinator!.managedObjectModel.entitiesByName[entityName]!
      let referenceID = obj["referenceID"]!
      let objectID = objectIDForEntity(entity, referenceObject: referenceID)
      let node = KNode(objectID: objectID)
      node.plistData = obj["plistData"] as? NSDictionary
      loadedNodes.insert(node)
    }
    
    addCacheNodes(loadedNodes)
    for node in loadedNodes {
      node.resolvePlistData()
    }
  }
  
  override func save() throws {
    
    // convert each cache node into its external, plist-safe representation
    let objectsToSave = cacheNodes().map { (node) -> NSMutableDictionary in
      let props = NSMutableDictionary()
      props["entityName"] = node.objectID.entity.name!
      props["referenceID"] = referenceObjectForObjectID(node.objectID)
      props["plistData"] = convertCacheNodeToPlistRepresentation(node)
      return props
    }

    let rootObject = ["objects": objectsToSave,
                      "metadata": metadata]
    let data = NSKeyedArchiver.archivedDataWithRootObject(rootObject)
    data.writeToURL(URL!, atomically: true)
  }
  
  override func newReferenceObjectForManagedObject(managedObject: NSManagedObject) -> AnyObject {
    // at this point the managed object has temporary objectIDs
    let counter = metadata["objectCounter"] as! Int
    metadata["objectCounter"] = counter + 1
    return counter
  }

  override func newCacheNodeForManagedObject(managedObject: NSManagedObject) -> NSAtomicStoreCacheNode {
    // at this point the managed object (and its relationships) all have permanent objectIDs
    let objectID = managedObject.objectID
    let node = KNode(objectID: objectID)
    node.plistData = convertManagedObjectToPlistRepresentation(managedObject)
    return node
  }
  
  override func updateCacheNode(node: NSAtomicStoreCacheNode, fromManagedObject managedObject: NSManagedObject) {
    let node = node as! KNode
    node.plistData = convertManagedObjectToPlistRepresentation(managedObject)
  }
  
  
  // MARK:- required overrides for NSPersistentStore subclasses
  
  override var type: String { return kstoreType }

  override class func metadataForPersistentStoreWithURL(url: NSURL) throws -> [String : AnyObject] {
    fatalError("not implemented")
  }

  /* Set the metadata of the store at url to metadata. Must be overriden by subclasses. */
  override class func setMetadata(metadata: [String : AnyObject]?, forPersistentStoreWithURL url: NSURL) throws {
    fatalError("not implemented")
  }
  
}
