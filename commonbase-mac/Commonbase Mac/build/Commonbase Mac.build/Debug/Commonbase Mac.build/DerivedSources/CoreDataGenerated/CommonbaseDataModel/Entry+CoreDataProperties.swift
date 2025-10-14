//
//  Entry+CoreDataProperties.swift
//  
//
//  Created by Bram Adams on 10/13/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Entry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        return NSFetchRequest<Entry>(entityName: "Entry")
    }

    @NSManaged public var content: String?
    @NSManaged public var contentType: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var imageData: Data?
    @NSManaged public var metadata: [String: Any]?
    @NSManaged public var sourceApplication: String?
    @NSManaged public var sourceBundleId: String?
    @NSManaged public var sourceURL: String?
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var embeddings: NSSet?
    @NSManaged public var linkedEntries: NSSet?
    @NSManaged public var backlinks: NSSet?

}

// MARK: Generated accessors for embeddings
extension Entry {

    @objc(addEmbeddingsObject:)
    @NSManaged public func addToEmbeddings(_ value: EntryEmbedding)

    @objc(removeEmbeddingsObject:)
    @NSManaged public func removeFromEmbeddings(_ value: EntryEmbedding)

    @objc(addEmbeddings:)
    @NSManaged public func addToEmbeddings(_ values: NSSet)

    @objc(removeEmbeddings:)
    @NSManaged public func removeFromEmbeddings(_ values: NSSet)

}

// MARK: Generated accessors for linkedEntries
extension Entry {

    @objc(addLinkedEntriesObject:)
    @NSManaged public func addToLinkedEntries(_ value: Entry)

    @objc(removeLinkedEntriesObject:)
    @NSManaged public func removeFromLinkedEntries(_ value: Entry)

    @objc(addLinkedEntries:)
    @NSManaged public func addToLinkedEntries(_ values: NSSet)

    @objc(removeLinkedEntries:)
    @NSManaged public func removeFromLinkedEntries(_ values: NSSet)

}

// MARK: Generated accessors for backlinks
extension Entry {

    @objc(addBacklinksObject:)
    @NSManaged public func addToBacklinks(_ value: Entry)

    @objc(removeBacklinksObject:)
    @NSManaged public func removeFromBacklinks(_ value: Entry)

    @objc(addBacklinks:)
    @NSManaged public func addToBacklinks(_ values: NSSet)

    @objc(removeBacklinks:)
    @NSManaged public func removeFromBacklinks(_ values: NSSet)

}

extension Entry : Identifiable {

}
