//
//  MuseScoreDocument.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 06/09/2018.
//

import Foundation

class MuseScorePart {
	let element: XMLElement
	
	init?(element: XMLElement) {
		guard element.name == "Part" else {
			return nil
		}
		self.element = element
	}
	
	var name: String? {
		get {
			return element.getStringValue(child: "trackName")
		}
		set {
			element.set(child: "trackName", stringValue: newValue)
		}
	}
	
	var volumeElement: XMLElement? {
		guard let instrumentElement = element.elements(forName: "Instrument").first else {
			return nil
		}
		guard let channelElement = instrumentElement.elements(forName: "Channel").first else {
			return nil
		}
		
		return channelElement.elements(forName: "controller").first(where: { $0.attribute(forName: "ctrl")?.stringValue == "7" })
		
		
	}
	
	var volume: Double {
		get {
			guard let volumeElement = volumeElement, let volumeString = volumeElement.getAttribute("value"), let volumeDouble = Double(volumeString) else {
				return 0.0
			}
			return volumeDouble/127.0
		}
		set {
			guard let volumeElement = volumeElement else {
				return
			}
			
			volumeElement.setAttribute("value", value: "\(Int(127.0 * newValue))")
		}
	}
}

class MuseScoreDocument {
	let document: XMLDocument
	let scoreElement: XMLElement
	let parts: [MuseScorePart]
	
	init?(document: XMLDocument) {
		guard let rootElement = document.rootElement(), rootElement.name == "museScore" else {
			return nil
		}
		
		// TODO: version check: <museScore version="2.06">
		
		guard let scoreElement = rootElement.elements(forName: "Score").first else {
			return nil
		}
		
		self.document = document
		self.scoreElement = scoreElement
		self.parts = scoreElement.elements(forName: "Part").compactMap { MuseScorePart(element: $0) }
	}
	
}
