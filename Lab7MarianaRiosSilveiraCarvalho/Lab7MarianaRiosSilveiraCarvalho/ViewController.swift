//
//  ViewController.swift
//  Lab7MarianaRiosSilveiraCarvalho
//
//  Created by Mariana Rios Silveira Carvalho on 2023-11-05.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    // MARK: - UI Components
    @IBOutlet weak var logoImage: UIImageView!

    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var currentSpeedLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var maxAccelerationLabel: UILabel!

    @IBOutlet weak var tripStatusView: UIView!
    @IBOutlet weak var speedStatusView: UIView!

    @IBOutlet weak var mapView: MKMapView!

    // MARK: - Private Variables
    private let locationManager: CLLocationManager
    private var waypoints: [CLLocation]
    private var hasExceedSpeed: Bool
    private var maxSpeed: Double

    // MARK: - Initializer
        required init?(coder: NSCoder) {
            self.locationManager = CLLocationManager()
            self.hasExceedSpeed = false
            self.waypoints = []
            self.maxSpeed = 0.0

            super.init(coder: coder)
        }

    // MARK: - UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    // MARK: - Private Functions
    private func setup() {
        self.setupUIComponents()
        self.checkLocationServices()
    }

    private func setupUIComponents() {
        self.logoImage.layer.cornerRadius = 24

        self.maxSpeedLabel.text = "0.00 km/h"
        self.distanceLabel.text = "0.00 km"
        self.currentSpeedLabel.text = "0.00 km/h"
        self.averageSpeedLabel.text = "0.00 km/h"
        self.maxAccelerationLabel.text = "0.00 m/s^2"

        self.speedStatusView.backgroundColor = .clear
        self.tripStatusView.backgroundColor = .gray
    }

    private func setupLocationManager() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func centerViewOnUserLocation() {
        if let location = self.locationManager.location?.coordinate {
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: location, span: span)
            self.mapView.setRegion(region, animated: true)
        }
    }

    // MARK: - IBActions Functions
    @IBAction func didTapStartTrip(_ sender: Any) {
        self.checkLocationManagerAuthorizationStatus()

        if  self.locationManager.authorizationStatus == .authorizedWhenInUse || self.locationManager.authorizationStatus == .authorizedAlways {
            self.centerViewOnUserLocation()
            self.mapView.showsUserLocation = true
            self.locationManager.startUpdatingLocation()
            self.tripStatusView.backgroundColor = .green
        }
    }

    @IBAction func didTapStopTrip(_ sender: Any) {
        self.mapView.showsUserLocation = false
        self.locationManager.stopUpdatingLocation()
        self.tripStatusView.backgroundColor = .gray
        self.speedStatusView.backgroundColor = .clear
    }
}

// MARK: - CLLocationManager Delegate
extension ViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.checkLocationManagerAuthorizationStatus()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("Location === \(location)")
        self.waypoints.append(location)

        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
        let region = MKCoordinateRegion(center: center, span: span)
        self.mapView.setRegion(region, animated: true)
        
        self.getCurrentSpeed(from: location)
        self.getMaxSpeed(from: location)
        self.getDistance()
    }
}

// MARK: - Private Extension Functions Related to Speed
private extension ViewController {
    func getCurrentSpeed(from location: CLLocation) {
        let speed = location.speed.toKmPerHour()
        self.checkSpeedLimit(from: speed)
        self.currentSpeedLabel.text = "\(speed.toString()) km/h"
        print("Speed === \(speed.toString()) km/h")
    }

    func checkSpeedLimit(from speed: Double) {
        if speed > 115.0, !hasExceedSpeed {
            self.hasExceedSpeed = true
            let distance = calculateTotalDistance()
            print("The driver traveled \(distance.toKm().toString()) km before exceeding the speed limit (115 km/h).")
        }

        self.speedStatusView.backgroundColor = speed > 115.0 ? .red : .clear
        self.loadViewIfNeeded()

    }

    func getMaxSpeed(from location: CLLocation) {
        if location.speed > maxSpeed {
            maxSpeed = location.speed
            self.getMaxAcceleration(from: maxSpeed, and: location)
        }

        self.maxSpeedLabel.text = "\(maxSpeed.toKmPerHour().toString()) km/h"
        print("Max Speed === \(maxSpeed.toKmPerHour().toString()) km/h")
    }

    func getMaxAcceleration(from maxSpeed: Double, and location: CLLocation) {
        guard let startTime = self.waypoints.first?.timestamp else { return }
        let time = location.timestamp.timeIntervalSince(startTime)

        if time > 0 {
            let maxAcceleration = maxSpeed / time
            self.maxAccelerationLabel.text = "\(maxAcceleration.toString()) m/sˆ2"
            print("Max Acceleration === \(maxAcceleration.toString()) m/sˆ2")
        }
    }

    func getDistance() {
        let distance = calculateTotalDistance()
        self.getAverageSpeed(from: distance)
        self.distanceLabel.text = "\(distance.toKm().toString()) km"
        print("Distance === \(distance.toKm().toString()) km")
    }

    func getAverageSpeed(from totalDistance: Double) {
        guard let startTime = self.waypoints.first?.timestamp, let currentTime = self.waypoints.last?.timestamp else { return }
        let totalTime = currentTime.timeIntervalSince(startTime)

        if totalDistance > 0, totalTime > 0 {
            let averageSpeed = (totalDistance / totalTime).toKmPerHour()
            self.averageSpeedLabel.text = "\(averageSpeed.toString()) km/h"
            print("Average Speed === \(averageSpeed.toString()) km/h")
        }
    }

    func calculateTotalDistance() -> Double {
        var totalDistance: Double = 0.0

        for i in 1..<self.waypoints.count {
            let startLocation = CLLocation(latitude: self.waypoints[i].coordinate.latitude, longitude: self.waypoints[i].coordinate.longitude)
            let currentLocation = CLLocation(latitude: self.waypoints[i - 1].coordinate.latitude, longitude: self.waypoints[i - 1].coordinate.longitude)
            totalDistance += startLocation.distance(from: currentLocation)
        }

        return totalDistance
    }
}

// MARK: - Private Extension Functions Related to Permissions
private extension ViewController {
    func checkLocationServices() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.setupLocationManager()
            } else {
                self.showAuthorizationStatusAlertError()
            }
        }
    }

    func checkLocationManagerAuthorizationStatus() {
        let authorizationStatus: CLAuthorizationStatus

        if #available(iOS 14, *) {
            authorizationStatus = self.locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        switch authorizationStatus {
        case .denied:
            self.showAuthorizationStatusAlertError()
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func showAuthorizationStatusAlertError() {
        let alert = UIAlertController(
            title: "Trip Summary needs to access your location while using the app",
            message: "To use this app, you will need to allow Trip Summary to access your location.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }
}
