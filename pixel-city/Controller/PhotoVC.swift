//
//  PhotoVC.swift
//  pixel-city
//
//  Created by Brian  Crowley on 01/12/2017.
//  Copyright © 2017 Brian Crowley. All rights reserved.
//

import UIKit

class PhotoVC: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var passedImage : UIImage!
    
    func initData(withImage image: UIImage) {
        passedImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = passedImage
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(PhotoVC.handleSwipe))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
    }

    @objc func handleSwipe () {
        dismiss(animated: true, completion: nil)
    }
}
