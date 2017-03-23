
import Foundation

enum RideType {
    case taxi
    case limo
}

struct Ride {
    var company: String
    var carNumber: String
    var timeInMinutes: Double
    var rideType: RideType
    var price: Float
    var currency: String
}


