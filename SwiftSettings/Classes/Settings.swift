//
// Created by Mikhail Mulyar on 30/07/16.
// Copyright (c) 2016 Mikhail Mulyar. All rights reserved.
//

import Foundation


open class Settings: NSObject, Reflectable {
    static let keysPrefixKey = "kSettingsPrefixKey"
    static let codableKeysPrefixKey = "kSettingsCodablePrefixKey"

    public override init() {
        super.init()

        for property in self.properties() {
            if let value = self[settingsKeyForPath(property)] {
                self.setValue(value, forKeyPath: property)
            }

            self.addObserver(self,
                             forKeyPath: property,
                             options: .new,
                             context: nil)
        }
    }

    open var keyPrefix: String? {
        get {
            if let key = UserDefaults.standard.string(forKey: Settings.keysPrefixKey) {
                return key
            }
            let key = "\(UUID().uuidString)."
            UserDefaults.standard.set(key, forKey: Settings.keysPrefixKey)
            UserDefaults.standard.synchronize()
            return key
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Settings.keysPrefixKey)
        }
    }

    open var codableKeyPrefix: String? {
        get {
            if let key = UserDefaults.standard.string(forKey: Settings.codableKeysPrefixKey) {
                return key
            }
            let key = "\(UUID().uuidString)."
            UserDefaults.standard.set(key, forKey: Settings.codableKeysPrefixKey)
            UserDefaults.standard.synchronize()
            return key
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Settings.codableKeysPrefixKey)
        }
    }

    deinit {
        for property in self.properties() {
            self.removeObserver(self, forKeyPath: property)
        }
    }

    open func data(for key: String) -> Data? {
        return UserDefaults.standard.object(forKey: key) as? Data
    }

    open func setData(_ data: Data?, for key: String) {
        if let d = data {
            UserDefaults.standard.set(d, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }

        UserDefaults.standard.synchronize()
    }

    open subscript(key: String) -> Any? {
        get {
            guard let data = self.data(for: key) else { return nil }
            return NSKeyedUnarchiver.unarchiveObject(with: data)
        }
        set {
            guard let value = newValue else {
                self.setData(nil, for: key)
                return
            }
            let data = NSKeyedArchiver.archivedData(withRootObject: value)
            self.setData(data, for: key)
        }
    }

    open func resetSettings() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }

    final override public func observeValue(forKeyPath keyPath: String?,
                                            of object: Any?,
                                            change: [NSKeyValueChangeKey: Any]?,
                                            context: UnsafeMutableRawPointer?) {
        if let path = keyPath {
            self[settingsKeyForPath(path)] = self.value(forKeyPath: path) as AnyObject?
        }
    }

    fileprivate func settingsKeyForPath(_ path: String) -> String {
        let prefix = self.keyPrefix
        return prefix == nil ? path : "\(prefix!)\(path)"
    }

    fileprivate func settingsCodableKeyForPath(_ path: String) -> String {
        let prefix = self.codableKeyPrefix
        return prefix == nil ? path : "\(prefix!)\(path)"
    }
}


extension Settings {
    public func store<T: Codable>(_ value: T?,
                                  forKey key: String = String(describing: T.self),
                                  encoder: JSONEncoder = JSONEncoder()) {
        if let val = value, let data: Data = try? encoder.encode(val) {
            self.setData(data, for: self.settingsCodableKeyForPath(key))
        } else {
            self.setData(nil, for: self.settingsCodableKeyForPath(key))
        }
    }

    public func fetch<T: Codable>(forKey key: String = String(describing: T.self),
                                  type: T.Type,
                                  decoder: JSONDecoder = JSONDecoder()) -> T? {
        if let data = self.data(for: self.settingsCodableKeyForPath(key)) {
            return try? decoder.decode(type, from: data) as T
        }

        return nil
    }
}
