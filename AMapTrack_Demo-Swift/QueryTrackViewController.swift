//
//  QueryTrackViewController.swift
//  AMapTrack_Demo-Swift
//
//  Created by lly on 2019/5/21.
//  Copyright © 2019 autonavi. All rights reserved.
//

import UIKit

class QueryTrackViewController: UIViewController,MAMapViewDelegate,AMapTrackManagerDelegate {

    @IBOutlet weak var queryTrackInfoBtn: UIButton!
    @IBOutlet weak var queryTrackHstBtn: UIButton!
    @IBOutlet weak var btnsContainerView: UIStackView!
    
    @IBOutlet weak var correctionSegment: UISegmentedControl!
    @IBOutlet weak var recoupSegment: UISegmentedControl!
    
    var correction:Bool = false
    var recoup:Bool = false
    
    @IBOutlet weak var mapView: MAMapView!
    
    var trackManager: AMapTrackManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.toolbar.isTranslucent = true
        self.navigationController?.isToolbarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initMapView()
        initBtns()
        initTrackManager()
    }
    
    deinit {
        self.trackManager?.stopService()
        self.trackManager?.delegate = nil
        
        self.mapView.removeFromSuperview()
        self.mapView.delegate = nil
    }

    func initMapView() {
        self.mapView.delegate = self
        self.mapView.zoomLevel = 13.0
        self.mapView.showsUserLocation = true
        self.mapView.userTrackingMode = MAUserTrackingMode.follow
    }
    
    func initBtns() {
        for subView:UIView in self.btnsContainerView.subviews {
            if subView.isKind(of: UIButton.self) {
                let btn = subView as! UIButton
                btn.backgroundColor = UIColor.white
                btn.layer.borderWidth = 1.0
                btn.layer.borderColor = UIColor.darkGray.cgColor
                btn.setTitleColor(UIColor.red, for: UIControl.State.normal)
            }
        }
    }
    
    func initTrackManager() {
        if Constants.TrackServiceID.count == 0 || Constants.TrackTerminalID.count == 0 {
            queryTrackInfoBtn.isEnabled = false
            queryTrackHstBtn.isEnabled = false
            
            let alertView = UIAlertView.init(title: "", message: "您需要指定ServiceID和TerminalID才可以使用轨迹服务", delegate: nil, cancelButtonTitle: "OK")
            alertView.show()
            return
        }
        
        let options = AMapTrackManagerOptions()
        options.serviceID = Constants.TrackServiceID
        
        self.trackManager = AMapTrackManager.init(options: options)
        self.trackManager?.delegate = self;
        
        self.trackManager?.allowsBackgroundLocationUpdates = true
        self.trackManager?.pausesLocationUpdatesAutomatically = false
    }
    
    //MARK:- Btns Action
    
    @IBAction func queryTrackInfoAction(_ sender: Any) {
        let request = AMapTrackQueryTrackInfoRequest()
        request.serviceID = self.trackManager?.serviceID ?? ""
        request.terminalID = Constants.TrackTerminalID
        request.startTime = Int64((NSDate.init().timeIntervalSince1970 - 12*60*60) * 1000)
        request.endTime = Int64((NSDate.init().timeIntervalSince1970 - 0) * 1000)
        if correction {
            request.correctionMode = "denoise=1,mapmatch=1,threshold=0,mode=driving";
        }
        if recoup {
            request.recoupMode = AMapTrackRecoupMode.driving
        }
        
        self.trackManager?.aMapTrackQueryTrackInfo(request)
    }
    
    @IBAction func queryTrackHstAction(_ sender: Any) {
        let request = AMapTrackQueryTrackHistoryAndDistanceRequest()
        request.serviceID = self.trackManager?.serviceID ?? ""
        request.terminalID = Constants.TrackTerminalID
        request.startTime = Int64((NSDate.init().timeIntervalSince1970 - 12*60*60) * 1000)
        request.endTime = Int64((NSDate.init().timeIntervalSince1970 - 0) * 1000)
        if correction {
            request.correctionMode = "driving"
        }
        if recoup {
            request.recoupMode = AMapTrackRecoupMode.driving
        }
        
        self.trackManager?.aMapTrackQueryTrackHistoryAndDistance(request)
    }
    
    @IBAction func correctionSegmentAction(_ sender: Any) {
        if correctionSegment.selectedSegmentIndex == 1 {
            self.correction = true
        } else {
            self.correction = false
        }
    }
    
    @IBAction func recoupSegmentAction(_ sender: Any) {
        if recoupSegment.selectedSegmentIndex == 1 {
            self.recoup = true
        } else {
            self.recoup = false
        }
    }
    
    //    MARK:- AMapTrackManagerDelegate
    func didFailWithError(_ error: Error, associatedRequest request: Any) {
        print("didFailWithError:\(error) --- associatedRequest:\(request)")
    }
    
    func onQueryTrackHistoryAndDistanceDone(_ request: AMapTrackQueryTrackHistoryAndDistanceRequest, response: AMapTrackQueryTrackHistoryAndDistanceResponse) {
        print("onQueryTrackHistoryAndDistanceDone \(response)")
        
        if response.points.count > 0 {
            self.mapView.removeOverlays(self.mapView.overlays)
            showPolylineWithTrackPoints(response.points)
            self.mapView.showOverlays(self.mapView.overlays, animated: false)
        }
    }
    
    func onQueryTrackInfoDone(_ request: AMapTrackQueryTrackInfoRequest, response: AMapTrackQueryTrackInfoResponse) {
        print("onQueryTrackInfoDone\(response.formattedDescription())")
        
        self.mapView.removeOverlays(self.mapView.overlays)
        for var track:AMapTrackBasicTrack in response.tracks {
            if track.points.count > 0 {
                showPolylineWithTrackPoints(track.points)
            }
        }
        self.mapView.showOverlays(self.mapView.overlays, animated: false)
    }
    
    //    MARK:-MAMapViewDelegate
    func mapViewRequireLocationAuth(_ locationManager: CLLocationManager!) {
        locationManager.requestAlwaysAuthorization()
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if overlay.isKind(of: MAPolyline.self) {
            let polylineRenderer = MAPolylineRenderer.init(overlay: overlay)
            polylineRenderer?.lineWidth = 12.0
            
            return polylineRenderer
        }
        return nil
    }
    
    
    //    MARK:- Helper
    func showPolylineWithTrackPoints(_ points:[AMapTrackPoint]) {
        let pointCount = points.count
        var locationArray = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount)
        for index in 0...(pointCount-1) {
            let location = CLLocationCoordinate2D.init(latitude: points[index].coordinate.latitude, longitude: points[index].coordinate.longitude)
            locationArray[index] = location
        }
        
        let polyline = MAPolyline.init(coordinates: locationArray, count: UInt(pointCount))
        self.mapView.add(polyline)
        
        locationArray.deallocate()
    }
    
    
}
