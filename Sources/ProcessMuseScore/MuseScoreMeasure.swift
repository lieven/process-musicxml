//
//  MuseScoreMeasure.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 15/09/2018.
//

import Foundation

public class MuseScoreMeasure {
	let element: XMLElement
	
	init?(element: XMLElement) {
		guard element.name == "Measure" else {
			return nil
		}
		self.element = element
	}
}
