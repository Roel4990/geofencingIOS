import UIKit
import WebKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, WKNavigationDelegate, WKUIDelegate {
    
    var webView: WKWebView!
    let locationManager = CLLocationManager()
    var locationPermissionCompletion: ((Bool) -> Void)?
    var isWorkplace = false
    let regionRadius: CLLocationDistance = 500 // 100 meters
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 위치 정보 권한 요청
        webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)
        locationManager.delegate = self
        // 백그라운드 위치 권한
        locationManager.allowsBackgroundLocationUpdates = true
        requestLocationPermission { granted in
            if granted {
                print("Location access granted.")
            } else {
                print("Location access denied.")
            }
        }
        locationManager.requestAlwaysAuthorization()
        
        // Example coordinate: Apple's HQ
        let center = CLLocationCoordinate2D(latitude: 37.5710792, longitude: 126.9814293)
        startMonitoring(center: center)
        
        // 웹뷰에 웹 사이트 로드
        if let url = URL(string: "http://192.168.21.17:3000") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        webView.frame = view.bounds
        webView.frame = CGRect(x: 0, y: 40, width: view.bounds.width, height: view.bounds.height - 40)
    }
    func startMonitoring(center: CLLocationCoordinate2D) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let region = CLCircularRegion(center: center, radius: regionRadius, identifier: "MyGeoFence")
            region.notifyOnEntry = true
            region.notifyOnExit = true
            
            locationManager.startMonitoring(for: region)
            locationManager.requestState(for: region)  // 상태 요청
        }
    }
    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        locationPermissionCompletion = completion
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            completion(true)
            // 해당 코드가 백그라운드에서도 계속해서 돌 수 있도록 하는 코드
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    // 상태가 결정되었을 때 호출되는 메서드
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if region is CLCircularRegion {
            switch state {
            case .inside:
                print("해당 지역 안에 있습니다.")
            case .outside:
                print("해당 지역 밖에 있습니다.")
            case .unknown:
                print("해당 지역에 대한 상태를 알 수 없습니다.")
            @unknown default:
                print("알 수 없는 상태입니다.")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            // User entered the region
            print("해당 지역 안입니다.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            // User exited the region
            print("해당 지역 밖입니다.")
        }
    }
    // CLLocationManagerDelegate의 다음 메서드를 사용하여 권한 변경을 감지하고 completion 핸들러를 호출합니다.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationPermissionCompletion?(true)
        case .denied, .restricted, .notDetermined:
            locationPermissionCompletion?(false)
        @unknown default:
            locationPermissionCompletion?(false)
        }
        locationPermissionCompletion = nil
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
        }
    }
    func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != .invalid)
    }

    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
