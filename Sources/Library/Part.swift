//
//  Part.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 09/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation


public class Part {
	public let metadata: PartListElement
	public var measures: [Measure]
	
	public init(metadata: PartListElement, measures: [Measure] = []) {
		self.metadata = metadata
		self.measures = measures
	}
	
	public var resultElement: XMLElement {
		let result = XMLElement(name: "part")
		result.setAttributesWith(["id": metadata.identifier])
		result.setChildren(measures.map { $0.resultElement })
		return result
	}
	
	public var voices: Set<String> {
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
