//
//  Importer.swift
//  cdsakilaimport
//
//  Created by Helge Heß on 22.09.19.
//  Copyright © 2019 ZeeZide GmbH. All rights reserved.
//

import CoreData
import Foundation

typealias Record = [ String : Any ] // JSON Record

func importSakila(_ tables: [ String: [ Record ]],
                  into moc: NSManagedObjectContext)
{
  
  // Note: Strings in the tables are not trimmed,
  //       Dates use this format: 2006-02-15T10:02:19
  func load<T: NSManagedObject>(_ table: String,
                                for entityName: String, as type: T.Type,
                                in moc: NSManagedObjectContext,
                                fill: ( Record, T ) -> Void)
       -> [ Int : T ]
  {
    let pkey = table + "_id"
    var map  = [ Int : T ]()
    for rec in tables[table]! {
      let object = NSEntityDescription
            .insertNewObject(forEntityName: entityName, into: moc) as! T
      fill(rec, object)
      if let v = rec[pkey] as? Int {
        assert(map[v] == nil)
        map[v] = object
      }
    }
    return map
  }
  
  
  // MARK: - Leaf Entities

  let languageMap = load("language", for: "Language", as: Language.self,
                         in: moc)
  { record, object in
    // {"language_id":1,
    //  "name":"English             ","last_update":"2006-02-15T10:02:19"}
    object.lastUpdate = record[date: "last_update"]
    object.name       = record[string: "name"]
  }
  
  let actorMap = load("actor", for: "Actor", as: Actor.self, in: moc) {
    record, object in
    //     {"actor_id":2,"first_name":"Nick","last_name":"Wahlberg","last_update":"2013-05-26T14:47:57.62"}
    object.lastUpdate = record[date:   "last_update"]
    object.firstName  = record[string: "first_name"]
    object.lastName   = record[string: "last_name"]
  }

  let categoryMap = load("category", for: "Category", as: Category.self,
                         in: moc)
  { record, object in
    // {"category_id":1,"name":"Action","last_update":"2006-02-15T09:46:27"}
    object.lastUpdate = record[date:   "last_update"]
    object.name       = record[string: "name"]
  }

  let countryMap = load("country", for: "Country", as: Country.self, in: moc) {
    record, object in
    //{"country_id":1,
    // "country":"Afghanistan","last_update":"2006-02-15T09:44:00"}
    object.lastUpdate = record[date:   "last_update"]
    object.country    = record[string: "country"]
  }

  
  // MARK: - Address Entities
  
  let cityMap = load("city", for: "City", as: City.self, in: moc) {
    record, object in
    // {"city_id":1,"city":"A Corua (La Corua)","country_id":87,"last_update":"2006-02-15T09:45:25"}
    object.lastUpdate = record[date:   "last_update"]
    object.city       = record[string: "city"]
    object.country = countryMap[record[key: "country_id"]]
    assert(object.country != nil)
  }
  
  let addressMap = load("address", for: "Address", as: Address.self, in: moc) {
    record, object in
    // {"address_id":2,"address":"28 MySQL Boulevard","address2":null,"district":"QLD","city_id":576,"postal_code":"","phone":"","last_update":"2006-02-15T09:45:30"}
    object.lastUpdate = record[date:      "last_update"]
    object.address    = record[string:    "address"]
    object.address2   = record[optString: "address2"]
    object.district   = record[string:    "district"]
    object.postalCode = record[optString: "postal_code"]
    object.phone      = record[optString: "phone"]

    object.city       = cityMap[record[key: "city_id"]]
    assert(object.city != nil)
  }
  
  
  // MARK: - Film
  
  let filmMap = load("film", for: "Film", as: Film.self, in: moc) {
    record, object in
    // {"film_id":133,"title":"Chamber Italian","description":"A Fateful Reflection of a Moose And a Husband who must Overcome a Monkey in Nigeria","release_year":2006,"language_id":1,"rental_duration":7,"rental_rate":4.99,"length":117,"replacement_cost":14.99,"rating":"NC-17","last_update":"2013-05-26T14:50:58.951","special_features":["Trailers"],"fulltext":"'chamber':1 'fate':4 'husband':11 'italian':2 'monkey':16 'moos':8 'must':13 'nigeria':18 'overcom':14 'reflect':5"}
    object.lastUpdate      = record[date:      "last_update"]
    object.title           = record[string:    "title"]
    object.releaseYear     = record[optString: "release_year"]
    object.rentalRate      = record[decimal:   "rental_rate"]
    object.length          = record[int32:     "length"]
    object.replacementCost = record[decimal:   "replacement_cost"]
    object.rating          = record[optString: "rating"]
    
    if let v = record["special_features"] as? [ String ] {
      object.specialFeatures = v.joined(separator: ",")
    }
    // no fulltext

    object.language = languageMap[record[key: "language_id"]]
    assert(object.language != nil)
  }

  _ = load("film_actor", for: "FilmActor", as: FilmActor.self, in: moc) {
    record, object in
    //{"actor_id":1,"film_id":1,"last_update":"2006-02-15T10:05:03"}
    object.lastUpdate = record[date: "last_update"]
    object.film  = filmMap [record[key: "film_id"]]
    object.actor = actorMap[record[key: "actor_id"]]
    assert(object.film != nil && object.actor != nil)
  }
  _ = load("film_category", for: "FilmCategory", as: FilmCategory.self, in: moc)
  { record, object in
    //{"film_id":1,"category_id":6,"last_update":"2006-02-15T10:07:09"}
    object.lastUpdate = record[date: "last_update"]
    object.film     = filmMap [record[key: "film_id"]]
    object.category = categoryMap[record[key: "category_id"]]
    assert(object.film != nil && object.category != nil)
  }
  
  
  // MARK: - Staff & Store
  
  // cyclic, wire up later
  var staffForStoreKey = [ Int : [ Staff ] ]()
  
  let staffMap = load("staff", for: "Staff", as: Staff.self, in: moc) {
    record, object in
    // {"staff_id":1,"first_name":"Mike","last_name":"Hillyer","address_id":3,
    //  "email":"Mike.Hillyer@sakilastaff.com","store_id":1,"active":true,
    //  "username":"Mike","password":"8cb2237d0679ca88db6464eac60da96345513964",
    //  "last_update":"2006-05-16T16:13:11.79328","picture":"\"}
    object.lastUpdate = record[date:      "last_update"]
    object.username   = record[string:    "username"]
    object.password   = record[string:    "password"]
    object.firstName  = record[string:    "first_name"]
    object.lastName   = record[string:    "last_name"]
    object.email      = record[optString: "email"]
    object.active     = (record["active"] as? Bool) ?? false

    let storeID = record[key: "store_id"]
    if staffForStoreKey[storeID] == nil {
      staffForStoreKey[storeID] = [ object ]
    }
    else {
      staffForStoreKey[storeID]!.append(object)
    }
    
    object.address = addressMap[record[key: "address_id"]]
    assert(object.address != nil)
    
    // FIXME: Import picture, available as string: "\x89504e470d0a5a0a"
    // no fulltext
  }

  let storeMap = load("store", for: "Store", as: Store.self, in: moc) {
    record, object in
    // {"store_id":1,"manager_staff_id":1,"address_id":1,"last_update":"2006-02-15T09:57:12"}
    object.lastUpdate = record[date: "last_update"]
    object.address    = addressMap[record[key: "address_id"]]
    object.manager    = staffMap  [record[key: "manager_staff_id"]]
    assert(object.address != nil && object.manager != nil)
    for staff in staffForStoreKey.removeValue(forKey: record[key: "store_id"])
                 ?? []
    {
      staff.store = object
    }
  }
  
  let inventoryMap = load("inventory", for: "Inventory", as: Inventory.self,
                          in: moc)
  { record, object in
    // {"inventory_id":1,"film_id":1,"store_id":1,"last_update":"2006-02-15T10:09:17"}
    object.lastUpdate = record[date: "last_update"]
    object.store      = storeMap[record[key: "store_id"]]
    object.film       = filmMap [record[key: "film_id"]]
    assert(object.store != nil && object.film != nil)
  }

  
  // MARK: - Customers
  
  let customerMap = load("customer", for: "Customer", as: Customer.self,
                         in: moc)
  { record, object in
    // {"customer_id":524,"store_id":1,"first_name":"Jared","last_name":"Ely",
    //  "email":"jared.ely@sakilacustomer.org","address_id":530,
    //  "activebool":true,"create_date":"2006-02-14",
    //  "last_update":"2013-05-26T14:49:45.738","active":1}
    object.lastUpdate = record[date:      "last_update"]
    object.firstName  = record[string:    "first_name"]
    object.lastName   = record[string:    "last_name"]
    object.email      = record[optString: "email"]
    object.active     = (record["activebool"] as? Bool) ?? false
    // not using active, but activebool. No idea why they kept both.

    // OK, so create date is just a date "2006-02-14" :-/
    // We could do some hops to expose it as DateComponents I supposed,
    // but lets do the stupid thing:
    let cd   = (record["create_date"] as! String) + "T12:00:00"
    let date = dateParserNoMS.date(from: cd)
    assert(date != nil)
    object.createDate = date
    
    object.address = addressMap[record[key: "address_id"]]
    object.store   = storeMap[record[key: "store_id"]]
    assert(object.store != nil && object.address != nil)
  }

  let rentalsMap = load("rental", for: "Rental", as: Rental.self, in: moc) {
    record, object in
    // {"rental_id":2,"rental_date":"2005-05-24T22:54:33","inventory_id":1525,
    //  "customer_id":459,"return_date":"2005-05-28T19:40:33","staff_id":1,
    //  "last_update":"2006-02-16T02:30:53"}
    object.lastUpdate = record[date:    "last_update"]
    object.rentalDate = record[date:    "rental_date"]
    object.returnDate = record[optDate: "return_date"]

    object.inventory  = inventoryMap[record[key: "inventory_id"]]
    object.customer   = customerMap [record[key: "customer_id"]]
    object.staff      = staffMap    [record[key: "staff_id"]]
    assert(object.inventory != nil && object.customer != nil &&
           object.staff != nil)
  }
  
  let paymentsMap = load("payment", for: "Payment", as: Payment.self, in: moc) {
    record, object in
    // {"payment_id":17503,"customer_id":341,"staff_id":2,"rental_id":1520,
    //  "amount":7.99,"payment_date":"2007-02-15T22:25:46.996577"}
    object.paymentDate = record[date:    "payment_date"]
    object.lastUpdate  = object.paymentDate // our data has no lastUpdate?
    object.amount      = record[decimal: "amount"]
    object.customer    = customerMap[record[key: "customer_id"]]
    object.staff       = staffMap   [record[key: "staff_id"]]
    object.rental      = rentalsMap [record[key: "rental_id"]]

    assert(object.rental != nil && object.customer != nil &&
           object.staff != nil)
  }


  // MARK: - Done
  // ~133MB of memory
  print("# of langs:", languageMap .count,
        "actors:",     actorMap    .count,
        "categories:", categoryMap .count,
        "countries:",  countryMap  .count,
        "cities:",     cityMap     .count,
        "addresses:",  addressMap  .count,
        "films:",      filmMap     .count,
        "staff:",      staffMap    .count,
        "stores:",     storeMap    .count,
        "inventory:",  inventoryMap.count,
        "customers:",  customerMap .count,
        "rentals:",    rentalsMap  .count,
        "payments:",   paymentsMap .count)
}
