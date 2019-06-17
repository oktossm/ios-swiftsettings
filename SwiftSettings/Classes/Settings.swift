//
// Created by Mikhail Mulyar on 30/07/16.
// Copyright (c) 2016 Mikhail Mulyar. All rights reserved.
//

import Foundation


open class Settings: NSObject, Reflectable {
    static let keysPrefixKey = "kSettingsPrefixKey"
    static let codableKeysPrefixKey = "kSettingsCodablePrefixKey"

    let userDefaults: UserDefaults
    let domainName: String
    private static var currentContext = 0

    
    public init(suiteName: String? = nil) {
        if let name = suiteName, let userdefaults = UserDefaults(suiteName: name) {
            self.userDefaults = userdefaults
            self.domainName = name
        } else {
            self.userDefaults = UserDefaults.standard
            self.domainName = Bundle.main.bundleIdentifier!
        }
        
        super.init()

        for property in self.properties() {
            if let value = self[settingsKeyForPath(property)] {
                self.setValue(value, forKeyPath: property)
            }

            self.addObserver(self,
                             forKeyPath: property,
                             options: .new,
                             context: &Settings.currentContext)

            self.userDefaults.addObserver(self,
                                          forKeyPath: settingsKeyForPath(property),
                                          options: .new,
                                          context: nil)
        }
    }

    open var keyPrefix: String? {
        get {
            if let key = self.userDefaults.string(forKey: Settings.keysPrefixKey) {
                return key
            }
            let key = "\(UUID().uuidString)_"
            self.userDefaults.set(key, forKey: Settings.keysPrefixKey)
            self.userDefaults.synchronize()
            return key
        }
        set {
            self.userDefaults.set(newValue, forKey: Settings.keysPrefixKey)
        }
    }

    open var codableKeyPrefix: String? {
        get {
            if let key = self.userDefaults.string(forKey: Settings.codableKeysPrefixKey) {
                return key
            }
            let key = "\(UUID().uuidString)_"
            self.userDefaults.set(key, forKey: Settings.codableKeysPrefixKey)
            self.userDefaults.synchronize()
            return key
        }
        set {
            self.userDefaults.set(newValue, forKey: Settings.codableKeysPrefixKey)
        }
    }

    deinit {
        for property in self.properties() {
            self.removeObserver(self, forKeyPath: property)
        }
    }

    open func data(for key: String) -> Data? {
        return self.userDefaults.object(forKey: key) as? Data
    }

    open func setData(_ data: Data?, for key: String) {
        if let d = data {
            self.userDefaults.set(d, forKey: key)
        } else {
            self.userDefaults.removeObject(forKey: key)
        }

        self.userDefaults.synchronize()
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
        self.userDefaults.removePersistentDomain(forName: self.domainName)
    }

    final override public func observeValue(forKeyPath keyPath: String?,
                                            of object: Any?,
                                            change: [NSKeyValueChangeKey: Any]?,
                                            context: UnsafeMutableRawPointer?) {
        guard let path = keyPath else { return }

        if context == &Settings.currentContext {
            self[settingsKeyForPath(path)] = self.value(forKeyPath: path) as AnyObject?
        } else if let keyPath = self.keyPath(from: path) {
            self.setValue(self[settingsKeyForPath(path)], forKeyPath: keyPath)
        }
    }

    fileprivate func keyPath(from settingsKey: String) -> String? {
        let keyPath = settingsKey.components(separatedBy: "_").last
        return keyPath
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
