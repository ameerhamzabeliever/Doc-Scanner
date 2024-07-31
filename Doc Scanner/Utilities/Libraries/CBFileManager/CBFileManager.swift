//
//  CBFileManager.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 07/09/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import Foundation

import UIKit
import CoreData

class CBFileManager {
    
    static let sharedInstance = CBFileManager()
    
    /* MARK:- Create */
    
    ///File/Folder
    func createData(
        withEntries entries : [String: Any] ,
        forEntity entity    : String        ,
        completion          : @escaping (_ finished: Bool) -> ()
    ){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return
        }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        //Now let’s create an entity and new user records.
        let dataEntity = NSEntityDescription.entity(
                            forEntityName : entity,
                            in            : managedContext
                         )!
        
        let Data = NSManagedObject(entity: dataEntity, insertInto: managedContext)
        
        for (key, value) in entries {
            Data.setValue(value, forKey: key)
        }
        
        //Now we have set all the values. The next step is to save them inside the Core Data
        do {
            try managedContext.save()
            completion(true)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
            completion(false)
        }
    }
    
    /* MARK:- UPDATE */
    
    ///File/Folder
    func upateData(
        withId id           : Int32 ,
        forEntity entity    : String,
        withEntries entries : [String: Any],
        completion          : @escaping (_ finished: Bool) -> ()
    ){
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            completion(false)
            return
        }

        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext

        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
                               entityName: entity
                           )
        
        let predicate = NSPredicate(format: "id = '\(id)'")
        
        fetchRequest.predicate = predicate
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            if let objectToUpdate = result.first as? NSManagedObject {
                
                for (key, value) in entries {
                    objectToUpdate.setValue(value, forKey: key)
                }
                
                try managedContext.save()
            }
            completion(true)
        } catch {
            print("Failed to update")
            completion(false)
        }
    }
    
    /* MARK:- RETRIEVE */
    
    ///File/Folder
    func retrieveFilesFolders(
        shouldAddCondition flag : Bool?               = nil,
        withKeyAndValue keyVal  : [String: String]?   = nil,
        ofType type: NSCompoundPredicate.LogicalType? = nil
    ) -> [DocumentsModel] {

        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return [DocumentsModel]()
        }

        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext

        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
                               entityName: DOCUMENTS
                           )
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor.init(key: "id", ascending: true)
        ]
        
        if flag ?? false {
            if let keyVal = keyVal {
                
                var predicates: [NSPredicate] = []
                
                for (key, value) in keyVal {
                    let predicate = NSPredicate(format: "\(key) = '\(value)'")
                    predicates.append(predicate)
                }
                
                var compundPredicate = NSCompoundPredicate()
                
                if let type = type {
                    compundPredicate = NSCompoundPredicate(
                        type          : type,
                        subpredicates : predicates
                    )
                } else {
                    compundPredicate = NSCompoundPredicate(
                        andPredicateWithSubpredicates: predicates
                    )
                }
                
                
                fetchRequest.predicate = compundPredicate
                
            }
        }

        do {
            var returnData: [DocumentsModel] = []
            
            let result = try managedContext.fetch(fetchRequest)
            
            for data in result as! [NSManagedObject] {
                
                let id        = data.value(forKey: "id")         as! Int32
                let name      = data.value(forKey: "name")       as! String
                let type      = data.value(forKey: "type")       as! String
                let folderId  = data.value(forKey: "folder_id")  as! Int32
                let lockType  = data.value(forKey: "lock_type")  as! Int16
                let password  = data.value(forKey: "password")   as! String
                let createdAt = data.value(forKey: "created_at") as! Date
                
                if type == DataType.folder.rawValue {
                    let folderData = CBFileManager.sharedInstance.retrieveFilesFolders(
                        shouldAddCondition: true                ,
                        withKeyAndValue   : ["folder_id" : "\(id)"] ,
                        ofType            : nil
                    )
                    
                    let datum: DocumentsModel = DocumentsModel(
                        id        : id        ,
                        name      : name      ,
                        type      : type      ,
                        pages     : []        ,
                        folderId  : folderId  ,
                        createdAt : createdAt ,
                        lockType  : lockType  ,
                        password  : password  ,
                        totalFiles: folderData.count
                    )
                    
                    returnData.append(datum)
                } else {
                    let pages: [PagesModel] = CBFileManager.sharedInstance.retrievePages(
                        shouldAddCondition: true,
                        withKeyAndValue: ["file_id":"\(id)"],
                        ofType: nil
                    )
                    
                    let datum: DocumentsModel = DocumentsModel(
                        id        : id        ,
                        name      : name      ,
                        type      : type      ,
                        pages     : pages     ,
                        folderId  : folderId  ,
                        createdAt : createdAt ,
                        lockType  : lockType  ,
                        password  : password  ,
                        totalFiles: 0
                    )
                    
                    returnData.append(datum)
                }
                
            }
            
            return returnData
        } catch {
            print("Failed to fetch")
            return [DocumentsModel]()
        }
    }
    
    ///Pages
    func retrievePages(
        shouldAddCondition flag : Bool?               = nil,
        withKeyAndValue keyVal  : [String: String]?   = nil,
        ofType type: NSCompoundPredicate.LogicalType? = nil
    ) -> [PagesModel] {

        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return [PagesModel]()
        }

        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext

        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
                               entityName: PAGES
                           )
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor.init(key: "id", ascending: true)
        ]
        
        if flag ?? false {
            if let keyVal = keyVal {
                
                var predicates: [NSPredicate] = []
                
                for (key, value) in keyVal {
                    let predicate = NSPredicate(format: "\(key) = '\(value)'")
                    predicates.append(predicate)
                }
                
                var compundPredicate = NSCompoundPredicate()
                
                if let type = type {
                    compundPredicate = NSCompoundPredicate(
                        type          : type,
                        subpredicates : predicates
                    )
                } else {
                    compundPredicate = NSCompoundPredicate(
                        andPredicateWithSubpredicates: predicates
                    )
                }
                
                
                fetchRequest.predicate = compundPredicate
                
            }
        }

        do {
            var returnData: [PagesModel] = []
            
            let result = try managedContext.fetch(fetchRequest)
            
            for data in result as! [NSManagedObject] {
                
                let id             = data.value(forKey: "id")               as! Int32
                let fileId         = data.value(forKey: "file_id")          as! Int32
                let enhancedImage  = data.value(forKey: "enhanced_image")   as! Data
                let croppedImage   = data.value(forKey: "cropped_image")    as! Data
                let originalImage  = data.value(forKey: "original_image")   as! Data
                let scannerType    = data.value(forKey: "scanner_type")     as! String
                let pageSize       = data.value(forKey: "page_size")        as! String
                let quad           = CBFileManager.sharedInstance.retrieveQuads(
                    shouldAddCondition: true,
                    withKeyAndValue   : ["page_id": "\(id)"],
                    ofType            : nil
                )
               
                let datum : PagesModel = PagesModel(
                    id            : id            ,
                    quad          : quad          ,
                    fileId        : fileId        ,
                    originalImage : originalImage ,
                    croppedImage  : croppedImage  ,
                    enhancedImage : enhancedImage ,
                    scannerType   : scannerType   ,
                    pageSize      : pageSize      
                )
                
                returnData.append(datum)
            }
            
            return returnData
        } catch {
            print("Failed to fetch")
            return [PagesModel]()
        }
    }
    
    ///Quads
    func retrieveQuads(
        shouldAddCondition flag : Bool?               = nil,
        withKeyAndValue keyVal  : [String: String]?   = nil,
        ofType type: NSCompoundPredicate.LogicalType? = nil
    ) -> QuadsModel {

        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return QuadsModel()
        }

        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext

        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
                               entityName: QUADS
                           )
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor.init(key: "id", ascending: true)
        ]
        
        if flag ?? false {
            if let keyVal = keyVal {
                
                var predicates: [NSPredicate] = []
                
                for (key, value) in keyVal {
                    let predicate = NSPredicate(format: "\(key) = '\(value)'")
                    predicates.append(predicate)
                }
                
                var compundPredicate = NSCompoundPredicate()
                
                if let type = type {
                    compundPredicate = NSCompoundPredicate(
                        type          : type,
                        subpredicates : predicates
                    )
                } else {
                    compundPredicate = NSCompoundPredicate(
                        andPredicateWithSubpredicates: predicates
                    )
                }
                
                
                fetchRequest.predicate = compundPredicate
                
            }
        }

        do {
            var quad: QuadsModel = QuadsModel()
            
            let result = try managedContext.fetch(fetchRequest)
            
            for data in result as! [NSManagedObject] {
                
                let id             = data.value(forKey: "id")              as! Int32
                let pageId         = data.value(forKey: "page_id")         as! Int32
                let topLeftX     = data.value(forKey: "top_left_x")      as! Double
                let topLeftY     = data.value(forKey: "top_left_y")      as! Double
                let topRightX    = data.value(forKey: "top_right_x")     as! Double
                let topRightY    = data.value(forKey: "top_right_y")     as! Double
                let bottomLeftX  = data.value(forKey: "bottom_left_x")   as! Double
                let bottomLeftY  = data.value(forKey: "bottom_left_y")   as! Double
                let bottomRightX = data.value(forKey: "bottom_right_x")  as! Double
                let bottomRightY = data.value(forKey: "bottom_right_y")  as! Double
                
                quad = QuadsModel(
                    id           : id           ,
                    pageId       : pageId       ,
                    topLeftX     : topLeftX     ,
                    topLeftY     : topLeftY     ,
                    topRightX    : topRightX    ,
                    topRightY    : topRightY    ,
                    bottomLeftX  : bottomLeftX  ,
                    bottomLeftY  : bottomLeftY  ,
                    bottomRightX : bottomRightX ,
                    bottomRightY : bottomRightY
                )
                
            }
            
            return quad
        } catch {
            print("Failed to fetch")
            return QuadsModel()
        }
    }
    
    /* MARK:- DELETE */
    
    ///File/Folder
    func deleteData(
        key     : String,
        value   : Int32,
        entity  : String,
        completion: @escaping (_ finished: Bool) -> ()
    ){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return
        }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let predicate    = NSPredicate(format: "\(key) = %ld", value)
        
        fetchRequest.predicate = predicate
        
        do {
            let data = try managedContext.fetch(fetchRequest)
            if data.indices.contains(0) {
                let objectToDelete = data[0] as! NSManagedObject
                managedContext.delete(objectToDelete)
                
                do {
                    try managedContext.save()
                    completion(true)
                } catch {
                    print(error)
                    completion(false)
                }
                return
            }
            completion(false)
        } catch {
            print(error)
        }
    }

    /* MARK:- Miscellaneous */
    
    ///Get File/Folder Next Id
    func nextId(
        _ idKey : String,
        forEntityName entityName : String
    ) -> NSNumber? {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return 0
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        let req     = NSFetchRequest<NSFetchRequestResult>.init(
                         entityName: entityName
                     )
        let entity  = NSEntityDescription.entity(
                          forEntityName: entityName,
                          in: context
                      )
        
        req.entity            = entity
        req.fetchLimit        = 1
        req.propertiesToFetch = [idKey]
        let indexSort         = NSSortDescriptor.init(key: idKey, ascending: false)
        req.sortDescriptors   = [indexSort]
        
        do {
            let fetchedData     = try context.fetch(req)
            if let firstObject  = fetchedData.first as? NSManagedObject {
                if let foundValue = firstObject.value(forKey: idKey) as? NSNumber {
                    return NSNumber.init(value: foundValue.intValue + 1)
                }
            } else {
                return NSNumber.init(value: 1)
            }
        } catch {
            print(error)
        }
        
        return nil
    }
    
}
