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
    private var waypoints: [CLLocation] = []
    private var maxSpeed: Double = 0.0

    // MARK: - Initializer
        required init?(coder: NSCoder) {
            self.locationManager = CLLocationManager()
            super.init(coder: coder)
        }

    // MARK: - UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    // MARK: - Private Functions
    private func setup() {
        self.setupLogo()
        self.setupLabels()
        self.setupStatusViews()
        self.setupLocationServices()
    }

    private func setupLogo() {
        self.logoImage.layer.cornerRadius = 24
    }

    private func setupLabels() {
        maxSpeedLabel.text = "0.00 km/h"
        distanceLabel.text = "0.00 km"
        currentSpeedLabel.text = "0.00 km/h"
        averageSpeedLabel.text = "0.00 km/h"
        maxAccelerationLabel.text = "0.00 m/s^2"
    }

    private func setupStatusViews() {
        self.speedStatusView.backgroundColor = .clear
        self.tripStatusView.backgroundColor = .gray
    }

    private func setupLocationServices() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.setupLocationManager()
            } else {
                self.showAuthorizationStatusAlertError()
            }
        }
    }

    private func setupLocationManager() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func checkLocationManagerAuthorizationStatus() {
        switch self.locationManager.authorizationStatus {
        case .denied:
            self.showAuthorizationStatusAlertError()
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    private func centerViewOnUserLocation() {
        if let location = self.locationManager.location?.coordinate {
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: location, span: span)
            self.mapView.setRegion(region, animated: true)
        }
    }

    private func updateSpeedStatusView(currentSpeed: Double) {
        self.speedStatusView.backgroundColor = currentSpeed > 115.0 ? .red : .clear
        self.loadViewIfNeeded()
    }

    private func showCurrentSpeed(from location: CLLocation) {
        let speed = location.speed
        let formattedSpeed = speed * 3.6
        self.currentSpeedLabel.text = "\(formattedSpeed.toString()) km/h"
        print("Speed === \(formattedSpeed.toString())")

        self.showMaxSpeed(with: location)
        self.updateSpeedStatusView(currentSpeed: formattedSpeed)
    }

    private func showMaxSpeed(with location: CLLocation) {
        let currentSpeed = location.speed

        if currentSpeed > maxSpeed {
            maxSpeed = currentSpeed
            self.calculateMaxAcceleration(with: maxSpeed, and: location)
        }

        let formattedSpeed = maxSpeed * 3.6
        self.maxSpeedLabel.text = "\(formattedSpeed.toString()) km/h"
        print("Max Speed === \(formattedSpeed.toString())")
    }

    private func calculateAverageSpeed() {
        var averageSpeed: Double = 0.0
        let count: Double = Double(self.waypoints.count)

        self.waypoints.forEach { location in
            averageSpeed += location.speed
        }

        let formattedSpeed = (averageSpeed / count) * 3.6
        self.averageSpeedLabel.text = "\(formattedSpeed.toString()) km/h"
        print("Average Speed === \(formattedSpeed.toString())")
    }

    private func calculateDistance() {
        var distance: Double = 0.0


        for i in 1..<self.waypoints.count {
            let startLocation = CLLocation(latitude: self.waypoints[i].coordinate.latitude, longitude: self.waypoints[i].coordinate.longitude)
            let currentLocation = CLLocation(latitude: self.waypoints[i - 1].coordinate.latitude, longitude: self.waypoints[i - 1].coordinate.longitude)
            distance += startLocation.distance(from: currentLocation)
        }

        let formattedDistance = distance / 1000
        self.distanceLabel.text = "\(formattedDistance.toString()) km"
        print("Distance === \(formattedDistance.toString())")
    }

    private func calculateMaxAcceleration(with maxSpeed: Double, and location: CLLocation) {
        guard let startTime = self.waypoints.first?.timestamp else { return }
        let time = location.timestamp.timeIntervalSince(startTime)

        if time > 0 {
            let maxAcceleration = maxSpeed / time
            self.maxAccelerationLabel.text = "\(maxAcceleration.toString()) m/sˆ2"
            print("Max Acceleration === \(maxAcceleration.toString())")
        }
    }

    private func showAuthorizationStatusAlertError() {
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

    // MARK: - IBActions Functions
    @IBAction func didTapStartTrip(_ sender: Any) {
        self.checkLocationManagerAuthorizationStatus()
        if  self.locationManager.authorizationStatus == .authorizedWhenInUse || self.locationManager.authorizationStatus == .authorizedAlways {
            self.locationManager.requestWhenInUseAuthorization()
            self.tripStatusView.backgroundColor = .green

            centerViewOnUserLocation()

            self.mapView.showsUserLocation = true
            self.mapView.userTrackingMode = .followWithHeading

            self.locationManager.startUpdatingLocation()
        }
    }

    @IBAction func didTapStopTrip(_ sender: Any) {
        self.tripStatusView.backgroundColor = .gray
        self.speedStatusView.backgroundColor = .clear
        self.locationManager.stopUpdatingLocation()
        self.mapView.showsUserLocation = false
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.checkLocationManagerAuthorizationStatus()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.waypoints.append(location)
        print("Location === \(location)")

        let span = MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: span)
        self.mapView.setRegion(region, animated: true)
        
        self.showCurrentSpeed(from: location)
        self.calculateAverageSpeed()
        self.calculateDistance()
    }
}
