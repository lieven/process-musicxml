//
//  MuseScoreDocument.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 06/09/2018.
//

import Foundation
import ProcessMusicXML



public class MuseScoreDocument {
	public let xmlDocument: XMLDocument
	let scoreElement: XMLElement
	public let parts: [MuseScorePart]
	public let staffs: [MuseScoreStaff]
	
	init?(document: XMLDocument) {
		guard let rootElement = document.rootElement(), rootElement.name == "museScore" else {
			return nil
		}
		
		// TODO: version check: <museScore version="2.06">
		
		guard let scoreElement = rootElement.elements(forName: "Score").first else {
			return nil
		}
		
		self.xmlDocument = document
		self.scoreElement = scoreElement
		self.parts = scoreElement.elements(forName: "Part").compactMap { MuseScorePart(element: $0) }
		self.staffs = scoreElement.elements(forName: "Staff").compactMap { MuseScoreStaff(element: $0) }
	}
	
}
