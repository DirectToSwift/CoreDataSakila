//
//  Utilities.swift
//  cdsakilaimport
//
//  Created by Helge Heß on 22.09.19.
//  Copyright © 2019 ZeeZide GmbH. All rights reserved.
//

import Foundation

extension String {
  
  func trim() -> String {
    trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  }
  
}

let dateParserNoMS : DateFormatter = {
  // 2006-02-15T10:02:19
  let fmt = DateFormatter()
  fmt.timeZone = TimeZone(secondsFromGMT: 0)!
  fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
  return fmt
}()
let dateParserWithMS : DateFormatter = {
  // 2013-05-26T14:47:57.62
  let fmt = DateFormatter()
  fmt.timeZone = TimeZone(secondsFromGMT: 0)!
  fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSS"
  return fmt
}()


extension Dictionary where Key == String {
  // Yes, those are required, we just do the mapper here.

  subscript(string key: String) -> String {
    (self[key] as! String).trim()
  }
  subscript(optString key: String) -> String? {
    (self[key] as? String)?.trim()
  }
  subscript(date key: String) -> Date {
    let s = self[key] as! String
    guard let d = dateParserWithMS.date(from: s)
               ?? dateParserNoMS  .date(from: s) else {
      fatalError("could not parse date: \(s)")
    }
    return d
  }
  subscript(optDate key: String) -> Date? {
    guard let s = self[key] as? String else { return nil }
    guard let d = dateParserWithMS.date(from: s)
               ?? dateParserNoMS  .date(from: s) else {
      fatalError("could not parse date: \(s)")
    }
    return d
  }

  subscript(key   key: String) -> Int   { self[key] as! Int }
  subscript(int32 key: String) -> Int32 { self[key] as! Int32 }

  subscript(decimal key: String) -> NSDecimalNumber {
    if let v = self[key] as? NSDecimalNumber { return v }
    if let v = self[key] as? Decimal { return v as NSDecimalNumber }
    if let v = self[key] as? Double  { return NSDecimalNumber(value: v) }
    fatalError("no decimal key: \(key) \(self[key] as Any)")
  }
}

import CoreData

@available(OSX 10.13, *)
extension NSAttributeType : CustomStringConvertible {

  public var description: String {
    switch self {
      case .undefinedAttributeType     : return "undefined"
      case .integer16AttributeType     : return "integer16"
      case .integer32AttributeType     : return "integer32"
      case .integer64AttributeType     : return "integer64"
      case .decimalAttributeType       : return "decimal"
      case .doubleAttributeType        : return "double"
      case .floatAttributeType         : return "float"
      case .stringAttributeType        : return "string"
      case .booleanAttributeType       : return "boolean"
      case .dateAttributeType          : return "date"
      case .binaryDataAttributeType    : return "binaryData"
      case .URIAttributeType           : return "URI"
      case .transformableAttributeType : return "transformable"
      case .objectIDAttributeType      : return "objectID"
      default: return "Other(\(rawValue))"
    }
  }
}
