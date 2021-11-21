//
//  MuseScoreFile.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 07/09/2018.
//

import Foundation
import ZIPFoundation

enum MuseScoreFileType: String {
	case mscx
	case mscz
}

extension MuseScoreFileType {
	func loadXMLDocument(from url: URL) throws -> (XMLDocument, Archive?, Entry?)? {
		switch self {
		case .mscx:
			return (try loadMSCX(url: url), nil, nil)
		case .mscz:
			guard let (archive, entry, xmlDocument) = try loadMSCZ(url: url) else {
				return nil
			}
			return (xmlDocument, archive, entry)
		}
	}
	
	private func loadMSCX(url: URL) throws -> XMLDocument {
		return try XMLDocument(contentsOf: url, options: [.nodePreserveAll])
	}
	
	private func loadMSCZ(url: URL) throws -> (Archive, Entry, XMLDocument)? {
		// open archive
		guard let archive = Archive(url: url, accessMode: .update) else {
			return nil
		}
		guard let entry = archive.makeIterator().first(where: { $0.path.hasSuffix(".mscx") }) else {
			return nil
		}
		
		var mscxData = Data()
		_ = try archive.extract(entry) { (chunk) in
			mscxData.append(chunk)
		}
		
		return (archive, entry, try XMLDocument(data: mscxData, options: [.nodePreserveAll]))
	}
}

enum ExportError: Error {
	case xml
	case unknownFileType
	case notImplemented
	case overwrite
	case zip
}

public class MuseScoreFile {
	public let document: MuseScoreDocument
	let url: URL
	let type: MuseScoreFileType
	let archive: Archive?
	let entry: Entry?

	public init?(url: URL) throws {
		self.url = url
		
		guard let type = MuseScoreFileType(rawValue: url.pathExtension) else {
			return nil
		}
		
		self.type = type
		
		guard let (xmlDocument, archive, entry) = try type.loadXMLDocument(from: url) else {
			return nil
		}
		
		guard let document = MuseScoreDocument(document: xmlDocument) else {
			return nil
		}
		self.document = document
		self.archive = archive
		self.entry = entry
	}
	
	private func resultData() throws -> Data {
		return document.document.xmlData(options: [.nodePreserveAll])
	}
	
	public func save() throws {
		if let archive = archive, let entry = entry {
			try archive.replace(entry: entry, with: try resultData())
		} else {
			try writeXML(to: url)
		}
	}
	
	public func export(to destinationURL: URL) throws {
		guard let destinationType = MuseScoreFileType(rawValue: destinationURL.pathExtension) else {
			throw ExportError.unknownFileType
		}
		
		guard url != destinationURL else {
			throw ExportError.overwrite
		}
		
		switch destinationType {
		case .mscx:
			try writeXML(to: destinationURL)
		case .mscz:
			let data = try resultData()
				
			switch type {
			case .mscz:
				// copy existing archive and replace entry
				let fm = FileManager.default
				if fm.fileExists(atPath: destinationURL.path) {
					try fm.removeItem(at: destinationURL)
				}
				
				try fm.copyItem(at: self.url, to: destinationURL)
				
				guard let (_, archive, entry) = try destinationType.loadXMLDocument(from: destinationURL), let destinationArchive = archive, let destinationEntry = entry else {
					throw ExportError.xml
				}
				
				try destinationArchive.replace(entry: destinationEntry, with: data)
			case .mscx:
				let tempURL = destinationURL.deletingPathExtension().appendingPathExtension("tmp")
				let fm = FileManager.default
				if fm.fileExists(atPath: tempURL.path) {
					try fm.removeItem(at: tempURL)
				}
				
				try write(xmlData: data, toNewArchive: tempURL)
				
				try? fm.removeItem(at: destinationURL)
				try fm.moveItem(at: tempURL, to: destinationURL)
			}
		}
	
	}
	
	private func writeXML(to destinationURL: URL) throws {
		let data = try resultData()
		try data.write(to: destinationURL)
	}
	
	private func write(xmlData data: Data, toNewArchive destinationURL: URL) throws {
		// create a new archive with the mscx file + a container describing where it is
		guard let newArchive = Archive(url: destinationURL, accessMode: .create) else {
			throw ExportError.zip
		}
		
		let fileName = destinationURL.deletingPathExtension().lastPathComponent.appending(".mscx")
		let dataProvider: Provider = { (position, size) in
			return data.subdata(in: position..<(position+size))
		}
		
		try newArchive.addEntry(with: fileName, type: .file, uncompressedSize: UInt32(data.count), compressionMethod: .deflate, provider: dataProvider)
		
		try newArchive.addDirectory(path: "META-INF")
		
		guard let containerXMLDocument = XMLDocument.container(rootFilePath: fileName) else {
			throw ExportError.xml
		}
		
		let containerXMLData = containerXMLDocument.xmlData(options: [.nodePrettyPrint])
		try newArchive.addFile(path: "META-INF/container.xml", data: containerXMLData)
	}
}

extension XMLDocument {
	static func container(rootFilePath: String) -> XMLDocument? {
		let containerElement = XMLElement(name: "container")	
		let rootFilesElement = XMLElement(name: "rootfiles")
		let fileElement = XMLElement(name: "rootfile")
		
		let document = XMLDocument(rootElement: containerElement)
		document.characterEncoding = "UTF-8"
		containerElement.addChild(rootFilesElement)
		rootFilesElement.addChild(fileElement)
		
		fileElement.setAttributesWith(["full-path": rootFilePath])
		
		return document
	}
}

extension Archive {
	func replace(entry: Entry, with data: Data) throws {
		guard entry.type == .file else {
			throw ExportError.zip
		}
		let path = entry.path

		try remove(entry)
		
		try addFile(path: path, data: data)
	}
	
	func addFile(path: String, data: Data) throws {
		let dataProvider: Provider = { (position, size) in
			return data.subdata(in: position..<(position+size))
		}

		try addEntry(with: path, type: .file, uncompressedSize: UInt32(data.count), compressionMethod: .deflate, provider: dataProvider)
	}
	
	func addDirectory(path: String) throws {
		let provider: Provider = { _, _ in return Data() }
		let pathWithSuffix = path.hasSuffix("/") ? path : path + "/"
		try self.addEntry(with: pathWithSuffix, type: .directory, uncompressedSize: 0, compressionMethod: .none, provider: provider)
	}
}
