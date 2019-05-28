//
// Created by Mikhail Mulyar on 01/08/16.
// Copyright (c) 2016 Mikhail Mulyar. All rights reserved.
//

import Foundation


protocol Reflectable {
    func properties() -> [String]
    func getTypeOfProperty(_ name: String) -> Any.Type?
}


extension Reflectable {
    public func properties() -> [String] {
        var s = [String]()
        for c in Mirror(reflecting: self).children {
            if let name = c.label {
                s.append(name)
            }
        }
        return s
    }

    // Returns the property type
    public func getTypeOfProperty(_ name: String) -> Any.Type? {

        var t: Mirror = Mirror(reflecting: self)

        for child in t.children  where child.label == name {
            return type(of: child.value)
        }
        while let parent = t.superclassMirror {
            for child in parent.children where child.label == name {
                return type(of: child.value)
            }
            t = parent
        }
        return nil
    }
}
