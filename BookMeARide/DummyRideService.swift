
import UIKit

class DummyRideService: NSObject, RideService {
    
    func findRide(from: String, to: String, completion: @escaping ([Ride]) -> Swift.Void) {
        completion(self.dummyRides())
    }
    
    private func dummyRides() -> [Ride] {
        let ride1 = Ride(company: "MM",
                         carNumber: "123", 
                         timeInMinutes: 3,
                         rideType: .taxi, 
                         price: 30,
                         currency: "EUR")
        
        let ride2 = Ride(company: "Luxury Limo",
                         carNumber: "11", 
                         timeInMinutes: 5,
                         rideType: .limo,
                         price: 60,
                         currency: "EUR")
        
        let ride3 = Ride(company: "Cool Taxi", 
                         carNumber: "80", 
                         timeInMinutes: 7,
                         rideType: .taxi,
                         price: 25,
                         currency: "EUR")
        
        return [ ride1, ride2, ride3 ]
    }
}
