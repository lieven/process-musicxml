//
//  Score+Transform.swift
//  ExplodeVoices
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

func which(_ command: String) -> String? {
	guard let result = execCommand("/usr/bin/which", args: [command]) else {
		fputs("which \(command) didn't terminate\n", stderr)
		return nil
	}
	
	guard result.code == 0 else {
		fputs("which \(command) failed: code = \(result.code)\n", stderr)
		if let stderrOutput = result.stderr {
			fputs(stderrOutput, stderr)
		}
		return nil
	}
	
	return result.stdout?.trimmingCharacters(in: .whitespacesAndNewlines)
}

func execCommand(_ command: String, args: [String]) -> (code: Int, stdout: String?, stderr: String?)? {
	let stdoutPipe = Pipe()
	let stderrPipe = Pipe()
	
	let proc = Process()
	proc.launchPath = command
	proc.arguments = args
	
	proc.standardOutput = stdoutPipe
	proc.standardError = stderrPipe
	proc.launch()
	
	let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
	let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
	
	proc.waitUntilExit()
	
	guard !proc.isRunning else {
		return nil
	}
	
	return (code: Int(proc.terminationStatus), stdout: String(data: stdoutData, encoding: .utf8), stderr: String(data: stderrData, encoding: .utf8))
}



extension Score {
	static func transform(inputURL: URL, outputURL: URL, action: (Score) -> Void) {
		let inputMusicXML: URL
		let outputMusicXML: URL
		
		let inputExtension = inputURL.pathExtension.lowercased()
		if inputExtension == "mscz" {
			let tempMusicXML = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("ExplodeVoicesInput-\(UUID().uuidString).xml")
			
			guard let mscore = which("mscore") else {
				fputs("mscore not found\n", stderr)
				exit(1)
			}
			
			guard let exportResult = execCommand(mscore, args: [ inputURL.path, "-o", tempMusicXML.path ]) else {
				fputs("Export to MusicXML \(tempMusicXML.path) failed\n", stderr)
				exit(1)
			}
			
			guard exportResult.code == 0 else {
				fputs("Export to MusicXML failed\n", stderr)
				if let stderrOutput = exportResult.stderr {
					fputs(stderrOutput, stderr)
				}
				exit(1)
			}
			
			
			inputMusicXML = tempMusicXML
		} else {
			inputMusicXML = inputURL
		}
		
		let outputExtension = outputURL.pathExtension.lowercased()
		if outputExtension == "mscz" {
			outputMusicXML = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("ExplodeVoicesOutput-\(UUID().uuidString).xml")
		} else {
			outputMusicXML = outputURL
		}
		
		
		transform(inputMusicXML: inputMusicXML, outputMusicXML: outputMusicXML, action: action)
		
		if outputExtension == "mscz" {
			guard let mscore = which("mscore") else {
				fputs("mscore not found\n", stderr)
				exit(1)
			}
			
			guard let exportResult = execCommand(mscore, args: [ outputMusicXML.path, "-o", outputURL.path ]) else {
				fputs("Export to MuseScore failed\n", stderr)
				exit(1)
			}
			
			guard exportResult.code == 0 else {
				fputs("Export to MuseScore failed\n", stderr)
				if let stderrOutput = exportResult.stderr {
					fputs(stderrOutput, stderr)
				}
				exit(1)
			}
		}
	}
	
	static func transform(inputMusicXML inputURL: URL, outputMusicXML outputURL: URL, action: (Score) -> Void) {
		let xmlDocument: XMLDocument

		do {
			xmlDocument = try XMLDocument(contentsOf: inputURL, options: [])
		} catch {
			fputs("Could not read XML document: \(error)\n", stderr)
			exit(1)
		}

		guard let score = Score(document: xmlDocument) else {
			fputs("Could not parse score\n", stderr)
			exit(1)
		}
		
		action(score)
		
		guard let resultDocument = score.resultDocument else {
			fputs("No result document", stderr)
			exit(1)
		}

		let xmlData = resultDocument.xmlData(options: [.nodePrettyPrint])
		do {
			try xmlData.write(to: outputURL)
		} catch {
			fputs("Could not write XML data: \(error)\n", stderr)
			exit(1)
		}
	}
}
