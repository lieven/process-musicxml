//
//  XMLElement+MeasureElement.swift
//  ExplodeVoices
//
//  Created by Lieven Dekeyser on 09/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

extension XMLElement {

	var duration: Int? {
		guard let elementName = name, let durationElement = elements(forName: "duration").first, let durationString = durationElement.stringValue, let duration = Int(durationString) else {
			return nil
		}
		
		switch elementName {
			case "forward", "note":
				return duration
			case "backup":
				return -duration
			default:
				fputs("unexpected element with duration: \(elementName)\n", stderr)
				return duration
		}
	}
	
	var movesMusicPointer: Bool {
		guard let elementName = self.name else {
			return false
		}
		
		switch elementName {
			case "forward", "backup":
				return true
			
			case "note":
				return elements(forName: "chord").isEmpty
			
			default:
				return false
		}
	}
	
	var voice: String? {
		guard let voiceElement = elements(forName: "voice").first, let voice = voiceElement.stringValue else {
			return nil
		}
		return voice
	}
	
	var isRest: Bool {
		return (name == "note" && !elements(forName: "rest").isEmpty)
	}
	
	convenience init(moveMusicCounter duration: Int) {
		self.init(name: duration > 0 ? "forward" : "backup")
		addChild(XMLElement(name: "duration", stringValue: "\(abs(duration))"))
	}
}
