//
//  Score.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 09/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

public class PartListElement {
	public var identifier: String {
		didSet {
			element.setAttribute("id", value: identifier)
			element.replace(oldValue, with: identifier, inDescendentsAttributesWithName: "id")
		}
	}
	
	public var name: String {
		didSet {
			if let existing = element.elements(forName: "part-name").first {
				existing.stringValue = name
			} else {
				element.addChild(XMLElement(name: "part-name", stringValue: name))
			}
			
			let abbreviatedName = name.reduce("") { (result, character) in
				let charString = String(character)
				if charString.lowercased() != charString {
					return "\(result)\(character)."
				} else {
					return result
				}
			}
			
			element.elements(forName: "part-abbreviation").first?.stringValue = abbreviatedName
			
			element.elements(forName: "score-instrument").first?.elements(forName: "instrument-name").first?.stringValue = name
		}
	}
	
	public var volume: String? {
		didSet {
			element.elements(forName: "midi-instrument").first?.elements(forName: "volume").first?.stringValue = volume
		}
	}
	
	public let element: XMLElement
	
	public init?(element originalElement: XMLElement) {
		guard originalElement.name == "score-part", let element = originalElement.copy() as? XMLElement else {
			return nil
		}
		
		guard let identifier = element.attribute(forName: "id")?.stringValue else {
			return nil
		}
		
		guard let name = element.elements(forName: "part-name").first?.stringValue else {
			return nil
		}
		
		self.identifier = identifier
		self.name = name
		self.volume = element.elements(forName: "midi-instrument").first?.elements(forName: "volume").first?.stringValue
		self.element = element
	}
}

public enum PartListItem {
	case part(Part)
	case other(XMLElement)
}



public extension PartListItem {
	init?(element: XMLElement, measures: [String: [Measure]]) {
		if element.name == "score-part" {
			guard let metadata = PartListElement(element: element) else {
				return nil
			}
			
			guard let measures = measures[metadata.identifier] else {
				return nil
			}
			
			self = .part(Part(metadata: metadata, measures: measures))
		} else {
			guard let elementCopy = element.copy() as? XMLElement else {
				return nil
			}
			self = .other(elementCopy)
		}
	}
	
	var resultListElement: XMLElement {
		switch self {
			case .part(let part):
				return part.metadata.element
			case .other(let element):
				return element
		}
	}
	
	var resultElement: XMLElement? {
		switch self {
			case .part(let part):
				return part.resultElement
			case .other:
				return nil
		}
	}
}


public class Score {
	public let originalDocument: XMLDocument
	public let headerElements: [XMLElement]
	public var partList: [PartListItem]
	
	public init?(document originalDocument: XMLDocument) {
		guard let rootElement = originalDocument.rootElement(), rootElement.name == "score-partwise" else {
			return nil
		}
		
		var partMeasures = [String: [Measure]]()
		
		let partElements = rootElement.elements(forName: "part")
		partElements.forEach { (partElement) in
			guard let partID = partElement.attribute(forName: "id")?.stringValue else {
				return
			}
			partMeasures[partID] = partElement.elements(forName: "measure").compactMap { Measure(element: $0) }
		}
		
		guard let partListElement = rootElement.elements(forName: "part-list").first?.copy() as? XMLElement else {
			return nil
		}
		
		self.partList = partListElement.children?.compactMap { (node) in
			guard let element = node as? XMLElement else {
				return nil
			}
			return PartListItem(element: element, measures: partMeasures)
		} ?? []
		
		
		self.originalDocument = originalDocument
		self.headerElements = rootElement.children?.compactMap { (node) in
			guard let element = node as? XMLElement else {
				return nil
			}
			
			if let elementName = element.name, (elementName == "part-list" || elementName == "part") {
				return nil
			}
			
			return element.copy() as? XMLElement
		} ?? []
	}
	
	func partIndex(identifier: String) -> Int? {
		return partList.index { (item) in
			if case .part(let part) = item, part.metadata.identifier == identifier {
				return true
			}
			return false
		}
	}
	
	func part(identifier: String) -> Part? {
		for item in partList {
			if case .part(let part) = item, part.metadata.identifier == identifier {
				return part
			}
		}
		return nil
	}
	
	func add(part: Part, after: Part? = nil) {
		if let after = after, let afterIndex = partIndex(identifier: after.metadata.identifier) {
			partList.insert(.part(part), at: afterIndex + 1)
		} else {
			partList.append(.part(part))
		}
	}
	
	var partListElement: XMLElement {
		let result = XMLElement(name: "part-list")
		result.setChildren(partList.map { $0.resultListElement })
		return result
	}
	
	public var resultDocument: XMLDocument? {
		guard let result = originalDocument.copy() as? XMLDocument else {
			return nil
		}
		
		var resultElements = [XMLElement]()
		resultElements.append(contentsOf: headerElements)
		resultElements.append(partListElement)
		resultElements.append(contentsOf: partList.compactMap { $0.resultElement })
		
		result.rootElement()?.setChildren(resultElements.compactMap { $0.copy() as? XMLElement })
		
		return result
	}
}

