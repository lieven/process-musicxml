//
//  XMLElement+Edits.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 09/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation


public extension XMLElement {
	func getStringValue(child: String) -> String? {
		return elements(forName: child).first?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	func set(child: String, stringValue: String?) {
		let existingElement = elements(forName: child).first
		if let newValue = stringValue {
			if let element = existingElement {
				element.stringValue = newValue
			} else {
				addChild(XMLElement(name: child, stringValue: newValue))
			}
		} else if let element = existingElement {
			removeChild(at: element.index)
		}
	}
	
	func append(_ suffix: String, toAttributeWithName name: String) {
		attribute(forName: name)?.stringValue?.append(suffix)
	}
	
	func append(_ suffix: String, toDescendentsAttributesWithName name: String) {
		children?.forEach { (node) in
			if let child = node as? XMLElement {
				child.append(suffix, toAttributeWithName: name)
				child.append(suffix, toDescendentsAttributesWithName: name)
			}
		}
	}
	
	func replace(_ value: String, with newValue: String, inAttributeWithName name: String) {
		guard let attribute = attribute(forName: name) else {
			return
		}
		attribute.stringValue = attribute.stringValue?.replacingOccurrences(of: value, with: newValue)
	}
	
	func replace(_ value: String, with newValue: String, inDescendentsAttributesWithName name: String) {
		children?.forEach { (node) in
			if let child = node as? XMLElement {
				child.replace(value, with: newValue, inAttributeWithName: name)
				child.replace(value, with: newValue, inDescendentsAttributesWithName: name)
			}
		}
	}
	
	func setAttribute(_ key: String, value: String?) {
		guard let value = value else {
			removeAttribute(forName: key)
			return
		}
		
		if let attribute = attribute(forName: key) {
			attribute.stringValue = value
		} else {
			let attribute = XMLNode(kind: .attribute)
			attribute.stringValue = value
			addAttribute(attribute)
		}
	}
	
	func getAttribute(_ key: String) -> String? {
		return attribute(forName: key)?.stringValue
	}
	
	func duplicate() -> XMLElement? {
		guard let parent = parent as? XMLElement, let elementCopy = self.copy() as? XMLElement else {
			return nil
		}
		
		parent.insertChild(elementCopy, at: self.index + 1)
		
		return elementCopy
	}
	
	func children(name: String) -> [XMLElement] {
		let results: [XMLElement]? = children?.compactMap {
			guard let childElement = $0 as? XMLElement, childElement.name == name else {
				return nil
			}
			
			return childElement
		}
		return results ?? []
	}
	
	func firstChild(name: String) -> XMLElement? {
		return children(name: name).first
	}
	
	func insert(_ node: XMLNode, after: XMLNode?) {
		if let after = after, after.parent == self {
			insertChild(node, at: after.index + 1)
		} else {
			addChild(node)
		}
	}
	
	func overrideChildren(withThoseOf other: XMLElement) {
		other.children?.forEach { (otherChild) in
			guard let otherChildElement = otherChild as? XMLElement, let otherChildName = otherChildElement.name else {
				return
			}
			
			if let existingChild = firstChild(name: otherChildName), let otherChildCopy = otherChildElement.copy() as? XMLElement {
				replaceChild(at: existingChild.index, with: otherChildCopy)
			}
		}
	}
	
	func replaceChildren(name: String, with other: [XMLElement]) {
		var lastIndex: Int?
		
		while let lastChild = children(name: name).last {
			let index = lastChild.index
			removeChild(at: index)
			lastIndex = index
		}
		
		var insertAtIndex = lastIndex ?? children?.count ?? 0
		
		for element in other {
			insertChild(element, at: insertAtIndex)
			insertAtIndex += 1
		}
	}
}
