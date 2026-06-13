import Foundation
import CoreLocation
import MapKit
import Observation

/// One-shot location + MapKit POI search. Asks for location only when the user
/// taps "What's here?", returns whatever stores are within `searchRadiusFeet`,
/// and maps them onto our `StoreCategory` values.
@MainActor
@Observable
final class NearbyStoreDetector: NSObject {
    var nearbyStores: [NearbyStore] = []
    var isSearching: Bool = false
    var lastError: String?

    /// Single source of truth for the search radius. The store-search distance
    /// and any user-facing copy both derive from this so they never disagree.
    static let searchRadiusFeet: Int = 250
    static var searchRadiusMeters: CLLocationDistance {
        Double(searchRadiusFeet) * 0.3048
    }

    /// Hidden override: when the list contains the magic item, pretend the
    /// device is standing at this coordinate instead of using live GPS.
    /// 45°31'22"N, 122°38'14"W.
    static let overrideItemName = "jirofeingold"
    static let overrideCoordinate = CLLocationCoordinate2D(
        latitude: 45.522778,
        longitude: -122.637222
    )

    @ObservationIgnored private let locationManager = CLLocationManager()
    @ObservationIgnored private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    @ObservationIgnored private var authorizationContinuation: CheckedContinuation<Void, Never>?

    struct NearbyStore: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let categories: [StoreCategory]
        let coordinate: CLLocationCoordinate2D

        func hash(into hasher: inout Hasher) { hasher.combine(id) }
        static func == (lhs: NearbyStore, rhs: NearbyStore) -> Bool { lhs.id == rhs.id }
    }

    override init() {
        super.init()
        locationManager.delegate = self
    }

    /// The main entry point — tap the button, this fills `nearbyStores`.
    /// When `forcedCoordinate` is supplied (the hidden override), live GPS is
    /// skipped and the search runs at that coordinate instead.
    func detect(forcedCoordinate: CLLocationCoordinate2D? = nil) async {
        isSearching = true
        lastError = nil
        defer { isSearching = false }

        do {
            let location: CLLocation
            if let forcedCoordinate {
                location = CLLocation(
                    latitude: forcedCoordinate.latitude,
                    longitude: forcedCoordinate.longitude
                )
            } else {
                try await ensureAuthorization()
                location = try await currentLocation()
            }
            let stores = try await searchPOIs(near: location)
            nearbyStores = stores
        } catch {
            lastError = error.localizedDescription
            nearbyStores = []
        }
    }

    // MARK: - Authorization

    private func ensureAuthorization() async throws {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return
        case .notDetermined:
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                self.authorizationContinuation = continuation
                self.locationManager.requestWhenInUseAuthorization()
            }
            if locationManager.authorizationStatus == .denied
                || locationManager.authorizationStatus == .restricted {
                throw LocationError.denied
            }
        case .denied, .restricted:
            throw LocationError.denied
        @unknown default:
            throw LocationError.denied
        }
    }

    // MARK: - Location

    private func currentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()
        }
    }

    // MARK: - POI search

    private func searchPOIs(near location: CLLocation) async throws -> [NearbyStore] {
        // Tight enough that only stores you're at or right next to show up.
        let request = MKLocalPointsOfInterestRequest(
            center: location.coordinate,
            radius: Self.searchRadiusMeters
        )
        request.pointOfInterestFilter = MKPointOfInterestFilter(
            including: StoreCategory.poiSearchCategories
        )

        let response: MKLocalSearch.Response
        do {
            response = try await MKLocalSearch(request: request).start()
        } catch let error as MKError where error.code == .placemarkNotFound {
            // "Nothing found here" is a normal outcome, not a failure — surface
            // it as an empty result so the user sees the friendly no-stores copy.
            return []
        }

        let stores: [(NearbyStore, CLLocationDistance)] = response.mapItems.compactMap { item in
            let categories = StoreCategory.categories(for: item)
            guard !categories.isEmpty else { return nil }
            let coord = item.placemark.coordinate
            let distance = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                .distance(from: location)
            let store = NearbyStore(
                name: item.name ?? "Unknown Place",
                categories: categories,
                coordinate: coord
            )
            return (store, distance)
        }
        return stores
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }

    enum LocationError: LocalizedError {
        case denied
        var errorDescription: String? {
            switch self {
            case .denied: "Location access is off. Turn it on in Settings to use \"What's here?\"."
            }
        }
    }
}

extension NearbyStoreDetector: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.locationContinuation?.resume(returning: location)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: any Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(throwing: error)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationContinuation?.resume()
            self.authorizationContinuation = nil
        }
    }
}
