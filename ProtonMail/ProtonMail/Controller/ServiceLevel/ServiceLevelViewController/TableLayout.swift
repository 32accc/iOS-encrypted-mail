//
//  TableLayout.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 15/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class TableLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        self.register(SeparatorDecorationView.self)
        self.scrollDirection = .vertical
        self.minimumLineSpacing = 0
        self.minimumInteritemSpacing = 0
    }
    
    var invalidatedOnce: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var separators: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        self.estimatedItemSize = .init(width: UIApplication.shared.keyWindow!.bounds.width * 0.70, height: 200)
    }
    
    override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool
    {
        // every separators frame depends on frame of some cell, which is calculated twice: attributes that FlowLayout calculates according to estimatedItemSize and then modified by cell according to its AutoLayout constraints. Here we are invalidating separator layout calculated BEFORE cells constraints were applied, so it will not be mispalced.
        if originalAttributes.representedElementKind == String(describing: SeparatorDecorationView.self) {
            return true
        }
        return super.shouldInvalidateLayout(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        fatalError()
    }
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        fatalError()
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil }
        guard let collectionView = collectionView else { return attributes }
        
        attributes.bounds.size.width = collectionView.bounds.width - sectionInset.left - sectionInset.right
        
        if indexPath.item > 0 {
            let inset: CGFloat = 20.0
            let thickness: CGFloat = 1
            let separator = UICollectionViewLayoutAttributes(forDecorationViewOfKind: String(describing: SeparatorDecorationView.self), with: indexPath)
            separator.zIndex = Int.max
            separator.frame = .init(x: attributes.frame.origin.x + inset,
                                    y: attributes.frame.origin.y - 1,
                                    width: attributes.bounds.size.width - inset,
                                    height: thickness)
            
            self.separators[indexPath] = separator
        }
        
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let allAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        var result: [UICollectionViewLayoutAttributes] = allAttributes.compactMap { attributes in
            return self.layoutAttributesForItem(at: attributes.indexPath)
        }
        result.append(contentsOf: self.separators.values )
        
        return result
    }
}

class SeparatorDecorationView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ProtonMail.TableSeparatorGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.ProtonMail.TableSeparatorGray
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        self.frame = layoutAttributes.frame
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let attributes: UICollectionViewLayoutAttributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes else {
            return layoutAttributes
        }
        attributes.zIndex = Int.max - 1
        return attributes
    }
}

