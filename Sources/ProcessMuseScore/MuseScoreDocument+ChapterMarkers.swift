//
//  MuseScoreStaff+ChapterMarkers.swift
//  
//
//  Created by Lieven Dekeyser on 13/06/2024.
//

import Foundation


struct ChapterMarker {
	let mark: String
	let time: Double
}


extension MuseScoreStaff {
	var chapterMarkers: [ChapterMarker] {
		return []
	}
}
