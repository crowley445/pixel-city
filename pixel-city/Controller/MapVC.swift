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
import Alamofire
import AlamofireImage

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
    
    var imageUrls = [String]()
    var images = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        addSwipe()
        addCollectionView()
        
        registerForPreviewing(with: self, sourceView: collectionView!)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
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
        collectionView?.addSubview(progressLabel!)
    }
    
    func addCollectionView() {
        
        let itemSize = (UIScreen.main.bounds.width / 3)
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, itemSize * 2.5, 0)
        flowLayout.itemSize = CGSize(width: itemSize, height: itemSize)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = UIColor.white
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
        cancelAllSessions()
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
        cancelAllSessions()

        images.removeAll()
        collectionView?.reloadData()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLabel()
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let droppablePin = DroppablePin(coordinate: touchCoordinates, identifier: "droppablePin")
        mapView.addAnnotation(droppablePin)
        
        self.retrieveUrls(withAnnotaion: droppablePin) { (urlArray) in
            self.downloadImages(urlArray: urlArray, completion: { (success) in
                if success {
                    self.removeSpinner()
                    self.removeLabel()
                    self.collectionView?.reloadData()
                    self.collectionView?.layoutIfNeeded()
                }
            })
        }
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
            
            let imageView = UIImageView(image: images[indexPath.row])
            imageView.frame.size = cell.frame.size
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            cell.addSubview(imageView)
            
            return cell
        }
        return PhotoCell()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoVC = PhotoVC()
        photoVC.initData(withImage: images[indexPath.row])
        photoVC.modalPresentationStyle = .custom
        present(photoVC, animated: true, completion: nil)
    }
    
}

extension MapVC {
    
    func retrieveUrls(withAnnotaion annotation: DroppablePin, completion: @escaping (_ completion: [String]) -> ()) {
        
        Alamofire.request(flickrURL(withAnnotaion: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            
            guard let json = response.result.value as? Dictionary<String, Any> else { return }
            guard let photos = (json["photos"] as? Dictionary<String, Any>)?["photo"] as? [Dictionary<String, Any>] else { return }
            var imageUrlArray = [String]()
            for photo in photos {
                let url = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!).jpg"
                imageUrlArray.append(url)
            }
            completion(imageUrlArray)
        }
    }
    
    func downloadImages(urlArray: [String], completion: @escaping CompletionHandler) {
        var t_images = [UIImage]()
        for url in urlArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else { return }
                t_images.append(image)
                self.progressLabel?.text = "\(self.images.count)/\(urlArray.count) PHOTOS LOADED"
                if t_images.count == urlArray.count {
                    self.images = t_images
                    completion (true)
                }
            })
        }
        
    }
    
    func cancelAllSessions () {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadTask) in
            sessionDataTask.forEach({$0.cancel()})
            downloadTask.forEach({$0.cancel()})
        }
    }
}

extension MapVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
        let photoVC = PhotoVC()
        photoVC.initData(withImage: images[indexPath.row])
        photoVC.modalPresentationStyle = .custom
        
        previewingContext.sourceRect = cell.contentView.frame
        return photoVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        present(viewControllerToCommit, animated: true, completion: nil)
    }
}






