//
//  MuseScoreDocument.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 06/09/2018.
//

import Foundation
import ProcessMusicXML



public class MuseScoreDocument {
	let document: XMLDocument
	
	let scoreElement: XMLElement
	public private(set) var parts: [MuseScorePart]
	public private(set) var staffs: [MuseScoreStaff]
	
	init?(document: XMLDocument) {
		guard let rootElement = document.rootElement(), rootElement.name == "museScore" else {
			return nil
		}
		
		// TODO: version check: <museScore version="2.06">
		
		guard let scoreElement = rootElement.elements(forName: "Score").first else {
			return nil
		}
		
		self.document = document
		self.scoreElement = scoreElement
		self.parts = scoreElement.elements(forName: "Part").compactMap { MuseScorePart(element: $0) }
		self.staffs = scoreElement.elements(forName: "Staff").compactMap { MuseScoreStaff(element: $0) }
	}
	
	func staff(identifier: String) -> MuseScoreStaff? {
		return staffs.first { $0.identifier == identifier }
	}
	
	func staff(part: MuseScorePart) -> MuseScoreStaff? {
		guard let staffID = part.staffIDs.first else {
			return nil
		}
		return staff(identifier: staffID)
	}
	
	func staffs(part: MuseScorePart) -> [MuseScoreStaff] {
		return part.staffIDs.compactMap { staff(identifier: $0) }
	}
	
	func addPart(_ newPart: MuseScorePart, staff newStaff: MuseScoreStaff, after: MuseScorePart? = nil) {
		parts.insert(newPart, after: after, parent: scoreElement)
		
		let afterStaff: MuseScoreStaff?
		if let afterPart = after {
			afterStaff = self.staff(part: afterPart)
		} else {
			afterStaff = nil
		}
		
		staffs.insert(newStaff, after: afterStaff, parent: scoreElement)
		
		
		// Rewrite identifiers, since order matters
		var identifier = 1
		let partsAndStaffs = parts.map { ($0, staffs(part: $0)) }
		for (part, staffs) in partsAndStaffs {
			var newStaffIDs = [String]()
			for staff in staffs {
				let newID = "\(identifier)"
				staff.identifier = newID
				newStaffIDs.append(newID)
				identifier += 1
			}
			part.staffIDs = newStaffIDs
		}
	}
}
