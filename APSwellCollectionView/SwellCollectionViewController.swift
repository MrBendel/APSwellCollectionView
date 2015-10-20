//
//  SwellCollectionViewController.swift
//  APSwellCollectionView
//
//  Created by Andrew Poes on 10/20/15.
//  Copyright © 2015 Andrew Poes. All rights reserved.
//

import UIKit

class SwellCollectionViewController: UICollectionViewController {
    var expandedCellHeight: CGFloat {
        get { return _expandedCellHeight }
    }
    private var _expandedCellHeight: CGFloat = 0
    var contractedCellHeight: CGFloat {
        get { return _contractedCellHeight }
    }
    private var _contractedCellHeight: CGFloat = 0
    internal var swellLayout: SwellCollectionViewLayout?
    
    convenience init(expandedHeight: CGFloat, contractedHeight: CGFloat) {
        let swellLayout = SwellCollectionViewLayout(expandedHeight: expandedHeight, contractedHeight: contractedHeight)
        self.init(collectionViewLayout: swellLayout)
        self._expandedCellHeight = expandedHeight
        self._contractedCellHeight = contractedHeight
    }
    
    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        if let swellLayout = layout as? SwellCollectionViewLayout {
            self.swellLayout = swellLayout
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self._expandedCellHeight = CGRectGetHeight(UIScreen.mainScreen().bounds) * 0.45
        self._contractedCellHeight = CGRectGetHeight(UIScreen.mainScreen().bounds) * 0.15
        let swellLayout = SwellCollectionViewLayout(expandedHeight: _expandedCellHeight, contractedHeight: _contractedCellHeight)
        super.init(collectionViewLayout: swellLayout)
        self.swellLayout = swellLayout
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let collectionView = self.collectionView {
            collectionView.decelerationRate = UIScrollViewDecelerationRateFast
            collectionView.backgroundColor = UIColor(white: 1, alpha: 1)
        }
        self.swellLayout?.viewDidLoad()
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? SwellCollectionViewCell {
            cell.expandedHeight = self.expandedCellHeight
            cell.contractedHeight = self.contractedCellHeight
            cell.forceScrollUpdate()
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
}