//
//  main.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 27/11/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation


func printUsage(action: Action? = nil, errorMessage: String? = nil) {
	if let errorMessage = errorMessage {
		fputs("\(errorMessage)\n", stderr)
	}
	
	let actions: [Action]
	if let action = action {
		actions = [action]
	} else {
		actions = Action.all
	}
	
	actions.forEach { (action) in
		action.printUsage()
	}
}


let args = CommandLine.arguments
guard let action = Action(args: args) else {
	printUsage()
	exit(1)
}

action.perform()


