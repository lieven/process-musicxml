//
//  MuseScoreDocument+ChapterMarkers.swift
//
//
//  Created by Lieven Dekeyser on 13/06/2024.
//

import Foundation


public struct ChapterMarker: Equatable {
	public let mark: String
	public let time: Double
}



extension MuseScoreDocument {
	public var chapterMarkers: [ChapterMarker]? {
		guard let firstStaff = self.firstStaff else {
			return nil
		}
	
		var tempo: Double = 2.0 // 2 beats per second = 120bpm
		var timeSignature = Fractional(numerator: 4, denominator: 4)
		
		var currentMeasureStartTime: Double = 0.0
		
		var results: [ChapterMarker] = []
		
		let flattenedMeasures = firstStaff.measures
			.flattenJumps()
			.flattenRepeats()
		
		for measure in flattenedMeasures {
			// Incomplete measures, e.g. at the start of a piece, can have a "len" attribute:
			// <Measure len="1/4">
			var measureLength = timeSignature
			if let measureLenAttribute = measure.element.getAttribute("len") {
				let components = measureLenAttribute.components(separatedBy: "/")
				if components.count == 2, let numerator = Int(components[0]), let denominator = Int(components[1]), denominator > 0 {
					measureLength = Fractional(numerator: numerator, denominator: denominator)
				}
			}
			
			var lastTempoChangeStartTime = currentMeasureStartTime
			var lastTempoChangeStartPosition = Fractional(numerator: 0, denominator: 4)
			// For fermatas and breaths
			var extraTimeSinceLastTempoChange = 0.0
		
			if let voiceElements = measure.voiceElements(voice: 0) {
				if let updatedTimeSig = voiceElements.first(where: { $0.timeSignature != nil })?.timeSignature {
					timeSignature = updatedTimeSig
				}
				
				var currentStretch: Double? = nil
				
				for voiceElement in voiceElements {
					if let timeStretch = voiceElement.timeStretch {
						currentStretch = timeStretch.factor
					} else if let stretch = currentStretch, let duration = voiceElement.duration {
						if duration.denominator > 0 {
							let elementDuration = 4.0 * Double(duration) / tempo
							let stretchedDuration = stretch * elementDuration
							extraTimeSinceLastTempoChange += stretchedDuration - elementDuration
						}
						currentStretch = nil
					}
					
					let timeSinceLastTempoChange = 4.0 * Double(voiceElement.position - lastTempoChangeStartPosition) / tempo
					
					

					
					if let updatedTempo = voiceElement.tempo {
						tempo = updatedTempo
						
						lastTempoChangeStartTime += timeSinceLastTempoChange + extraTimeSinceLastTempoChange
						lastTempoChangeStartPosition = voiceElement.position
						extraTimeSinceLastTempoChange = 0.0
						
					} else if let rehearsalMark = voiceElement.rehearsalMark {
						results.append(ChapterMarker(mark: rehearsalMark, time: lastTempoChangeStartTime + timeSinceLastTempoChange + extraTimeSinceLastTempoChange))
					} else if let breathPause = voiceElement.breathPause {
						extraTimeSinceLastTempoChange += breathPause
					}
				}
			}
			let measureEndTimeSinceLastTempoChange = 4.0 * Double(measureLength - lastTempoChangeStartPosition) / tempo
				
			currentMeasureStartTime = lastTempoChangeStartTime + measureEndTimeSinceLastTempoChange + extraTimeSinceLastTempoChange
		}
	
		return results
	}
}


extension XMLElement {
	/// only valid on voice elements
	var timeSignature: Double? {
		guard
			let timeSigElement = self.firstChild(name: "TimeSig"),
			let sigN = timeSigElement.firstChild(name: "sigN")?.doubleValue,
			let sigD = timeSigElement.firstChild(name: "sigD")?.doubleValue,
			sigD > 0.0
		else {
			return nil
		}
		return sigN / sigD
	}
}


extension XMLNode {
	var doubleValue: Double? {
		guard
			let stringValue = self.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
			let doubleValue = Double(stringValue)
		else {
			return nil
		}
		return doubleValue
	}
	
	var intValue: Int? {
		guard
			let stringValue = self.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
			let intValue = Int(stringValue)
		else {
			return nil
		}
		return intValue
	}
}

extension MuseScoreVoiceElement {
	var tempo: Double? {
		guard element.name == "Tempo", let tempo = element.firstChild(name: "tempo")?.doubleValue else {
			return nil
		}
		return tempo
	}
	
	var rehearsalMark: String? {
		guard element.name == "RehearsalMark", let rehearsalMark = element.getStringValue(child: "text") else {
			return nil
		}
		return rehearsalMark
	}
	
	var timeSignature: Fractional? {
		guard
			element.name == "TimeSig",
			let sigN = element.firstChild(name: "sigN")?.intValue,
			let sigD = element.firstChild(name: "sigD")?.intValue,
			sigD > 0
		else {
			return nil
		}
		return Fractional(numerator: sigN, denominator: sigD)
	}
	
	var breathPause: Double? {
		guard element.name == "Breath", let pause = element.firstChild(name: "pause")?.doubleValue else {
			return nil
		}
		return pause
	}
	
	var timeStretch: TimeStretch? {
		guard element.name == "Fermata" else {
			return nil
		}
		if let stretch = element.firstChild(name: "timeStretch")?.doubleValue, stretch > 0.0 {
			return TimeStretch.start(factor: stretch)
		} else {
			return TimeStretch.end
		}
	}
}

enum TimeStretch {
	case start(factor: Double)
	case end
	
	var factor: Double? {
		switch (self) {
		case .start(let factor):
			return factor
		case .end:
			return nil
		}
	}
}
