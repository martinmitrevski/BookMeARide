
import Intents
import CoreLocation

class IntentHandler: INExtension, INRequestRideIntentHandling, INGetRideStatusIntentHandling {
    
    let rideService = DummyRideService()
    static let taxiIdentifier = "Taxi"
    static let limoIdentifier = "Limo"
    static let rideOptionKey = "rideOption"
    static let pickupDateKey = "pickupDate"
    static let statusKey = "status"
    
    override func handler(for intent: INIntent) -> Any {
        return self
    }
    
    
    func handle(requestRide intent: INRequestRideIntent,
                completion: @escaping (INRequestRideIntentResponse) -> Swift.Void) {
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INRequestRideIntentResponse.self))
        let response = INRequestRideIntentResponse(code: .success,
                                                   userActivity: userActivity)
        let rideStatus = INRideStatus()
        rideStatus.phase = INRidePhase.confirmed
        RideStorage.save(rideInfo: [ IntentHandler.statusKey : true ])
        rideStatus.pickupLocation = intent.pickupLocation
        rideStatus.dropOffLocation = intent.dropOffLocation
        let pickupDate = RideStorage.latestRide()?[IntentHandler.pickupDateKey] as! Date
        rideStatus.rideOption =
            INRideOption(name: (intent.rideOptionName?.spokenPhrase)!,
                         estimatedPickupDate: pickupDate)
        
        response.rideStatus = rideStatus
        completion(response)
    }
    
    func confirm(requestRide intent: INRequestRideIntent,
                 completion: @escaping (INRequestRideIntentResponse) -> Swift.Void) {
        self.handleIntent(requestRide: intent, completion: completion)
    }
    
    private func handleIntent(requestRide intent: INRequestRideIntent,
                              completion: @escaping (INRequestRideIntentResponse) -> Swift.Void) {
        let userActivity =
            NSUserActivity(activityType: NSStringFromClass(INRequestRideIntentResponse.self))
        var response = INRequestRideIntentResponse(code: .success,
                                                   userActivity: userActivity)
        let from = intent.pickupLocation?.name
        let to = intent.dropOffLocation?.name
        var rideType: RideType = .taxi
        if let phrase = intent.rideOptionName?.spokenPhrase {
            if phrase == IntentHandler.limoIdentifier {
                rideType = .limo
            }
        }
        if let from = from, let to = to {
            rideService.findRide(from: from, to: to, completion: { [unowned self] rides in
                if rides.count > 0 {
                    let rideStatus = self.convertRidesToRideStatus(rides: rides,
                                                                   from: from,
                                                                   to: to,
                                                                   rideType: rideType)
                    let rideInfo: [String : Any] =
                        [ IntentHandler.rideOptionKey : rideStatus.rideOption!.name,
                          IntentHandler.pickupDateKey : rideStatus.rideOption!.estimatedPickupDate]
                    RideStorage.removeRide()
                    RideStorage.save(rideInfo: rideInfo)
                    response.rideStatus = rideStatus
                    completion(response)
                } else {
                    response = INRequestRideIntentResponse(code: .failure,
                                                           userActivity: userActivity)
                    RideStorage.removeRide()
                    completion(response)
                }
            })
        } else {
            response = INRequestRideIntentResponse(code: .failure,
                                                   userActivity: userActivity)
            RideStorage.removeRide()
            completion(response)
        }
    }
    
    func resolvePickupLocation(forRequestRide intent: INRequestRideIntent,
                               with completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        if (intent.pickupLocation == nil) {
            let result = INPlacemarkResolutionResult.needsValue()
            completion(result)
        } else {
            let result = INPlacemarkResolutionResult.success(with: intent.pickupLocation!)
            completion(result)
        }
    }
    
    func resolveDropOffLocation(forRequestRide intent: INRequestRideIntent,
                                with completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        if (intent.dropOffLocation == nil) {
            let result = INPlacemarkResolutionResult.needsValue()
            completion(result)
        } else {
            let result = INPlacemarkResolutionResult.success(with: intent.dropOffLocation!)
            completion(result)
        }
    }
    
    private func convertRidesToRideStatus(rides: [Ride],
                                          from: String, 
                                          to: String,
                                          rideType: RideType) -> INRideStatus {
        var text = "ride "
        var selectedRide = rides.first!
        for ride in rides {
            if ride.rideType == rideType {
                selectedRide = ride
                break
            }
        }
        let price = "\(selectedRide.price) \(selectedRide.currency)"
        let minutes = Int(selectedRide.timeInMinutes)
        text += "from \(from) to \(to) with \(selectedRide.company), " +
                "departing in \(minutes) minutes for \(price)"
        let rideStatus = INRideStatus()
        let pickupDate = Date().addingTimeInterval(selectedRide.timeInMinutes * 60)
        rideStatus.rideOption = INRideOption(name: text, estimatedPickupDate: pickupDate)
        
        return rideStatus
    }
    
    func resolveRideOptionName(forRequestRide intent: INRequestRideIntent,
                        with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        if let rideOption = intent.rideOptionName {
            let result = INSpeakableStringResolutionResult.success(with: rideOption)
            completion(result)
        } else {
            let first = INSpeakableString(identifier: IntentHandler.taxiIdentifier,
                                          spokenPhrase: "Taxi",
                                          pronunciationHint: nil)
            let second = INSpeakableString(identifier: IntentHandler.limoIdentifier,
                                           spokenPhrase: "Limo",
                                           pronunciationHint: nil)
            let result = INSpeakableStringResolutionResult.disambiguation(with: [first, second])
            completion(result)
        }
    }
    
    
    public func resolvePickupLocation(forListRideOptions intent: INListRideOptionsIntent,
                                with completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        let result = INPlacemarkResolutionResult.success(with: intent.pickupLocation!)
        completion(result)
    }
    
    
    public func resolveDropOffLocation(forListRideOptions intent: INListRideOptionsIntent,
                            with completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        let result = INPlacemarkResolutionResult.success(with: intent.dropOffLocation!)
        completion(result)
    }
    
    public func handle(getRideStatus intent: INGetRideStatusIntent,
                       completion: @escaping (INGetRideStatusIntentResponse) -> Void) {
        guard let latest = RideStorage.latestRide() else {
            failureResponse(completion: completion)
            return
        }
        
        guard let status = latest[IntentHandler.statusKey] as? Bool else {
            failureResponse(completion: completion)
            return
        }
        
        guard status == true else {
            failureResponse(completion: completion)
            return
        }
        
        let response = INGetRideStatusIntentResponse(code: .success, userActivity: nil)
        let rideStatus = INRideStatus()
        let pickupDate = latest[IntentHandler.pickupDateKey] as! Date
        rideStatus.rideOption =
            INRideOption(name: latest[IntentHandler.rideOptionKey] as! String,
                         estimatedPickupDate: pickupDate)
        rideStatus.phase = ridePhase(forPickupDate: pickupDate)
        response.rideStatus = rideStatus
        completion(response)
    }
    
    private func failureResponse(completion: @escaping (INGetRideStatusIntentResponse) -> Void) {
        let response = INGetRideStatusIntentResponse(code: .failure, userActivity: nil)
        completion(response)
    }
    
    private func ridePhase(forPickupDate date: Date) -> INRidePhase {
        let dateDiff = self.dateDiff(forPickupDate: date)
        if dateDiff < 0 {
            return .ongoing
        } else {
            if dateDiff > 60 {
                return .approachingPickup
            } else {
                return .pickup
            }
        }
    }
    
    private func dateDiff(forPickupDate date: Date) -> Int {
        let dateDiff = Calendar.current.dateComponents([.second],
                                                       from: Date(),
                                                       to: date).second ?? 0
        return dateDiff
    }
    
    
    public func startSendingUpdates(forGetRideStatus intent: INGetRideStatusIntent,
                                    to observer: INGetRideStatusIntentResponseObserver) {
        print("Siri started asking for updates for the ride")
    }
    
    
    public func stopSendingUpdates(forGetRideStatus intent: INGetRideStatusIntent) {
        print("Siri stopped asking for updates for the ride")
    }

    
}
