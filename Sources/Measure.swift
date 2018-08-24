//
//  Measure.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 09/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

class MeasureElement {
	let element: XMLElement
	let name: String
	let duration: Int
	let musicCounter: Int
	let movesMusicCounter: Bool
	let voice: String?
	let isRest: Bool
	
	init?(originalElement: XMLElement, musicCounter: Int) {
		guard let element = originalElement.copy() as? XMLElement, let name = element.name else {
			return nil
		}
		self.element = element
		self.name = name
		self.duration = element.duration ?? 0
		self.musicCounter = musicCounter
		self.movesMusicCounter = element.movesMusicPointer
		self.voice = element.voice
		self.isRest = element.isRest
	}
	
	func copy() -> MeasureElement? {
		return MeasureElement(originalElement: element, musicCounter: musicCounter)
	}
	
	var musicCounterEnd: Int {
		return musicCounter + duration
	}
	
	func overlaps(with otherElement: MeasureElement) -> Bool {
		return musicCounter < otherElement.musicCounterEnd
			&& otherElement.musicCounter < musicCounterEnd
	}
	
	func overlaps(with elements: [MeasureElement]) -> Bool {
		for otherElement in elements {
			if overlaps(with: otherElement) {
				return true
			}
		}
		return false
	}
}



class Measure {
	var attributes: [String: String] = [:]
	var childElements: [MeasureElement] = []
	
	init?(element: XMLElement) {
		guard element.name == "measure" else {
			return nil
		}
				
		element.attributes?.forEach { (attribute) in
			if let key = attribute.name, let value = attribute.stringValue {
				attributes[key] = value
			}
		}
		
		var musicCounter = 0
		element.children?.forEach { (childNode) in
			// Possible children: "(note | backup | forward | direction | attributes | harmony | figured-bass | print | sound | barline | grouping | link | bookmark)*"
			guard let childElement = childNode as? XMLElement, let measureElement = MeasureElement(originalElement: childElement, musicCounter: musicCounter) else {
				return
			}
			
			if measureElement.name != "forward" && measureElement.name != "backup" {
				childElements.append(measureElement)
			}
			
			if measureElement.movesMusicCounter {
				musicCounter += measureElement.duration
			}
		}
	}
	
	init(copying measure: Measure) {
		self.attributes = measure.attributes
		self.childElements = measure.childElements.compactMap { $0.copy() }
	}
	
	func copy() -> Measure {
		return Measure(copying: self)
	}
	
	func remove(voice: String) {
		childElements = childElements.filter { (child) in
			if let childVoice = child.voice {
				return childVoice != voice
			} else {
				return true
			}
		}
	}
	
	func keepOnly(voice: String) {
		childElements = childElements.compactMap { (child) in
			guard let childVoice = child.voice else {
				return child
			}
			
			guard childVoice == voice else {
				return nil
			}
			
			child.element.changeVoice(to: "1")
			return child
		}
	}
	
	func overwriteNotesWithThoseFrom(variation: Measure, voice: String) {
		let variationElements = variation.childElements.filter { $0.voice == voice }
		childElements = childElements.filter { !$0.overlaps(with: variationElements) }
		childElements.append(contentsOf: variationElements.compactMap {
			let result = $0.copy()
			result?.element.changeVoice(to: "1")
			return result
		})
	}
	
	var resultElement: XMLElement {
		let result = XMLElement(name: "measure")
		result.setAttributesWith(attributes)
		
		var musicCounter = 0
		for childElement in childElements {
			let musicCounterDiff = (childElement.musicCounter - musicCounter)
			if musicCounterDiff != 0 {
				result.addChild(XMLElement(moveMusicCounter: musicCounterDiff))
				musicCounter = childElement.musicCounter
			}
			
			if let childCopy = childElement.element.copy() as? XMLElement {
				result.addChild(childCopy)
			}
			
			if childElement.movesMusicCounter {
				musicCounter += childElement.duration
			}
		}
		
		return result
	}
}
