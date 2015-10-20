//
//  SwellCollectionViewLayout.swift
//  APSwellCollectionView
//
//  Created by Andrew Poes on 10/20/15.
//  Copyright © 2015 Andrew Poes. All rights reserved.
//

import UIKit

class SwellCollectionViewLayout: UICollectionViewLayout {
    var expandedCellHeight: CGFloat {
        get { return _expandedCellHeight }
    }
    private var _expandedCellHeight: CGFloat = 0
    var contractedCellHeight: CGFloat {
        get { return _contractedCellHeight }
    }
    private var _contractedCellHeight: CGFloat = 0
    private var needsResetLayout: Bool = false
    
    private var calculatedCellRects = [CGRect]()
    private let dragInterval: CGFloat = 300
    private var cachedContentHeight: CGFloat = 0
    private var cachedTotalItems: Int = 0
    private var initialScrollPosition = CGPoint()

    convenience init(expandedHeight: CGFloat, contractedHeight: CGFloat) {
        self.init()
        self._expandedCellHeight = expandedHeight
        self._contractedCellHeight = contractedHeight
        self.setNeedsResetLayout()
    }
    
    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setNeedsResetLayout() {
        self.needsResetLayout = true
    }
    
    func resetLayout() {
        self.needsResetLayout = false
        self.cachedContentHeight = 0
        if let collectionView = self.collectionView {
            self.cachedTotalItems = collectionView.numberOfItemsInSection(0)
        }
    }
    
    func viewDidLoad() {
        if let collectionView = self.collectionView {
            collectionView.panGestureRecognizer.addTarget(self, action: "handlePanGesture:")
        }
    }
    
    // MARK: Layout
    
    override func collectionViewContentSize() -> CGSize {
        if let collectionView = self.collectionView {
            if self.cachedTotalItems == 0 || self.cachedContentHeight > 0 {
                return CGSize(width: CGRectGetWidth(collectionView.bounds), height: self.cachedContentHeight)
            } else {
                let height = CGRectGetHeight(collectionView.bounds) + CGFloat(self.cachedTotalItems - 1) * self.dragInterval
                self.cachedContentHeight = height
                return CGSize(width: CGRectGetWidth(collectionView.bounds), height: height)
            }
        }
        return CGSize()
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        
        if self.needsResetLayout {
            self.resetLayout()
        }
        
        if let collectionView = self.collectionView {
            self.calculatedCellRects.removeAll(keepCapacity: true)
            let contentOffsetY = collectionView.contentOffset.y
            var overallProgress = contentOffsetY / self.dragInterval
            overallProgress = max(min(overallProgress, CGFloat(self.cachedTotalItems)), 0)
            var curIndex = Int(floor(overallProgress))
            var transitionProgress = 1 - fmod(overallProgress, 1)
            if curIndex > self.cachedTotalItems - 1 {
                transitionProgress = 0
            }
            curIndex = max(min(curIndex, self.cachedTotalItems - 1), 0)
            let width = CGRectGetWidth(collectionView.bounds)
            var cellFrame = CGRect()
            for index in 0 ..< self.cachedTotalItems {
                var cellSize = CGSize(width: width, height: self.contractedCellHeight)
                if index < curIndex {
                    cellFrame = CGRect()
                }
                else if index > curIndex {
                    let isNextItem: Bool = index == curIndex + 1
                    let isInRange: Bool = curIndex + 1 < self.cachedTotalItems
                    if isNextItem && isInRange {
                        cellSize.height = self.contractedCellHeight + (self.expandedCellHeight - self.contractedCellHeight) * (1 - transitionProgress)
                        
                    }
                    // order matters!
                    cellFrame.origin.y = CGRectGetMaxY(cellFrame)
                    cellSize.height = floor(cellSize.height * 2) / 2
                    cellFrame.size = cellSize
                }
                else /*if index == curIndex*/ {
                    cellSize.height = self.contractedCellHeight + (self.expandedCellHeight - self.contractedCellHeight) * transitionProgress
                    if contentOffsetY < 0 {
                        cellSize.height -= contentOffsetY
                    }
                    cellSize.height = floor(cellSize.height * 2) / 2
                    cellFrame.size = cellSize
                    cellFrame.origin.y = contentOffsetY - self.contractedCellHeight * (1 - transitionProgress)
                }
                self.calculatedCellRects.append(cellFrame)
            }
        }
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for (index, cellRect) in self.calculatedCellRects.enumerate() {
            if CGRectIsInBounds(cellRect, bounds: rect) {
                let indexPath = NSIndexPath(forItem: index, inSection: 0)
                if let attributes = self.layoutAttributesForItemAtIndexPath(indexPath) {
                    layoutAttributes.append(attributes)
                }
            }
        }
        return layoutAttributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        if let frame = self.frame(forIndexPath: indexPath) {
            attributes.frame = frame
        }
        attributes.zIndex = indexPath.item
        return attributes
    }
    
    override func targetContentOffsetForProposedContentOffset(var proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var proposedIndex = self.index(forContentOffset: proposedContentOffset)
        let currentIndex = self.index(forContentOffset: self.initialScrollPosition)
        let hasVelocity: Bool = fabs(velocity.y) > 0
        if proposedIndex == currentIndex && hasVelocity {
            proposedIndex += velocity.y > 0 ? 1 : -1
        }
        proposedIndex = max(min(proposedIndex, self.cachedTotalItems - 1), 0)
        proposedContentOffset.y = self.dragInterval * CGFloat(proposedIndex)
        return proposedContentOffset;
    }
    
    func index(forContentOffset contentOffset: CGPoint) -> Int {
        let cellPercent = contentOffset.y / self.dragInterval
        var currentIndex = max(min(Int(floor(cellPercent)), self.cachedTotalItems - 1), 0)
        // fraction mod to 1 to get just the decimal part of the number
        let percentOffset = 1 - fmod(cellPercent, 1)
        if percentOffset < 0.5 && currentIndex < self.cachedTotalItems - 1 {
            currentIndex = currentIndex + 1
        }
        return currentIndex
    }
    
    // MARK: PanGestureRecognizer Logic
    
    func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        if let collectionView = self.collectionView {
            if gestureRecognizer.state == .Began {
                self.initialScrollPosition = collectionView.contentOffset
            }
        }
    }
    
    // MARK: Utils
    
    func CGRectIsInBounds(rect: CGRect, bounds: CGRect) -> Bool {
        let isEmpty = CGRectIsEmpty(rect)
        let hasHeight = CGRectGetHeight(rect) > 0
        let intersects = CGRectIntersectsRect(rect, bounds)
        return !isEmpty && hasHeight && intersects
    }

    func frame(forIndexPath indexPath: NSIndexPath) -> CGRect? {
        let index = indexPath.item
        if index >= 0 && index < self.calculatedCellRects.count {
            return self.calculatedCellRects[index]
        }
        return nil
    }
}
