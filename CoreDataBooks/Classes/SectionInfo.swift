//
//  SectionInfo.swift
//  CoreDataBooks
//
//  Created by Keith Lazuka on 11/17/15.
//
//

import Foundation

// similar to NSFetchedResultsController
protocol SectionInfoType {
  
  typealias ElementType
  
  var name: String { get }
  var objects: [ElementType] { get }
}

struct SectionInfo<T>: SectionInfoType {
  var name: String = ""
  var objects = [T]()
}
