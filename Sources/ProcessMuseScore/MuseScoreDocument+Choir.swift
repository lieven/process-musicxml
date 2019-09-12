//
//  MuseScoreDocument+Choir.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 16/08/2019.
//

import Foundation

public enum ChoirVoice: CaseIterable {
	case soprano
	case alto
	case women
	case tenor
	case bass
	case men
	case highVoices
	case lowVoices
	case mezzoSoprano
	case mezzoAlto
}

extension ChoirVoice {
	public var names: [String] {
		switch self {
		case .soprano:
			return ["sopraan", "soprano"]
		case .alto:
			return ["alt", "alto"]
		case .women:
			return ["women", "vrouwen", "sopraan/alt", "sopraan\nalt", "soprano/alto", "soprano\nalto"]
		case .tenor:
			return ["tenor"]
		case .bass:
			return ["bass", "bas"]
		case .men:
			return ["men", "mannen", "tenor/bas", "tenor\nbas", "tenor/bass", "tenor\nbass"]
		case .highVoices:
			return ["sopraan/tenor", "sopraan\ntenor"]
		case .lowVoices:
			return ["alt/bas", "alt\nbas"]
		case .mezzoSoprano:
			return ["mezzo-sopraan", "mezzo-soprano"]
		case .mezzoAlto:
			return ["mezzo-alt", "mezzo-alto"]
		}
	}
}

public struct PartName {
	let long: String
	let short: String
	
	static let mezzoSoprano = PartName(long: "Mezzo-Sopraan", short: "M.S.")
	static let mezzoAlto = PartName(long: "Mezzo-Alt", short: "M.A.")
}

public extension MuseScoreDocument {
	func choirPart(_ voice: ChoirVoice) -> MuseScorePart? {
		return partWithName(in: voice.names)
	}
	
	func choirStaff(_ voice: ChoirVoice) -> MuseScoreStaff? {
		guard let staffID = choirPart(voice)?.staffID else {
			return nil
		}
		return staff(identifier: staffID)
	}

	private func partWithName(in namesList: [String]) -> MuseScorePart? {
		return parts.first { part in
			guard let partName = part.name?.lowercased() else {
				return false
			}
			return namesList.contains(partName)
		}
	}
	
	func extractMezzos(soprano: MuseScorePart, alto: MuseScorePart) {
		guard let sopranoStaff = staff(part: soprano), let altoStaff = staff(part: alto) else {
			return
		}
	
		if sopranoStaff.voiceCount >= 2 {
			if altoStaff.voiceCount >= 2 {
				extractVariation(basePart: soprano, baseVoice: 0, variationPart: soprano, variationVoice: 1, cut: true, destinationPartName: .mezzoSoprano)
				extractVariation(basePart: alto, baseVoice: 0, variationPart: alto, variationVoice: 1, cut: true, destinationPartName: .mezzoAlto)
			} else {
				extractVariation(basePart: soprano, baseVoice: 0, variationPart: soprano, variationVoice: 1, cut: false, destinationPartName: .mezzoSoprano)
				extractVariation(basePart: alto, baseVoice: 0, variationPart: soprano, variationVoice: 1, cut: true, destinationPartName: .mezzoAlto)
			}
		} else if altoStaff.voiceCount >= 2 {
			extractVariation(basePart: alto, baseVoice: 0, variationPart: alto, variationVoice: 1, cut: false, destinationPartName: .mezzoAlto)
			extractVariation(basePart: soprano, baseVoice: 0, variationPart: alto, variationVoice: 1, cut: true, destinationPartName: .mezzoSoprano)
		}
	}
	
	func extractVariation(basePart: MuseScorePart, baseVoice: Int, variationPart: MuseScorePart, variationVoice: Int, cut: Bool, destinationPartName: PartName) {
		
		// MARK: - Duplicate base part and create new staff
		guard let baseStaff = staff(part: basePart) else {
			fputs("Could not find base staff\n", stderr)
			exit(1)
		}
		
		guard let destinationStaff = MuseScoreStaff(copy: baseStaff) else {
			fputs("Could not copy staff\n", stderr)
			exit(1)
		}
		let destinationStaffID = nextStaffIdentifier()
		destinationStaff.identifier = destinationStaffID
		
		
		guard let destinationPart = MuseScorePart(copy: basePart) else {
			fputs("Could not copy part\n", stderr)
			exit(1)
		}
		
		destinationPart.staffID = destinationStaffID
		destinationPart.name = destinationPartName.long
		destinationPart.longInstrumentName = destinationPartName.long
		destinationPart.shortInstrumentName = destinationPartName.short
		
		addPart(destinationPart, staff: destinationStaff, after: basePart)
		
		
		
		/*
		// Join base part and variation
		let basePartMeasures = basePart.measures
		let variationMeasures = variationPart.measures

		guard variationMeasures.count == basePartMeasures.count else {
			fputs("Base part has \(variationMeasures.count) measures, base part has \(basePartMeasures.count)", stderr)
			exit(1)
		}


		// Make joint base/variation measures:
		destinationPart.measures = zip(basePartMeasures, variationMeasures).map { (baseMeasure, variationMeasure) -> Measure in
			let destinationMeasure = baseMeasure.copy()
			destinationMeasure.keepOnly(voice: baseVoice)
			destinationMeasure.overwriteNotesWithThoseFrom(variation: variationMeasure, voice: variationVoice)
			return destinationMeasure
		}

		if cut {
			// Remove variation voice from original part
			variationPart.measures.forEach { (measure) in
				measure.remove(voice: variationVoice)
			}
		}
		*/
		
	}
}


extension MuseScoreStaff {
	var identifierAsInt: Int? {
		guard let identifier = identifier else {
			return nil
		}
		return Int(identifier)
	}
}

extension MuseScoreDocument {
	func nextStaffIdentifier() -> String {
		if let maxID = staffs.compactMap({ $0.identifierAsInt }).max() {
			return "\(maxID + 1)"
		} else {
			return "1"
		}
	}
}
