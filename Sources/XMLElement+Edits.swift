//
//  XMLElement+Edits.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 09/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation


extension XMLElement {
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
	
	func setAttribute(_ key: String, value: String) {
		if let attribute = attribute(forName: key) {
			attribute.stringValue = value
		} else {
			let attribute = XMLNode(kind: .attribute)
			attribute.stringValue = value
			addAttribute(attribute)
		}
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
}
