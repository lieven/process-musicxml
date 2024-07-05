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
		var timeSignature: Double = 1.0 // 4/4
		
		var currentTime: Double = 0.0
		
		var results: [ChapterMarker] = []
		
		let flattenedMeasures = firstStaff.measures.flattenRepeats()
		
		for measure in flattenedMeasures {
			var breathsDuration: Double = 0.0
			var fermataExtraDuration: Double = 0.0
		
			if let firstVoice = measure.voices.first {
				if let updatedTimeSig = firstVoice.timeSignature {
					timeSignature = updatedTimeSig
				}
				
				if let updatedTempo = firstVoice.tempo, updatedTempo > 0.0 {
					tempo = updatedTempo
				}
				
				if let rehearsalMark = firstVoice.rehearsalMark {
					results.append(ChapterMarker(mark: rehearsalMark, time: currentTime))
					print("\(currentTime) - marker \(rehearsalMark)")
				} else {
					print("\(currentTime) - no marker")
				}
				
				let breaths = firstVoice.children(name: "Breath")
				for breath in breaths {
					if let pause = breath.firstChild(name: "pause")?.doubleValue {
						breathsDuration += pause
					}
				}
			}
			
			if let voiceElements = measure.voiceElements(voice: 0) {
				var currentStretch: Double? = nil
				
				for voiceElement in voiceElements {
					if voiceElement.element.name == "Fermata" {
						if let stretch = voiceElement.element.firstChild(name: "timeStretch")?.doubleValue, stretch > 0.0 {
							currentStretch = stretch
						} else {
							currentStretch = nil
						}
					} else if let stretch = currentStretch, let duration = voiceElement.duration {
						if duration.denominator > 0 {
							let elementDuration = 4.0 * Double(duration) / tempo
							let stretchedDuration = stretch * elementDuration
							fermataExtraDuration += stretchedDuration - elementDuration
						}
						
						currentStretch = nil
					}
				}
			}
			
			let measureDuration = (4.0*timeSignature/tempo) + breathsDuration + fermataExtraDuration
			
			currentTime += measureDuration
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
	
	/// only valid on voice elements
	var tempo: Double? {
		guard
			let tempoElement = self.firstChild(name: "Tempo"),
			let tempo = tempoElement.firstChild(name: "tempo")?.doubleValue
		else {
			return nil
		}
		
		return tempo
	}
	
	var rehearsalMark: String? {
		guard
			let rehearsalMarkElement = self.firstChild(name: "RehearsalMark"),
			let rehearsalMark = rehearsalMarkElement.getStringValue(child: "text")
		else {
			return nil
		}
		return rehearsalMark
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
