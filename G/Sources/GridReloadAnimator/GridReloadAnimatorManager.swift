//
//  GridReloadAnimatorManager.swift
//  G
//
//  Created by Eugene on 19.02.2020.
//  Copyright © 2020 Eugene. All rights reserved.
//

import UIKit

public protocol GridReloadAnimatorManagerReleaser: AnyObject {
    func releaseAnimatorManager()
}

public protocol GridReloadAnimatorManager: AnyObject {

    var animator: GridReloadAnimator { get }
    var animatorReleaser: GridReloadAnimatorManagerReleaser? { get set }

    func willDisplay(_ cell: UIView, type: GCIndexPath.CellType, section: Int, gridRect: CGRect)
    func handleCellsAnimation()
}

open class GridReloadAnimatorManagerImp: GridReloadAnimatorManager {

    // MARK: - Properties

    public weak var animatorReleaser: GridReloadAnimatorManagerReleaser?
    public let animator: GridReloadAnimator

    let itemDelay: TimeInterval
    private(set) var sections: [Int: Section] = [:]
    private(set) var gridRect: CGRect = .zero

    // MARK: - Init

    init(itemDelay: TimeInterval,
         animator: GridReloadAnimator)
    {
        self.animator = animator
        self.itemDelay = itemDelay
    }

    // MARK: - Public methods
    
    public func willDisplay(_ cell: UIView, type: GCIndexPath.CellType, section: Int, gridRect: CGRect) {
        
        self.gridRect = gridRect
        
        if sections[section] == nil {
            sections.updateValue(.init(header: nil, cells: [], footer: nil), forKey: section)
        }

        switch type {
        case .cell:
            sections[section]!.cells.append(cell)
            
        case .header:
            sections[section]!.header = cell

        case .footer:
            sections[section]!.footer = cell
        }
        
    }
    
    open func handleCellsAnimation() {
        
        var headerDelay: TimeInterval = 0
        var cellDelay: TimeInterval = 0
        var footerDelay: TimeInterval = 0
        
        for (idx, section) in sections.sorted(by: { $0.key < $1.key }) {
            
            if let header = section.header {
                headerDelay += idx == 0 ? 0 : itemDelay
                cellDelay = headerDelay
                animator.animate(header, delay: headerDelay, gridRect: gridRect)
            }
            
            section.cells.forEach({ cell in
                cellDelay += itemDelay
                animator.animate(cell, delay: cellDelay, gridRect: gridRect)
            })
            
            footerDelay += cellDelay
            if let footer = section.footer {
                footerDelay += itemDelay
                animator.animate(footer, delay: footerDelay, gridRect: gridRect)
            }
            
            headerDelay = footerDelay
            
        }
        
        animatorReleaser?.releaseAnimatorManager()
        
    }

}

public extension GridReloadAnimatorManagerImp {
    
    struct Section {
        var header: UIView?
        var cells: [UIView]
        var footer: UIView?
    }

}
