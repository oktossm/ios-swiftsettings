//
// Created by Mikhail Mulyar on 30/07/16.
// Copyright (c) 2016 Mikhail Mulyar. All rights reserved.
//

import Foundation


open class Settings: NSObject, Reflectable {

	static let keysPrefixKey = "kSettingsPrefixKey"

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

	deinit {
		for property in self.properties() {
			self.removeObserver(self, forKeyPath: property)
		}
	}

	open subscript(key: String) -> AnyObject? {
		get {
			let value = UserDefaults.standard.object(forKey: key)

			if let data = value as? Data {
				return NSKeyedUnarchiver.unarchiveObject(with: data) as AnyObject?
			}

			return nil
		}
		set {
			if let value = newValue {
				let data = NSKeyedArchiver.archivedData(withRootObject: value)
				UserDefaults.standard.set(data, forKey: key)
			}
			else {
				UserDefaults.standard.removeObject(forKey: key)
			}

			UserDefaults.standard.synchronize()
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
}
