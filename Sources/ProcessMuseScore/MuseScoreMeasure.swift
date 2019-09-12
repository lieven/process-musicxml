//
//  MuseScoreMeasure.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 15/09/2018.
//

import Foundation

public class MuseScoreMeasure: ManagedXMLElement {
	public let element: XMLElement
	
	required public init?(element: XMLElement) {
		guard element.name == "Measure" else {
			return nil
		}
		self.element = element
	}
	
	var voices: [XMLElement] {
		return element.elements(forName: "voice")
	}
}
