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



public class MuseScoreFile {
	public let document: MuseScoreDocument
	let url: URL
	let archive: Archive?
	let entry: Entry?

	public init?(url: URL) throws {
		self.url = url
		
		guard let type = MuseScoreFileType(rawValue: url.pathExtension) else {
			return nil
		}
		
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
	
	private var xmlData: Data {
		return document.xmlDocument.xmlData(options: [.nodePreserveAll])
	}
	
	public func save() throws {
	
		if let archive = archive, let entry = entry {
			try archive.replace(entry: entry, with: xmlData)
		} else {
			try save(to: url)
		}
	}
	
	public func save(to url: URL) throws {
		try xmlData.write(to: url)
	}
}

extension Archive {
	func replace(entry: Entry, with data: Data) throws {
		guard entry.type == .file else {
			return // TODO: error handling
		}
		let path = entry.path

		try remove(entry)

		let dataProvider: Provider = { (position, size) in
			return data.subdata(in: position..<(position+size))
		}

		try addEntry(with: path, type: .file, uncompressedSize: UInt32(data.count), compressionMethod: .deflate, provider: dataProvider)
	}
}
