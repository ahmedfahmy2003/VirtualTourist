//
//  DataController.swift
//  VirtualTourist
//
//  Created by Ahmed Fahmy on 22/02/2019.
//  Copyright © 2019 Mohtaref. All rights reserved.
//

import Foundation
import CoreData

//struct ContextManager{
//    static var context: NSManagedObjectContext {
//        return persistentContainer.viewContext
//    }
//    static let persistentContainer = NSPersistentContainer(name: "VirtualTourist")
//    
//    static func saveContext(){
//        guard context.hasChanges else { return }
//        do {
//            try context.save()
//        } catch let error as NSError {
//            print("Couldn't save. \(error), \(error.userInfo)")
//        }
//    }
//}

class DataController {
    static let shared = DataController()
    
    private let persistentContainer:NSPersistentContainer
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "VirtualTourist")
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()
            completion?()
        }
    }
}

// MARK: - Autosaving

extension DataController {
    private func autoSaveViewContext(interval:TimeInterval = 30) {
        let timeInterval = interval > 0 ? interval : 30
        if interval <= 0 {
            // just informing the developer that something wrong has happened
            print("time interval should be greater than 0, will use the default time interval")
        }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
            self.autoSaveViewContext(interval: timeInterval)
        }
    }
}
