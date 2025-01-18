//
//  MuseScoreMeasure.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 15/09/2018.
//

import Foundation

extension Array {
	subscript (safe index: Int) -> Element? {
		guard index >= 0, index < count else {
			return nil
		}
		return self[index]
	}
}

enum MuseScoreDurationType: String {
	case measure
	case whole
	case half
	case quarter
	case eighth
	case sixteenth = "16th"
	
	var fraction: Fractional {
		switch self {
		case .measure:
			return 1/1 // TODO: check this
		case .whole:
			return 1/1
		case .half:
			return 1/2
		case .quarter:
			return 1/4
		case .eighth:
			return 1/8
		case .sixteenth:
			return 1/16
		}
	}
}

extension String {
	var fraction: Fractional? {
		let durationComponents = self.components(separatedBy: "/")
		guard durationComponents.count == 2 else {
			return nil
		}
		
		guard let numerator = Int(durationComponents[0]), let denominator = Int(durationComponents[1]) else {
			return nil
		}
		
		return Fractional(numerator: numerator, denominator: denominator)
	}
}

extension XMLElement {
	var durationTypeString: String? {
		return getStringValue(child: "durationType")
	}
	
	var durationType: MuseScoreDurationType? {
		guard let durationTypeString = durationTypeString else {
			return nil
		}
		
		return MuseScoreDurationType(rawValue: durationTypeString)
	}
	
	var dotsString: String? {
		return getStringValue(child: "dots")
	}
	
	var dots: Int? {
		guard let dotsString = dotsString else {
			return nil
		}
		return Int(dotsString)
	}
	
	var dotsFactor: Fractional? {
		guard let dots = dots else {
			return nil
		}
		
		var factor: Fractional = 1 / 2
		
		var result: Fractional = 1
		for _ in [0..<dots] {
			result += factor
			
			factor /= 2
		}
		return result
		
	}
	
	var durationString: String? {
		return getStringValue(child: "duration") 
	}
	
	public var durationFraction: Fractional? {
		guard let durationString = durationString else {
			guard let durationTypeFraction = durationType?.fraction else {
				return nil
			}
			
			if let dotsFactor = dotsFactor {
				return durationTypeFraction * dotsFactor
			} else {
				return durationTypeFraction
			}
		}
		return durationString.fraction
	}
	
	var locationDuration: Fractional? {
		guard name == "location" else {
			return nil
		}
	
		return elements(forName: "fractions").first?.stringValue?.fraction
	}
	
	var tupletFactor: Fractional? {
		guard
			let name = self.name, name == "Tuplet",
			let normalNotesString = self.firstChild(name: "normalNotes")?.stringValue,
			let normalNotes = Int(normalNotesString),
			normalNotes > 0,
			let actualNotesString = self.firstChild(name: "actualNotes")?.stringValue,
			let actualNotes = Int(actualNotesString),
			actualNotes > 0
		else {
			return nil
		}
		return Fractional(numerator: normalNotes, denominator: actualNotes)
	}
}



public class MuseScoreVoiceElement {
	public let element: XMLElement
	public let position: Fractional
	public let duration: Fractional?
	public let positionEnd: Fractional
	
	required public init(element: XMLElement, position: Fractional, tupletFactor: Fractional) {
		self.element = element
		self.position = position
		if let duration = element.durationFraction {
			self.duration = duration * tupletFactor
			self.positionEnd = self.position + duration
		} else {
			self.duration = nil
			self.positionEnd = self.position
		}
	}
	
	func overlaps(with otherElement: MuseScoreVoiceElement) -> Bool {
		if self.element.tupletFactor != nil, otherElement.element.tupletFactor != nil, self.position == otherElement.position {
			return true
		}
		
		return position < otherElement.positionEnd
			&& otherElement.position < positionEnd
	}
	
	func overlaps(with elements: [MuseScoreVoiceElement]) -> Bool {
		for otherElement in elements {
			if overlaps(with: otherElement) {
				return true
			}
		}
		return false
	}
}

extension Array where Element == MuseScoreVoiceElement {
	var voiceElement: XMLElement {
		let result = XMLElement(name: "voice")
		
		let sortedElements = self.sorted { (lhs, rhs) -> Bool in
			return lhs.position < rhs.position
		}
		
		var position = Fractional(0)
		for element in sortedElements {
			let diff = element.position - position
			if diff.magnitude > 0 {
				let locationElement = XMLElement(name: "location")
				let fractionsElement = XMLElement(name: "fractions")
				fractionsElement.stringValue = "\(diff.numerator)/\(diff.denominator)"
				locationElement.addChild(fractionsElement)
				result.addChild(locationElement)
				position += diff
			}
			
			if let elementCopy = element.element.copy() as? XMLElement {
				result.addChild(elementCopy)
			}
			if let duration = element.duration {
				position += duration
			}
		}
		
		return result
	}
}


public class MuseScoreMeasure: ManagedXMLElement {
	public let element: XMLElement
	
	required public init?(element: XMLElement) {
		guard element.name == "Measure" else {
			return nil
		}
		self.element = element
	}
	
	var voices: [XMLElement] {
		return element.elements(forName: "voice")
	}
}

extension MuseScoreMeasure {
	func remove(voice: Int) {
		let voices = self.voices
		guard voice >= 0, voice < voices.count else {
			return
		}
		
		voices[voice].detach()
	}
	
	func keepOnly(voice: Int) {
		let voices = self.voices
		for i in 0..<voices.count {
			if i != voice {
				voices[i].detach()
			}
		}
	}
	
	func voiceElements(voice: Int) -> [MuseScoreVoiceElement]? {
		guard let voiceElement = voices[safe: voice] else {
			return nil
		}
		
		let childNodes = voiceElement.children ?? []
		
		var position = Fractional(0)
		var tupletFactors = [Fractional(1)]

		let voiceElements: [MuseScoreVoiceElement] = childNodes.compactMap { node in
			guard let element = node as? XMLElement else {
				return nil
			}
			
			let currentTupletFactor = tupletFactors.last ?? Fractional(1)
			
			if let locationDuration = element.locationDuration {
				position += currentTupletFactor * locationDuration
				return nil
			}
			
			if let newTupletFactor = element.tupletFactor {
				tupletFactors.append(newTupletFactor)
			} else if element.name == "endTuplet" {
				if tupletFactors.count > 1 {
					tupletFactors.removeLast()
				} else {
					print("Warning: endTuplet without start")
				}
			}
			
			let result = MuseScoreVoiceElement(element: element, position: position, tupletFactor: currentTupletFactor)
			if let duration = result.duration {
				position += duration
			}
			
			return result
		}
		
		return voiceElements
	}
	
	func overwriteNotesWithThoseFrom(variation: MuseScoreMeasure, voice: Int) {
		guard
			let destinationVoiceElement = voices.first,
			let ownVoiceElements = voiceElements(voice: 0),
			let variationVoiceElements = variation.voiceElements(voice: voice)
		else {
			return
		}
			
		
		var remainingElements = ownVoiceElements.filter { !$0.overlaps(with: variationVoiceElements) }
		remainingElements.append(contentsOf: variationVoiceElements)
		
		element.replaceChild(at: destinationVoiceElement.index, with: remainingElements.voiceElement)
	}
}

extension Array where Element == MuseScoreMeasure {
	
	func flattenRepeats() -> [MuseScoreMeasure] {
		var results: [MuseScoreMeasure] = []
		
		var i = 0
		let n = self.count
		
		var currentStartRepeat: Int? = 0
		var currentIteration: Int = 0
		var currentRepeatCount: Int? = nil
		
		while i < n {
			let measure = self[i]
			
			if (currentStartRepeat == nil || currentStartRepeat == 0), measure.element.firstChild(name: "startRepeat") != nil {
				currentStartRepeat = i
				currentIteration = 0
			}
			
			results.append(measure)
			
			if let startRepeat = currentStartRepeat {
				if let endRepeatElement = measure.element.firstChild(name: "endRepeat") {
					if currentRepeatCount == nil {
						let repeatCount = endRepeatElement.intValue ?? 2
						currentRepeatCount = repeatCount
						currentIteration = 1
					}
					
					if let repeatCount = currentRepeatCount, currentIteration < repeatCount {
						i = startRepeat
						currentIteration += 1
						continue
					} else {
						currentStartRepeat = nil
						currentRepeatCount = nil
					}
				}
			}
			
			i += 1
		}
		
		return results
	}
	
	private var labelToMeasureIndex: [String: Int] {
		var labelToMeasureIndex: [String: Int] = [:]
		
		var measureIndex = 0
		for measure in self {
			if let markerElement = measure.element.firstChild(name: "Marker"), let label = markerElement.getStringValue(child: "label") {
				/*
				<Marker>
					<style>Repeat Text Right</style>
					<text>To Coda</text>
					<label>coda</label>
				</Marker>
				 */
				labelToMeasureIndex[label] = measureIndex
			}
			
			measureIndex += 1
		}
		
		return labelToMeasureIndex
	}
	
	func flattenJumps() -> [MuseScoreMeasure] {
		let labelToMeasureIndex = self.labelToMeasureIndex
		
		var measureIndex = 0
		
		var currentJump: (playUntil: Int, continueAt: Int)?
		
		let numMeasures = self.count
		
		var results: [MuseScoreMeasure] = []
		
		while measureIndex < numMeasures {
			let measure = self[measureIndex]
			
			if let jump = currentJump, measureIndex > jump.playUntil {
				measureIndex = jump.continueAt
				currentJump = nil
				continue
			}
			
			results.append(measure)
			
			if currentJump == nil, let jumpElement = measure.element.firstChild(name: "Jump"), let jumpToMarker = jumpElement.getStringValue(child: "jumpTo"), let jumpTo = labelToMeasureIndex[jumpToMarker] {
				
				/*
				<Jump>
					<style>Repeat Text Right</style>
					<text>D.S. al Coda</text>
					<jumpTo>segno</jumpTo>
					<playUntil>coda</playUntil>
					<continueAt>codab</continueAt>
				</Jump>
				 */
				
				let playUntil: Int
				if let playUntilMarker = jumpElement.getStringValue(child: "playUntil"), let playUntilIndex = labelToMeasureIndex[playUntilMarker] {
					playUntil = playUntilIndex
				} else {
					playUntil = measureIndex + 1
				}
				
				let continueAt: Int
				if let continueAtMarker = jumpElement.getStringValue(child: "continueAt"), let continueAtIndex = labelToMeasureIndex[continueAtMarker] {
					continueAt = continueAtIndex
				} else {
					continueAt = measureIndex + 1
				}
				
				currentJump = (playUntil: playUntil, continueAt: continueAt)
				
				measureIndex = jumpTo
				
				continue
			}
			
			measureIndex += 1
		}
		
		return results
	}
	
}
