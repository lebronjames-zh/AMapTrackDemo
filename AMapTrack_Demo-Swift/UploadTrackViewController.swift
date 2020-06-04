//
//  ViewController.swift
//  AMapTrack_Demo-Swift
//
//  Created by lly on 2019/5/21.
//  Copyright © 2019 autonavi. All rights reserved.
//

import UIKit

class UploadTrackViewController: UIViewController ,MAMapViewDelegate,AMapTrackManagerDelegate {

    @IBOutlet weak var mapView: MAMapView!
    
    @IBOutlet weak var btnsContainerView: UIStackView!
    @IBOutlet weak var startTrackServiceBtn: UIButton!
    @IBOutlet weak var gatherBtn: UIButton!
    @IBOutlet weak var createTidBtn: UIButton!
    @IBOutlet weak var trackIDSegment: UISegmentedControl!
    
    var serviceStartedFlag = false
    var gatherStartedFlag = false
    var createTrackID = false
    
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
            startTrackServiceBtn.isEnabled = false
            gatherBtn.isEnabled = false
            
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
    //MARK:-Btns action
    @IBAction func clickeTrackServiceBtn(_ sender: Any) {
        if self.trackManager == nil {
            return
        }
        if self.serviceStartedFlag == false {
            let options = AMapTrackManagerServiceOption()
            options.terminalID = Constants.TrackTerminalID
            
            self.trackManager?.startService(withOptions: options)
        } else {
            self.trackManager?.stopService()
        }
    }
    
    @IBAction func clickeGatherBtn(_ sender: Any) {
        if self.trackManager == nil {
            return
        }
        if self.trackManager?.terminalID.count == 0 {
            NSLog("您需要先开始轨迹服务，才可以开始轨迹采集。");
            return
        }
        if self.gatherStartedFlag == false {
            if createTrackID == true {
                trackIDSegment.isEnabled = false
                doCreateTrackName()
            } else {
                trackIDSegment.isEnabled = false
                self.trackManager?.startGatherAndPack()
            }
        } else {
            self.trackManager?.stopGaterAndPack()
        }
    }

    @IBAction func clickeCreateTidBtn(_ sender: Any) {
        if self.trackManager == nil {
            return
        }
        let request = AMapTrackAddTerminalRequest()
        request.serviceID = Constants.TrackServiceID
        request.terminalName = "TrackDemoFirstTerminal"
        request.terminalDesc = "TrackDemoFirstTerminal-desc"
        
        self.trackManager?.aMapTrackAddTerminal(request)
    }
    
    @IBAction func segmentChanged(_ sender: Any) {
        if self.trackIDSegment.selectedSegmentIndex == 1 {
            self.createTrackID = true
        } else {
            self.createTrackID = false
        }
    }
    
    //    MARK:- Helper
    func doCreateTrackName() {
        if self.trackManager == nil {
            return
        }
        let request = AMapTrackAddTrackRequest()
        request.serviceID = self.trackManager!.serviceID
        request.terminalID = self.trackManager?.terminalID
        
        self.trackManager?.aMapTrackAddTrack(request)
        
    }
    
    //    MARK:- AMapTrackManagerDelegate
    func didFailWithError(_ error: Error, associatedRequest request: Any) {
        if request is AMapTrackAddTrackRequest {
            self.trackIDSegment.isEnabled = true
        }
        print("didFailWithError:\(error) --- associatedRequest:\(request)")
    }
    
    func onStartService(_ errorCode: AMapTrackErrorCode) {
        if errorCode == AMapTrackErrorCode.OK {
            self.serviceStartedFlag = true
            self.startTrackServiceBtn.backgroundColor = UIColor.green
        } else {
            self.serviceStartedFlag = false
            self.startTrackServiceBtn.backgroundColor = UIColor.white
        }
        print("onStartService:\(errorCode)")
    }
    
    func onStopService(_ errorCode: AMapTrackErrorCode) {
        serviceStartedFlag = false
        gatherStartedFlag = false
        startTrackServiceBtn.backgroundColor = UIColor.white
        gatherBtn.backgroundColor = UIColor.white
        trackIDSegment.isEnabled = true
        print("onStopService:\(errorCode)")
    }
    
    func onStartGatherAndPack(_ errorCode: AMapTrackErrorCode) {
        if errorCode == AMapTrackErrorCode.OK {
            self.gatherStartedFlag = true
            self.gatherBtn.backgroundColor = UIColor.green
        } else {
            self.gatherStartedFlag = false
            self.gatherBtn.backgroundColor = UIColor.white
        }
        print("onStartGatherAndPack\(errorCode)")
    }
    
    func onStopGatherAndPack(_ errorCode: AMapTrackErrorCode) {
        self.gatherStartedFlag = false
        self.gatherBtn.backgroundColor = UIColor.white
        self.trackIDSegment.isEnabled = true
        print("onStopGatherAndPack:\(errorCode)")
    }
    
    func onStopGatherAndPack(_ errorCode: AMapTrackErrorCode, errorMessage: String?) {
        print("onStopGatherAndPack:\(errorCode) errorMessage:\(String(describing: errorMessage))")
    }
    
    func onAddTrackDone(_ request: AMapTrackAddTrackRequest, response: AMapTrackAddTrackResponse) {
        print("onAddTrackDone:\(response.formattedDescription())")
        if response.code == AMapTrackErrorCode.OK {
            self.trackManager?.trackID = response.trackID
            self.trackManager?.startGatherAndPack()
        } else {
            self.trackIDSegment.isEnabled = true
            print("创建trackID失败")
        }
    }
    
    func onAddTerminalDone(_ request: AMapTrackAddTerminalRequest, response: AMapTrackAddTerminalResponse) {
        if response != nil {
            print("you should copy the response TerminalID\(response.terminalID) to Constants.TerminalID")
        }
    }
    
    //    MARK:-MAMapViewDelegate
    func mapView(_ mapView: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation: Bool) {
        NSLog("mapView userLocaiton updated")
    }
    
    func mapViewRequireLocationAuth(_ locationManager: CLLocationManager!) {
        locationManager.requestAlwaysAuthorization()
    }
}

