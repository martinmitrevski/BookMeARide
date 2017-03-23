
import UIKit
import Intents

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var from: UITextField?
    @IBOutlet weak var to: UITextField?
    @IBOutlet weak var ridesTableView: UITableView?
    
    private let rideService = DummyRideService()
    private var rides = [Ride]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestSiriAuthorization()
    }
    
    private func requestSiriAuthorization() {
        INPreferences.requestSiriAuthorization { authorizationStatus in
            switch authorizationStatus {
            case .authorized:
                print("User authorized Siri")
            default:
                print("User didn't authorize Siri")
            }
        }
    }
    
    @IBAction func findRouteButtonClicked() {
        let fromText = self.checkNil(from?.text as AnyObject?)
        let toText = self.checkNil(to?.text as AnyObject?)
        rideService.findRide(from: fromText, to: toText, completion: {
            [unowned self] foundRides in
            self.rides = foundRides
            self.ridesTableView?.reloadData()
        })
    }
    
    // MARK: UITableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rides.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "RouteCell")
        }
        
        let ride = rides[indexPath.row]
        let displayText =
        "Ride with \(ride.company), car number \(ride.carNumber) in \(ride.timeInMinutes) min."
        cell?.textLabel?.text = displayText
        cell?.textLabel?.minimumScaleFactor = 0.3
        cell?.textLabel?.adjustsFontSizeToFitWidth = true
        
        return cell!
    }
    
    
    func checkNil(_ string: AnyObject?) -> String {
        return string == nil ? "" : string as! String
    }
}

