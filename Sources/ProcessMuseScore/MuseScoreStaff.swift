//
//  MuseScoreStaff.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 15/09/2018.
//

import Foundation



public class MuseScoreStaff {
	let element: XMLElement
	
	public let measures: [MuseScoreMeasure]
	
	init?(element: XMLElement) {
		guard element.name == "Staff" else {
			return nil
		}
		self.element = element
		self.measures = element.children(name: "Measure").compactMap { MuseScoreMeasure(element: $0) }
	}
}
