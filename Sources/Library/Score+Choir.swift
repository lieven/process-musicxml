//
//  Score+Choir.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

extension Score {
	
	public var sopranoPart: Part? {
		return partWithName(in: [ "sopraan", "soprano" ])
	}
	
	public var altoPart: Part? {
		return partWithName(in: [ "alt", "alto" ])
	}
	
	public var womenPart: Part? {
		return partWithName(in: [ "women", "vrouwen", "sopraan/alt", "sopraan\nalt", "soprano/alto", "soprano\nalto" ])
	}
	
	public var tenorPart: Part? {
		return partWithName(in: [ "tenor" ])
	}
	
	public var bassPart: Part? {
		return partWithName(in: [ "bass", "bas" ])
	}
	
	public var menPart: Part? {
		return partWithName(in: [ "men", "mannen", "tenor/bas", "tenor\nbas", "tenor/bass", "tenor\nbass" ])
	}
	
	public var highVoicesPart: Part? {
		return partWithName(in: [ "sopraan/tenor", "sopraan\ntenor" ])
	}
	
	public var lowVoicesPart: Part? {
		return partWithName(in: [ "alt/bas", "alt\nbas" ])
	}
	
	
	private func partWithName(in namesList: [String]) -> Part? {
		for item in partList {
			if case .part(let part) = item {
				if namesList.contains(part.metadata.name.lowercased()) {
					return part
				}
			}
		}
		return nil
	}
	
	public func splitWomen(part: Part) {
		if part.voices.contains("2") {
			extractVariation(basePart: part, baseVoice: "1", variationPart: part, variationVoice: "2", cut: true, destinationPartName: "Alt")
			part.metadata.name = "Sopraan"
		}
	}
	
	public func splitMen(part: Part) {
		if part.voices.contains("2") {
			extractVariation(basePart: part, baseVoice: "1", variationPart: part, variationVoice: "2", cut: true, destinationPartName: "Bas")
			part.metadata.name = "Tenor"
		}
	}
	
	public func extractMezzos(soprano: Part, alto: Part) {
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
	
	public func extractBaritones(tenor: Part, bass: Part) {
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
