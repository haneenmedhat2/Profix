//
//  AppLocationManager.swift
//  Profix
//
//  Created by Haneen on 31/12/2025.
//


import CoreLocation
import UIKit

final class AppLocationManager: NSObject {
    
    static let shared = AppLocationManager()
    
    private let locationManager = CLLocationManager()
    private var completion: ((AddressModel?) -> Void)?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    // MARK: - Public API -
    
    func requestLocation(completion: @escaping (AddressModel?) -> Void) {
        self.completion = completion
        
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            clearLocationAndComplete()
            showLocationPermissionAlert()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            clearLocationAndComplete()
        }
    }
    
}

extension AppLocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            clearLocationAndComplete()
            showLocationPermissionAlert()

        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            clearLocationAndComplete()
            return
        }
        
        reverseGeocode(location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        clearLocationAndComplete()
    }
}


extension AppLocationManager {
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        AppHelper.getAddressFromCoordinates(latitude: coordinate.latitude,
                                            longitude: coordinate.longitude) { [weak self] address in
            guard let self = self else { return }
            
            let model = AddressModel(
                lat: coordinate.latitude,
                long: coordinate.longitude,
                desc: address
            )
            
            UserDefaults.currentLocation = model

            DispatchQueue.main.async {
                self.completion?(model)
                self.completion = nil
            }
        }
    }

    private func clearLocationAndComplete() {
        UserDefaults.currentLocation = nil
        DispatchQueue.main.async {
            self.completion?(nil)
            self.completion = nil
        }
    }

    private func showLocationPermissionAlert() {
        DispatchQueue.main.async {
            guard let viewController = SceneDelegate.current?.window?.topViewController(),
                  viewController.presentedViewController == nil else { return }

            let alert = UIAlertController(
                title: "location_permission_title".localized,
                message: "location_permission_message".localized,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel))
            alert.addAction(UIAlertAction(title: "open_settings".localized, style: .default) { _ in
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsURL)
            })
            viewController.present(alert, animated: true)
        }
    }
}

