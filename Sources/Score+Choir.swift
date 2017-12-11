//
//  Score+Choir.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

extension Score {
	
	var sopranoPart: Part? {
		return partWithName(in: [ "sopraan", "soprano" ])
	}
	
	var altoPart: Part? {
		return partWithName(in: [ "alt", "alto" ])
	}
	
	var tenorPart: Part? {
		return partWithName(in: [ "tenor" ])
	}
	
	var bassPart: Part? {
		return partWithName(in: [ "bass", "bas" ])
	}
	
	private func partWithName(in namesList: [String]) -> Part? {
		for item in partList {
			if case .part(let part) = item, namesList.contains(part.metadata.name.lowercased()) {
				return part
			}
		}
		return nil
	}
	
	func extractMezzos(soprano: Part, alto: Part) {
		if soprano.voices.contains("2") {
			if alto.voices.contains("2") {
				extractVariation(basePart: soprano, baseVoice: "1", variationPart: soprano, variationVoice: "2", cut: true, destinationPartName: "Mezzo-Sopraan")
				extractVariation(basePart: alto, baseVoice: "1", variationPart: alto, variationVoice: "2", cut: true, destinationPartName: "Mezzo-Alt")
			} else {
				extractVariation(basePart: soprano, baseVoice: "1", variationPart: soprano, variationVoice: "2", cut: false, destinationPartName: "Mezzo-Sopraan")
				extractVariation(basePart: alto, baseVoice: "1", variationPart: soprano, variationVoice: "2", cut: true, destinationPartName: "Mezzo-Alt")
			}
		} else if alto.voices.contains("2") {
			extractVariation(basePart: alto, baseVoice: "1", variationPart: alto, variationVoice: "2", cut: false, destinationPartName: "Mezzo-Alt")
			extractVariation(basePart: soprano, baseVoice: "1", variationPart: alto, variationVoice: "2", cut: true, destinationPartName: "Mezzo-Sopraan")
		}
	}
	
	func extractBaritones(tenor: Part, bass: Part) {
		if tenor.voices.contains("2") {
			if bass.voices.contains("2") {
				extractVariation(basePart: tenor, baseVoice: "1", variationPart: tenor, variationVoice: "2", cut: true, destinationPartName: "Bari-Tenor")
				extractVariation(basePart: bass, baseVoice: "1", variationPart: bass, variationVoice: "2", cut: true, destinationPartName: "Bari-Bas")
			} else {
				extractVariation(basePart: tenor, baseVoice: "1", variationPart: tenor, variationVoice: "2", cut: false, destinationPartName: "Bari-Tenor")
				extractVariation(basePart: bass, baseVoice: "1", variationPart: tenor, variationVoice: "2", cut: true, destinationPartName: "Bari-Bas")
			}
		} else if bass.voices.contains("2") {
			extractVariation(basePart: bass, baseVoice: "1", variationPart: bass, variationVoice: "2", cut: false, destinationPartName: "Bari-Bas")
			extractVariation(basePart: tenor, baseVoice: "1", variationPart: bass, variationVoice: "2", cut: true, destinationPartName: "Bari-Tenor")
		}
	}
}
