//
//  Score+ReduceDynamics.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 26/02/2018.
//  Copyright © 2018 Plane Tree Software. All rights reserved.
//

import Foundation


public extension Score {
	public func reduceDynamics() {
		for item in partList {
    		if case .part(let part) = item {
				part.reduceDynamics()
			}
		}
	}
	
}

public extension Part {
	public func reduceDynamics() {
		for measure in measures {
			measure.reduceDynamics()
		}
	}
}

public extension Measure {
	public func reduceDynamics() {
		for element in childElements {
			element.reduceDynamics()
		}
	}
}

public extension MeasureElement {
	public func reduceDynamics() {
		guard name == "direction" else { return }
		
		let defaultDynamics = 80
		
		if let soundElement = element.firstChild(name: "sound"), soundElement.attribute(forName: "dynamics")?.stringValue != nil {
			// OK, let's override
			soundElement.setAttribute("dynamics", value: "\(defaultDynamics)")
		} else if element.firstChild(name: "direction-type")?.firstChild(name: "dynamics") != nil {
			// Just to be safe, let's add <sound dynamics="80">
			let soundElement = XMLElement()
			soundElement.name = "sound"
			soundElement.setAttribute("dynamics", value: "\(defaultDynamics)")
			element.addChild(soundElement)
		}
	}
}	
