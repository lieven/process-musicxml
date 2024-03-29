//
//  MuseScoreDocument+Choir.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 16/08/2019.
//

import Foundation

public enum ChoirVoice: CaseIterable {
	case soprano
	case mezzoSoprano
	case mezzoAlto
	case alto
	case women
	case tenor
	case bariTenor
	case bariBass
	case bass
	case men
	case highVoices
	case lowVoices
	case solo
}

extension ChoirVoice {
	public var names: [String] {
		switch self {
		case .soprano:
			return ["sopraan", "soprano"]
		case .mezzoSoprano:
			return ["mezzo-sopraan", "mezzo-soprano"]
		case .mezzoAlto:
			return ["mezzo-alt", "mezzo-alto"]
		case .alto:
			return ["alt", "alto"]
		case .women:
			return ["women", "vrouwen", "sopraan/alt", "sopraan\nalt", "soprano/alto", "soprano\nalto"]
		case .tenor:
			return ["tenor"]
		case .bariTenor:
			return ["bari-tenor"]
		case .bariBass:
			return ["bari-bass", "bari-bas"]
		case .bass:
			return ["bass", "bas"]
		case .men:
			return ["men", "mannen", "tenor/bas", "tenor\nbas", "tenor/bass", "tenor\nbass"]
		case .highVoices:
			return ["sopraan/tenor", "sopraan\ntenor"]
		case .lowVoices:
			return ["alt/bas", "alt\nbas"]
		case .solo:
			return ["solo"]
		}
	}
}

public struct PartName {
	let long: String
	let short: String
	
	static let soprano = PartName(long: "Sopraan", short: "S.")
	static let alto = PartName(long: "Alt", short: "A.")
	static let tenor = PartName(long: "Tenor", short: "T.")
	static let bass = PartName(long: "Bas", short: "B.")
	
	static let mezzoSoprano = PartName(long: "Mezzo-Sopraan", short: "M.S.")
	static let mezzoAlto = PartName(long: "Mezzo-Alt", short: "M.A.")
	
	static let bariTenor = PartName(long: "Bari-Tenor", short: "B.T.")
	static let bariBass = PartName(long: "Bari-Bas", short: "B.B.")
}

public extension MuseScorePart {
	var partName: PartName? {
		get {
			guard let name = name ?? longInstrumentName else {
				return nil
			}
			
			return PartName(long: name, short: shortInstrumentName ?? name)
		}
		set {
			name = newValue?.long
			longInstrumentName = newValue?.long
			shortInstrumentName = newValue?.short
		}
	}
}

public extension MuseScoreDocument {
	func extractChoirVariations() {
		if let soprano = choirPart(.soprano), let alto = choirPart(.alto) {
			extractMezzos(soprano: soprano, alto: alto)
		} else if let women = choirPart(.women) {
			splitWomen(part: women)
		}
		
		if let tenor = choirPart(.tenor), let bass = choirPart(.bass) {
			extractBaritones(tenor: tenor, bass: bass)
		} else if let men = choirPart(.men) {
			splitMen(part: men)
		}
	}

	func choirPart(_ voice: ChoirVoice) -> MuseScorePart? {
		return partWithName(in: voice.names)
	}
	
	func choirStaff(_ voice: ChoirVoice) -> MuseScoreStaff? {
		guard let staffIDs = choirPart(voice)?.staffIDs, staffIDs.count == 1, let staffID = staffIDs.first else {
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
		let sopranoStaffs = staffs(part: soprano)
		let altoStaffs = staffs(part: alto)
		
		guard sopranoStaffs.count == 1, altoStaffs.count == 1, let sopranoStaff = sopranoStaffs.first, let altoStaff = altoStaffs.first else {
			return
		}
		
		if sopranoStaff.voiceCount >= 2 {
			if altoStaff.voiceCount >= 2 {
				extractVariation(basePart: soprano, baseVoice: 0, variationPart: soprano, variationVoice: 1, cut: true, destinationPartName: .mezzoSoprano)
				extractVariation(basePart: alto, baseVoice: 0, variationPart: alto, variationVoice: 1, cut: true, destinationPartName: .mezzoAlto)
			} else {
				extractVariation(basePart: soprano, baseVoice: 0, variationPart: soprano, variationVoice: 1, cut: true, destinationPartName: .mezzoSoprano)
			}
		} else if altoStaff.voiceCount >= 2 {
			extractVariation(basePart: alto, baseVoice: 0, variationPart: alto, variationVoice: 1, cut: false, destinationPartName: .mezzoAlto)
			extractVariation(basePart: soprano, baseVoice: 0, variationPart: alto, variationVoice: 1, cut: true, destinationPartName: .mezzoSoprano)
		}
	}
	
	func extractBaritones(tenor: MuseScorePart, bass: MuseScorePart) {
		let tenorStaffs = staffs(part: tenor)
		let bassStaffs = staffs(part: bass)
		
		guard tenorStaffs.count == 1, bassStaffs.count == 1, let tenorStaff = tenorStaffs.first, let bassStaff = bassStaffs.first else {
			return
		}
	
		if tenorStaff.voiceCount >= 2 {
			if bassStaff.voiceCount >= 2 {
				extractVariation(basePart: tenor, baseVoice: 0, variationPart: tenor, variationVoice: 1, cut: true, destinationPartName: .bariTenor)
				extractVariation(basePart: bass, baseVoice: 0, variationPart: bass, variationVoice: 1, cut: true, destinationPartName: .bariBass)
			} else {
				extractVariation(basePart: tenor, baseVoice: 0, variationPart: tenor, variationVoice: 1, cut: true, destinationPartName: .bariTenor)
			}
		} else if bassStaff.voiceCount >= 2 {
			extractVariation(basePart: bass, baseVoice: 0, variationPart: bass, variationVoice: 1, cut: false, destinationPartName: .bariBass)
			extractVariation(basePart: tenor, baseVoice: 0, variationPart: bass, variationVoice: 1, cut: true, destinationPartName: .bariTenor)
		}
	}
	
	
	func splitWomen(part: MuseScorePart) {
		split(part: part, firstPartName: .soprano, secondPartName: .alto)
	}
	
	func splitMen(part: MuseScorePart) {
		split(part: part, firstPartName: .tenor, secondPartName: .bass)
	}
	
	func split(part: MuseScorePart, firstPartName: PartName, secondPartName: PartName) {
		let staffs = staffs(part: part)
		
		guard staffs.count == 1, let staff = staffs.first, staff.voiceCount >= 2 else {
			return
		}
		extractVariation(basePart: part, baseVoice: 0, variationPart: part, variationVoice: 1, cut: true, destinationPartName: secondPartName)
		part.partName = firstPartName
	}
	
	
	func extractVariation(basePart: MuseScorePart, baseVoice: Int, variationPart: MuseScorePart, variationVoice: Int, cut: Bool, destinationPartName: PartName) {
		let baseStaffs = staffs(part: basePart)
		let variationStaffs = staffs(part: variationPart)
		
		// MARK: - Duplicate base part and create new staff
		guard baseStaffs.count == 1, variationStaffs.count == 1, let baseStaff = baseStaffs.first, let variationStaff = variationStaffs.first else {
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
		
		destinationPart.staffIDs = [destinationStaffID]
		destinationPart.partName = destinationPartName
		
		addPart(destinationPart, staff: destinationStaff, after: basePart)
		
		
		// Join base part and variation
		let baseMeasures = baseStaff.measures
		let variationMeasures = variationStaff.measures

		guard variationMeasures.count == baseMeasures.count else {
			fputs("Variation part has \(variationMeasures.count) measures, base part has \(baseMeasures.count)", stderr)
			exit(1)
		}
		
		// Make joint base/variation measures:
		destinationStaff.measures = zip(baseMeasures, variationMeasures).compactMap { (baseMeasure, variationMeasure) -> MuseScoreMeasure? in
			guard let destinationMeasure = MuseScoreMeasure(copy: baseMeasure) else {
				return nil
			}
			destinationMeasure.keepOnly(voice: baseVoice)
			destinationMeasure.overwriteNotesWithThoseFrom(variation: variationMeasure, voice: variationVoice)
			return destinationMeasure
		}

		if cut {
			// Remove variation voice from original part
			baseMeasures.forEach { (measure) in
				measure.remove(voice: variationVoice)
			}
		}
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
