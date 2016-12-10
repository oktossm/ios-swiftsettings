//
// Created by Mikhail Mulyar on 01/08/16.
// Copyright (c) 2016 Mikhail Mulyar. All rights reserved.
//

import Foundation


protocol Reflectable {
	func properties() -> [String]
}


extension Reflectable {
	func properties() -> [String] {
		var s = [String]()
		for c in Mirror(reflecting: self).children {
			if let name = c.label {
				s.append(name)
			}
		}
		return s
	}
}
