//
//  EntryEmbedding+CoreDataProperties.swift
//  
//
//  Created by Bram Adams on 10/13/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension EntryEmbedding {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EntryEmbedding> {
        return NSFetchRequest<EntryEmbedding>(entityName: "EntryEmbedding")
    }

    @NSManaged public var embedding: [Float]?
    @NSManaged public var id: UUID?
    @NSManaged public var model: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var entry: Entry?

}

extension EntryEmbedding : Identifiable {

}
