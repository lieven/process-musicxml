//
//  Action+ExtractRange.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 19/02/2018.
//  Copyright © 2018 Plane Tree Software. All rights reserved.
//

import Foundation
import ProcessMusicXML

extension MeasureElement {
	func overrideChildren(attributesElement other: MeasureElement) {
		guard name == "attributes", other.name == "attributes" else {
			return
		}
		
		element.overrideChildren(withThoseOf: other.element)
	}
}


extension Score {
	func extractRange(firstMeasure: Int, lastMeasure: Int) {
		for item in partList {
    		if case .part(let part) = item {
    			// Some elements aren't repeated in each measure, so if we remove a range at the start, we need to copy some information to the new first measure.
    			var lastPrintElement: MeasureElement? = nil
    			var joinedAttributesElement: MeasureElement? = nil
    			
    			part.measures = part.measures.filter { (measure) in
    				guard let numberString = measure.attributes["number"], let number = Int(numberString) else {
    					return false
    				}
    				
    				guard number >= firstMeasure else {
    					if let printElement = measure.childElements.first(where: { $0.name == "print" }) {
    						lastPrintElement = printElement
						}
						
						if let attributesElement = measure.childElements.first(where: { $0.name == "attributes" }) {
							if let joinedAttributesElement = joinedAttributesElement {
								joinedAttributesElement.overrideChildren(attributesElement: attributesElement)
							} else {
								joinedAttributesElement = attributesElement.copy()
							}
						}
						
    					return false
    				}
    				
    				return number <= lastMeasure
    			}
    			
    			var updatedNumber = 1
    			part.measures.forEach { (measure) in
    				measure.attributes["number"] = "\(updatedNumber)"
    				updatedNumber += 1
    			}
    			
    			if let firstMeasure = part.measures.first {
    				if let printElement = lastPrintElement, firstMeasure.childElements.first(where: { $0.name == "print" }) == nil {
    					firstMeasure.childElements.insert(printElement, at: 0)
    				}
    				
    				if let joinedAttributesElement = joinedAttributesElement {
    					if let existingIndex = firstMeasure.childElements.firstIndex(where: { $0.name == "attributes" }) {
    						joinedAttributesElement.overrideChildren(attributesElement: firstMeasure.childElements[existingIndex])
							firstMeasure.childElements[existingIndex] = joinedAttributesElement
    					} else {
    						firstMeasure.childElements.insert(joinedAttributesElement, at: 0)
    					}
    				}
    			}
    		}
		}
	}
}

extension Action {
	func performExtractRangeAction(inputPath: String, outputPath: String, firstMeasure: Int, lastMeasure: Int) {
		let inputURL = URL(fileURLWithPath: inputPath)
		let outputURL = URL(fileURLWithPath: outputPath)
		
		Score.transform(inputURL: inputURL, outputURL: outputURL) { (score) in
			score.extractRange(firstMeasure: firstMeasure, lastMeasure: lastMeasure)
		}
	}
}
