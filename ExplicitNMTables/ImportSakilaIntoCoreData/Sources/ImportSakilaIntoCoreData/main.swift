//
//  main.swift
//  cdsakilaimport
//
//  Created by Helge Heß on 22.09.19.
//  Copyright © 2019 ZeeZide GmbH. All rights reserved.
//

import Foundation
import CoreData

let args = ProcessInfo.processInfo.arguments
guard args.count == 4 else {
  print(args.first ?? "cdimport", "<cd model> <Sakila json file> <SQLite out>")
  exit(42)
}

#if false
  // Nope, this is NOT the right thing. We need the MOM. Can't we load a model
  // from an xcdatamodel??
  let modelURL = URL(fileURLWithPath: args[1])
#else
  // The MOM is living alongside the tool
  let toolURL  = URL(fileURLWithPath: args[0])
  let modelURL = toolURL.deletingLastPathComponent()
                        .appendingPathComponent("Sakila.mom")
#endif
let fileURL   = URL(fileURLWithPath: args[2])
let outputURL = URL(fileURLWithPath: args[3])

print("Import:   ", fileURL  .path,
      "\n  using:", modelURL .path,
      "\n  to:   ", outputURL.path)


// MARK: - Load JSON

let jsonData : Data
do {
  jsonData = try Data(contentsOf: fileURL)
}
catch {
  print("Failed to load:",
        "\n  path: ", fileURL,
        "\n  error:", error)
  exit(45)
}
guard let json = try? JSONSerialization.jsonObject(with: jsonData) else {
  print("could not parse JSON:", fileURL)
  exit(46)
}
guard let jsonArray = json as? [ String : [ [ String: Any] ]] else {
  print("unexpected JSON format:", fileURL)
  exit(47)
}
print("Number of tables:", jsonArray.count)


// MARK: - Load Model

guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
  print("could not load model:", modelURL.absoluteString)
  exit(43)
}


// MARK: - Setup Stack

let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
let managedObjectContext =
      NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
managedObjectContext.persistentStoreCoordinator = psc


// MARK: - Create Store

let fm = FileManager.default
if fm.fileExists(atPath: outputURL.path) {
  print("File exists, trashing:", outputURL.path)
  try fm.trashItem(at: outputURL, resultingItemURL: nil)
}

do {
  let opts = [
    NSSQLitePragmasOption: [ "journal_mode": "DELETE" ]
  ]
  try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil,
                             at: outputURL, options: opts)
}
catch {
  print("failed to create store:", error)
  exit(44)
}


// MARK: - Run

print("import:", Date())
importSakila(jsonArray, into: managedObjectContext)

print("save:", Date())
do {
  try managedObjectContext.save()
}
catch {
  print("failed to save MOC:", error)
  exit(50)
}

// ~3MB
print("Done, find your database at:", outputURL.path)
