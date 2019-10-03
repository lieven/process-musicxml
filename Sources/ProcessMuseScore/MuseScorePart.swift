//
//  MuseScorePart.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 15/09/2018.
//

import Foundation


public class MuseScorePart: ManagedXMLElement {
	public let element: XMLElement
	
	required public init?(element: XMLElement) {
		guard element.name == "Part" else {
			return nil
		}
		self.element = element
	}
	
	public var name: String? {
		get {
			return element.getStringValue(child: "trackName")
		}
		set {
			element.set(child: "trackName", stringValue: newValue)
			instrumentElement?.set(child: "trackName", stringValue: newValue)
		}
	}
	
	public var longInstrumentName: String? {
		get {
			return instrumentElement?.getStringValue(child: "longName")
		}
		set {
			instrumentElement?.set(child: "longName", stringValue: newValue)
		}
	}
	
	public var shortInstrumentName: String? {
		get {
			return instrumentElement?.getStringValue(child: "shortName")
		}
		set {
			instrumentElement?.set(child: "shortName", stringValue: newValue)
		}
	}
	
	fileprivate var staffElements: [XMLElement] {
		return element.elements(forName: "Staff")
	}
	
	var staffIDs: [String] {
		get {
			return staffElements.compactMap { $0.getAttribute("id") }
		}
		set {
			let elements = staffElements
			for (element, staffID) in zip(elements, newValue) {
				element.setAttribute("id", value: staffID)
			}
		}
	}
	
	var instrumentElement: XMLElement? {
		return element.elements(forName: "Instrument").first
	}
	
	var channelElement: XMLElement? {
		return instrumentElement?.elements(forName: "Channel").first
	}
	
	fileprivate var volumeElement: XMLElement? {
		return channelElement?.elements(forName: "controller").first(where: { $0.attribute(forName: "ctrl")?.stringValue == "7" })
	}
	
	fileprivate var volumeString: String? {
		get {
			return volumeElement?.getAttribute("value")
		}
		set {
			guard let channelElement = channelElement else {
				return
			}
			
			if let volumeElement = volumeElement {
				if let volume = newValue {
					volumeElement.setAttribute("value", value: volume)
				} else {
					channelElement.removeChild(at: volumeElement.index)
				}
			} else if let volume = newValue {
				let volumeElement = XMLElement(name: "controller")
				volumeElement.setAttributesWith(["ctrl": "7", "value": volume])
				channelElement.addChild(volumeElement)
			}
		}
	}
	
	
	public var volume: Double {
		get {
			guard let volumeString = volumeString, let volumeDouble = Double(volumeString) else {
				return 0.0
			}
			return volumeDouble/127.0
		}
		set {
			volumeString = "\(Int(127.0 * newValue))"
		}
	}
}
