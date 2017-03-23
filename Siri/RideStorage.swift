
import Foundation

class RideStorage {
    
    static let savedRideId = "savedRide"
    
    class func save(rideInfo: [String : Any]) {
        var newRideInfo = rideInfo
        if let saved = latestRide() {
            newRideInfo.merge(with: saved)
        }
        UserDefaults.standard.set(newRideInfo, forKey: RideStorage.savedRideId)
        UserDefaults.standard.synchronize()
    }
    
    class func removeRide() {
        UserDefaults.standard.set(nil, forKey: RideStorage.savedRideId)
        UserDefaults.standard.synchronize()
    }
    
    class func latestRide() -> [String : Any]? {
        return UserDefaults.standard.value(forKey: RideStorage.savedRideId) as? [String : Any]
    }
    
}

extension Dictionary {
    
    mutating func merge(with dictionary: Dictionary) {
        dictionary.forEach { updateValue($1, forKey: $0) }
    }
    
    func merged(with dictionary: Dictionary) -> Dictionary {
        var dict = self
        dict.merge(with: dictionary)
        return dict
    }
}
