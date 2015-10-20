//
//  ViewController.swift
//  APSwellCollectionView
//
//  Created by Andrew Poes on 10/20/15.
//  Copyright © 2015 Andrew Poes. All rights reserved.
//

import UIKit

extension UIImage {
    func predrawnImage() -> UIImage? {
        let source = self.CGImage
        var predrawn: UIImage?
        var width  = CGImageGetWidth(source)
        var height = CGImageGetHeight(source)
        if width > 375 {
            let ar: CGFloat = CGFloat(height) / CGFloat(width)
            width = 375
            height = Int(floor(CGFloat(width) * ar))
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGBitmapContextCreate(nil, width, height, 8, width * 4, colorSpace, CGImageAlphaInfo.PremultipliedFirst.rawValue)
        if ctx != nil {
            CGContextDrawImage(ctx, CGRect(x: 0, y: 0, width: width, height: height), source)
            if let output = CGBitmapContextCreateImage(ctx) {
                predrawn  = UIImage(CGImage: output, scale: 2, orientation: .Up)
            }
        }
        return predrawn
    }
}

class ViewController: SwellCollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let collectionView = self.collectionView {
            collectionView.registerClass(TestCell.self, forCellWithReuseIdentifier: TestCell.description())
            collectionView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TestCell.description(), forIndexPath: indexPath)
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        super.collectionView(collectionView, willDisplayCell: cell, forItemAtIndexPath: indexPath)
        if let cell = cell as? TestCell {
            cell.willDisplayCell(indexPath)
        }
    }
}

class TestCell: SwellCollectionViewCell {
    static let images = [
        "IMG_0225", "IMG_0245", "IMG_0310", "IMG_0463", "IMG_0494", "IMG_0506", "IMG_0572", "IMG_0637", "IMG_0639"
    ]
    
    static let tags = [
        "90's cliche", "High Life", "try-hard", "Thundercats", "Sriracha", "Post-ironic", "Scenester", "gentrify", "banjo freegan", "next level", "pickled", "farm-to-table", "YOLO", "biodiesel disrupt", "PBR&B", "Beards", "Intelligentsia", "VHS Truffaut", "Banksy", "LOMO"
    ]
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = UIViewContentMode.ScaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(44, weight: UIFontWeightBlack)
        label.textColor = UIColor.whiteColor()
        label.layer.shadowColor = UIColor.blackColor().CGColor
        label.layer.shadowOffset = CGSize()
        label.layer.shadowRadius = 4
        label.layer.shadowOpacity = 0.5
        label.layer.shouldRasterize = true
        label.layer.rasterizationScale = 0.3
        label.layer.drawsAsynchronously = true
        label.layer.minificationFilter = kCAFilterNearest
        label.layer.magnificationFilter = kCAFilterNearest
        return label
    }()
    
    var imageSetupCounter: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.blackColor()
        self.addSubview(self.imageView)
        self.addSubview(self.label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageSetupCounter++
        self.imageView.image = nil
    }
    
    override func updateScrollProgress() {
        super.updateScrollProgress()
        
        let xCenter = CGRectGetMidX(self.bounds)
        let yCenter = CGRectGetMidY(self.bounds)
        self.imageView.center = CGPoint(x: xCenter, y: yCenter)
        self.imageView.bounds = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: max(self.expandedHeight + 100, self.bounds.size.height))
        
        let drift = self.imageView.frame.size.height - self.expandedHeight
        self.imageView.transform = CGAffineTransformMakeTranslation(0, self.scrollProgress * -drift)
        self.imageView.alpha = self.restProgress * 0.7 + 0.2;
        self.label.center = CGPoint(x: xCenter, y: yCenter)
        self.label.layer.rasterizationScale = max(pow(self.restProgress, 2), 0.02)
        let scale = max(self.restProgress, 0.1) * 0.55 + 0.44;
        self.label.transform = CGAffineTransformMakeScale(scale, scale)
    }
    
    func willDisplayCell(indexPath: NSIndexPath) {
        self.label.text = TestCell.tags[indexPath.item%TestCell.tags.count]
        self.label.sizeToFit()
        self.label.center = CGPoint(x: CGRectGetMidX(self.bounds), y: CGRectGetMidY(self.bounds))
        
        let setupCounter = ++self.imageSetupCounter
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            let name = TestCell.images[indexPath.item%TestCell.images.count]
            if let path = NSBundle.mainBundle().pathForResource(name, ofType: "jpg") {
                if let image = UIImage(contentsOfFile: path) {
                    if let predrawn = image.predrawnImage() {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if setupCounter == self.imageSetupCounter {
                                UIView.transitionWithView(self.imageView, duration: 0.3, options: .AllowUserInteraction, animations: { () -> Void in
                                    self.imageView.image = predrawn
                                    }, completion: nil)
                            }
                        })
                    }
                }
            }
        }
    }
}
