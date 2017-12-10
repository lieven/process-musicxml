//
//  Part.swift
//  ExplodeVoices
//
//  Created by Lieven Dekeyser on 09/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation


class Part {
	let metadata: PartListElement
	var measures: [Measure]
	
	init(metadata: PartListElement, measures: [Measure] = []) {
		self.metadata = metadata
		self.measures = measures
	}
	
	var resultElement: XMLElement {
		let result = XMLElement(name: "part")
		result.setAttributesWith(["id": metadata.identifier])
		result.setChildren(measures.map { $0.resultElement })
		return result
	}
	
	var voices: Set<String> {
		var voices = Set<String>()
		measures.forEach {
			$0.childElements.forEach { 
				if let voice = $0.voice {
					voices.insert(voice)
				}
			}
		}
		return voices
	}
}
