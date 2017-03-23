
import Foundation

protocol RideService {
    func findRide(from: String, to: String, completion: @escaping ([Ride]) -> Swift.Void)
}


