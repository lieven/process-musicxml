//
//  MuseScoreStaff.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 15/09/2018.
//

import Foundation

public protocol Copyable {
	init?(copy: Self)
}

public protocol ManagedXMLElement: Copyable {
	var element: XMLElement { get }
	init?(element: XMLElement)
}


extension ManagedXMLElement {
	public init?(copy: Self) {
		guard let elementCopy = copy.element.copy() as? XMLElement else {
			return nil
		}
		self.init(element: elementCopy)
	}
}

extension Array where Element: AnyObject & ManagedXMLElement {
	mutating func insert(_ newElement: Element, after: Element? = nil, parent: XMLElement? = nil) {
		if let after = after {
			if let arrayIndex = firstIndex(where: { $0 === after }) {
				insert(newElement, at: arrayIndex + 1)
			} else {
				append(newElement)
			}
		}
		
		if let parentElement = parent ?? (after?.element.parent as? XMLElement) {
			if let after = after {
				parentElement.insertChild(newElement.element, at: after.element.index + 1)
			} else {
				parentElement.addChild(newElement.element)
			}
		}
	}
}



public class MuseScoreStaff: ManagedXMLElement {
	public let element: XMLElement
	public var identifier: String? {
		get {
			return element.getAttribute("id")
		}
		set {
			element.setAttribute("id", value: newValue)
		}
	}
	
	public let measures: [MuseScoreMeasure]
	
	required public init?(element: XMLElement) {
		guard element.name == "Staff" else {
			return nil
		}
		self.element = element
		self.measures = element.children(name: "Measure").compactMap { MuseScoreMeasure(element: $0) }
	}
	
	var voiceCount: Int {
		let measureVoiceCounts = measures.map { $0.voices.count }
		return measureVoiceCounts.max() ?? 0
	}
}
