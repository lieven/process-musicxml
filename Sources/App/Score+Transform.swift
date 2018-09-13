//
//  Score+Transform.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation
import ProcessMusicXML
import ProcessMuseScore


extension Score {

	public convenience init?(musicXMLFile: URL) throws {
		self.init(document: try XMLDocument(contentsOf: musicXMLFile, options: []))
	}
	
	public convenience init?(inputFile: URL) throws {
		try self.init(musicXMLFile: MuseScore.convertToMusicXMLIfNeeded(inputFile: inputFile))
	}
	
	public func export(outputFile: URL) {
		guard let resultDocument = resultDocument else {
			fputs("No result document", stderr)
			exit(1)
		}
		
		let outputMusicXML: URL
		let outputExtension = outputFile.pathExtension.lowercased()
		if outputExtension != "xml" {
			outputMusicXML = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("MusicXMLOutput-\(UUID().uuidString).xml")
		} else {
			outputMusicXML = outputFile
		}
		
		let xmlData = resultDocument.xmlData(options: [.nodePrettyPrint])
		do {
			try xmlData.write(to: outputMusicXML)
		} catch {
			fputs("Could not write XML data: \(error)\n", stderr)
			exit(1)
		}
		
		if outputExtension != "xml" {
			MuseScore.convert(musicXMLFile: outputMusicXML, outputFile: outputFile)
		}
	}
	
	public static func transform(inputURL: URL, outputURL: URL, action: (Score) throws -> Void) {
		do {
			guard let score = try Score(inputFile: inputURL) else {
				fputs("Could not parse score\n", stderr)
				exit(1)
			}
			
			try action(score)
			
			score.export(outputFile: outputURL)
		} catch {
			fputs("Could not read XML document: \(error)\n", stderr)
			exit(1)
		}
	}
	
}
