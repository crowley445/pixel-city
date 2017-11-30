//
//  ViewController.swift
//  pixel-city
//
//  Created by Brian  Crowley on 29/11/2017.
//  Copyright © 2017 Brian Crowley. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    
    var locationManager =  CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius : Double = 5000
    let screenSize = UIScreen.main.bounds
    
    var spinner : UIActivityIndicatorView?
    var progressLabel : UILabel?
    var collectionView: UICollectionView?
    var flowLayout = UICollectionViewFlowLayout()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        addSwipe()
        addCollectionView()
    }
    
    func addDoubleTap () {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe () {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    func addSpinner () {
        spinner = UIActivityIndicatorView()
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = UIColor.darkGray
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: (screenSize.height / 4) - ((spinner?.frame.height)! / 2))
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func addProgressLabel () {
        progressLabel = UILabel()
        progressLabel?.frame = CGRect(x: 0, y: (screenSize.height / 4) + 20, width: screenSize.width, height: 40)
        progressLabel?.font = UIFont(name: "Avenir Next", size: 18)
        progressLabel?.textColor = UIColor.darkGray
        progressLabel?.textAlignment = .center
        progressLabel?.text = "12/40 PHOTOS LOADED"
        collectionView?.addSubview(progressLabel!)
    }
    
    func addCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        pullUpView.addSubview(collectionView!)
    }
    
    func removeSpinner () {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func removeLabel () {
        if progressLabel != nil {
            progressLabel?.removeFromSuperview()
        }
    }
    
    func animateViewUp () {
        pullUpViewHeightConstraint.constant = screenSize.height / 2
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown () {
        pullUpViewHeightConstraint.constant = 1
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func centerMapButtonPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
}

extension MapVC : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil  }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.tintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUserLocation () {
        guard let coordinate = locationManager.location?.coordinate else { return }
        centerMapOnLocation(withCoordinates: coordinate)
    }
    
    func centerMapOnLocation( withCoordinates coordinate: CLLocationCoordinate2D ) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(sender: UIGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        removeSpinner()
        removeLabel()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLabel()
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let droppablePin = DroppablePin(coordinate: touchCoordinates, identifier: "droppablePin")
        mapView.addAnnotation(droppablePin)
        
        centerMapOnLocation(withCoordinates: touchCoordinates)
    }
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices () {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell {
            return cell
        }
        return PhotoCell()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
}

