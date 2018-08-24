//
//  Score+ExtractVariation.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation


extension Score {

	func extractVariation(basePartID: String, baseVoice: String, variationPartID: String, variationVoice: String, cut: Bool, destinationPartName: String) {
		let partIDsAndNames: [(String, String)] = partList.compactMap {
			switch $0 {
				case .part(let part):
					return (part.metadata.identifier, part.metadata.name)
				case .other:
					return nil
			}
		}
		
		let partIDsString = partIDsAndNames.map { "- \($0.0): \($0.1)" }.joined(separator: "\n")
		
		guard let basePart = part(identifier: basePartID) else {
			printUsage(errorMessage: "No such base part: \(basePartID):\n\(partIDsString)")
			exit(1)
		}

		guard let variationPart = part(identifier: variationPartID) else {
			printUsage(errorMessage: "No such variation part: \(variationPartID):\n\(partIDsString)")
			exit(1)
		}
		
		extractVariation(basePart: basePart, baseVoice: baseVoice, variationPart: variationPart, variationVoice: variationVoice, cut: cut, destinationPartName: destinationPartName)
	}
	
	func extractVariation(basePart: Part, baseVoice: String, variationPart: Part, variationVoice: String, cut: Bool, destinationPartName: String) {

		let idSuffix = "-copy"
		let destinationPartID = basePart.metadata.identifier.appending(idSuffix)

		// MARK: - Duplicate base part list element and set new part name

		guard let destinationPartMetadata = PartListElement(element: basePart.metadata.element) else {
			fputs("Could not copy part list element\n", stderr)
			exit(1)
		}

		destinationPartMetadata.name = destinationPartName
		destinationPartMetadata.identifier = destinationPartID

		let destinationPart = Part(metadata: destinationPartMetadata)
		add(part: destinationPart, after: basePart)



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
	}
}
