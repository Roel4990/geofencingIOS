import UIKit
import WebKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, WKNavigationDelegate, WKUIDelegate {
    
    var webView: WKWebView!
    let locationManager = CLLocationManager()
    var locationPermissionCompletion: ((Bool) -> Void)?
    
    let regionRadius: CLLocationDistance = 500 // 100 meters

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 위치 정보 권한 요청
//        requestLocationPermission { granted in
//            if granted {
//                print("Location access granted.")
//            } else {
//                print("Location access denied.")
//            }
//        }
        webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)
        locationManager.delegate = self
        requestLocationPermission { granted in
            if granted {
                print("Location access granted.")
            } else {
                print("Location access denied.")
            }
        }
//        locationManager.requestAlwaysAuthorization()
        
        // Example coordinate: Apple's HQ
        let center = CLLocationCoordinate2D(latitude: 37.5710792, longitude: 126.9814293)
        startMonitoring(center: center)
        
        // 웹뷰에 웹 사이트 로드
        if let url = URL(string: "http://192.168.1.37:3000") {
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
        }
    }
    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        locationPermissionCompletion = completion
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            completion(true)
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            // User entered the region
            print("Entered the region")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            // User exited the region
            print("Exited the region")
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
}
