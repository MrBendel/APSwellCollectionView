//
//  SwellCollectionViewCell.swift
//  APSwellCollectionView
//
//  Created by Andrew Poes on 10/20/15.
//  Copyright © 2015 Andrew Poes. All rights reserved.
//

import UIKit

class SwellCollectionViewCell: UICollectionViewCell {
    var scrollProgress: CGFloat {
        get { return _scrollProgress }
    }
    private var _scrollProgress: CGFloat = 0 {
        didSet {
            if fabs(oldValue - _scrollProgress) < CGFloat(FLT_EPSILON) {
                self.setNeedsScrollUpdate()
            }
        }
    }
    var restProgress: CGFloat {
        get { return _restProgress }
    }
    private var _restProgress: CGFloat = 0
    var expandedHeight: CGFloat = 0
    var contractedHeight: CGFloat = 0
    private var needsScrollUpdate: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // setup the defaults
        self.clipsToBounds = true
        self.expandedHeight = 1
        self.contractedHeight = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Updates
    
    func setNeedsScrollUpdate() {
        self.needsScrollUpdate = true
    }
    
    func forceScrollUpdate() {
        self.setNeedsScrollUpdate()
        self.updateScrollProgress()
    }
    
    func updateScrollProgress() {
        if (self.needsScrollUpdate) {
            self.needsScrollUpdate = false
        } else {
            return
        }
        
        self._restProgress = (CGRectGetHeight(self.bounds) - self.contractedHeight) / (self.expandedHeight - self.contractedHeight)
    }
    
    // MARK: Layouts
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        
        if let superview = self.superview where CGRectGetHeight(superview.bounds) > 0 {
            if let superduperview = superview.superview {
                let converted = superview.convertPoint(self.frame.origin, toView: superduperview)
                let scrollProgress = converted.y / CGRectGetHeight(superview.bounds)
                self._scrollProgress = scrollProgress
                self.updateScrollProgress()
            }
        }
    }
    
    // MARK: overrides
    
    override var bounds: CGRect {
        didSet {
            if CGRectEqualToRect(oldValue, bounds) == false {
                self.setNeedsScrollUpdate()
            }
        }
    }
}

