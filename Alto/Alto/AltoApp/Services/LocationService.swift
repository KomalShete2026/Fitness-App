import CoreLocation
import Foundation

protocol LocationService {
    func requestCurrentLocation() async throws -> CLLocation
}

enum LocationServiceError: Error {
    case restricted
    case denied
    case noLocation
}

final class CoreLocationService: NSObject, LocationService {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestCurrentLocation() async throws -> CLLocation {
        let status = manager.authorizationStatus
        if status == .restricted { throw LocationServiceError.restricted }
        if status == .denied { throw LocationServiceError.denied }
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }
}

extension CoreLocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            continuation?.resume(throwing: LocationServiceError.noLocation)
            continuation = nil
            return
        }

        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
