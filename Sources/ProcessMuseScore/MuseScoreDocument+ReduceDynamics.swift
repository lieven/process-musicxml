//
//  MuseScoreDocument+ReduceDynamics.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 15/09/2018.
//

import Foundation


extension MuseScoreDocument {
	public func reduceDynamics() {
		staffs.forEach {
			$0.reduceDynamics()
		}
	}
}

extension MuseScoreStaff {
	func reduceDynamics() {
		measures.forEach {
			$0.reduceDynamics()
		}
	}
}

extension MuseScoreMeasure {
	func reduceDynamics(defaultVelocity: Int = 80) {
		voices.forEach { voice in
			voice.children(name: "Dynamic").forEach { (dynamicElement) in
				dynamicElement.set(child: "velocity", stringValue: "\(defaultVelocity)")
			}
		}
	}
}
