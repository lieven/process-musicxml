//
//  MuseScore.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

func which(_ command: String) -> String? {
	let result = execCommand("/usr/bin/which", args: [command])
	guard result.code == 0 else {
		fputs("which \(command) failed: code = \(result.code)\n", stderr)
		if let stderrOutput = result.stderr {
			fputs(stderrOutput, stderr)
		}
		return nil
	}
	
	guard let trimmedResult = result.stdout?.trimmingCharacters(in: .whitespacesAndNewlines), trimmedResult.count > 0 else {
		return nil
	}
	
	return trimmedResult
}

func execCommand(_ command: String, args: [String], stdout: Bool = true, stderr: Bool = true) -> (code: Int, stdout: String?, stderr: String?) {
	let stdoutPipe = Pipe()
	let stderrPipe = Pipe()
	
	let proc = Process()
	proc.launchPath = command
	proc.arguments = args
	
	proc.standardOutput = stdoutPipe
	proc.standardError = stderrPipe
	proc.launch()
	
	var stdoutData = Data()
	stdoutPipe.fileHandleForReading.readabilityHandler = { (stdoutHandle) in
		stdoutData.append(stdoutHandle.availableData)
	}
	var stderrData = Data()
	stderrPipe.fileHandleForReading.readabilityHandler = { (stderrHandle) in
		stderrData.append(stderrHandle.availableData)
	}
	
	proc.waitUntilExit()
	
	stdoutPipe.fileHandleForReading.readabilityHandler = nil
	stderrPipe.fileHandleForReading.readabilityHandler = nil
	
	return (code: Int(proc.terminationStatus), stdout: String(data: stdoutData, encoding: .utf8), stderr: String(data: stderrData, encoding: .utf8))
}

public class MuseScore {

	private static var command: String = {
		return which("mscore") ?? "/Applications/MuseScore 2.app/Contents/MacOS/mscore"
	}()
	
	public static func convertToMusicXMLIfNeeded(inputFile: URL) -> URL {
		guard inputFile.pathExtension.lowercased() == "mscz" else {
			return inputFile
		}
		let tempMusicXML = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("MusicXMLInput-\(UUID().uuidString).xml")
		MuseScore.convertToMusicXML(museScoreFile: inputFile, outputFile: tempMusicXML)
		return tempMusicXML
	}
	
	public static func convertToMusicXML(museScoreFile: URL, outputFile: URL) {
		let exportResult = execCommand(MuseScore.command, args: [ museScoreFile.path, "-o", outputFile.path ])
		guard exportResult.code == 0 else {
			fputs("Convert to MusicXML failed\n", stderr)
			if let stderrOutput = exportResult.stderr {
				fputs(stderrOutput, stderr)
			}
			exit(1)
		}
	}

	public static func convert(musicXMLFile: URL, outputFile: URL) {
		let exportResult = execCommand(MuseScore.command, args: [ musicXMLFile.path, "-o", outputFile.path ])
		guard exportResult.code == 0 else {
			fputs("Export to MuseScore failed\n", stderr)
			if let stderrOutput = exportResult.stderr {
				fputs(stderrOutput, stderr)
			}
			exit(1)
		}
	}
}

