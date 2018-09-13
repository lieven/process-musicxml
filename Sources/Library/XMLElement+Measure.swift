//
//  XMLElement+Measure.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 09/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation



extension XMLElement {

	var voices: Set<String> {
		var voices = Set<String>()
		children?.forEach {
			if let voice = ($0 as? XMLElement)?.voice {
				voices.insert(voice)
			}
		}
		return voices
	}
}
