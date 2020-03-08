//
//  GTManager.swift
//  G
//
//  Created by Eugene on 19.02.2020.
//  Copyright © 2020 Eugene. All rights reserved.
//

import UIKit

protocol GTPresentable: AnyObject {
    var gridManager: GTManagerProtocol { get }
}

protocol GTManagerProtocol {
    
    typealias Animation = UITableView.RowAnimation
    
    var sectionsCount: Int { get }
    
    func cellsCount(section: Int) -> Int?
    
    func header(section: Int) -> GTManagerCell?
    
    func footer(section: Int) -> GTManagerCell?
    
    func cells(section: Int) -> [GTManagerCell]
    
    func cell(section: Int, index: Int) -> GTManagerCell
    
    func reloadData(sections: [GridSection], animator: GridReloadAnimatorFactory?)
    
    func appendSections(_ sections: [GridSection], with animation: Animation?)
    
//    TODO
//    func insertSections(_ sections: [GridSection], _ pattern: GridSourceMatchPattern, with animation: Animation?)
    
//    TODO
//    func reloadSections(_ sections: [GridSection], _ pattern: GridSourceMatchPattern, with animation: Animation?)
    
//    TODO
//    func deleteSections(_ pattern: GridSourceMatchPattern, animation: Animation?)
    
    func appendCells(_ cells: [GTCellProvider], section: Int, animation: Animation?)
    
//    TODO
//    func insertCells(_ cells: [GTCellProvider], section: Int, pattern: GridSourceMatchPattern, animation: Animation?)
    
    func reloadCells(_ cells: [GTCellProvider], section: Int, pattern: GridSourceMatchPattern, animation: Animation?)
    
    func deleteCells(section: Int, pattern: GridSourceMatchPattern, animation: Animation?)
    
    func updateHeader(_ header: GTCellProvider, section: Int, animation: Animation?)
    
    func updateFooter(_ footer: GTCellProvider, section: Int, animation: Animation?)
    
}

extension GTManagerProtocol {
    
    func cell(indexPath: IndexPath) -> GTManagerCell {
        return cell(section: indexPath.section, index: indexPath.item)
    }
    
}

final class GTManager: GTManagerProtocol {
    
    unowned var tableView: UITableView!
    
    private let sizeProvider: GTCSizeProvider
    private let gridSource: GridSourceProtocol
    private var reloadAnimator: GridReloadAnimatorManager?
    
    init(gridSource: GridSourceProtocol = GridSource(),
        sizeProvider: GTCSizeProvider = GTCSizeProviderImp())
    {
        self.gridSource = gridSource
        self.sizeProvider = sizeProvider
    }
    
    // MARK: - Public methods that should be used inside View Contoller
    
    // cell
    func cellSize(forIndexPath indexPath: IndexPath, in rect: CGRect) -> CGSize {
        return cell(indexPath: indexPath).size(in: rect, sizeProvider: sizeProvider)
    }
    
    func configureCell(forIndexPath indexPath: IndexPath) -> UITableViewCell {
        return cell(indexPath: indexPath).configureCell(tableView)
    }
    
    // header
    func headerSize(forSection section: Int, in rect: CGRect) -> CGSize {
        return header(section: section)?.size(in: rect, sizeProvider: sizeProvider) ?? .zero
    }
    
    func configureHeader(forSection section: Int) -> UITableViewHeaderFooterView? {
        guard let header = header(section: section) else { return nil }
        let inTableHeader = tableView.headerView(forSection: section)
        return header.configureHeaderFooter(inTableHeader)
    }
    
    // footer
    func footerSize(forSection section: Int, in rect: CGRect) -> CGSize {
        return footer(section: section)?.size(in: rect, sizeProvider: sizeProvider) ?? .zero
    }
    
    func configureFooter(forSection section: Int) -> UITableViewHeaderFooterView? {
        guard let footer = footer(section: section) else { return nil }
        let inTableFooter = tableView.footerView(forSection: section)
        return footer.configureHeaderFooter(inTableFooter)
    }
    
    // Raw reload animator
    func willDisplayCell(_ cell: UITableViewCell, section: Int, gridRect: CGRect = .zero) {
        let rect = gridRect == .zero ? tableView.frame : gridRect
        reloadAnimator?.willDisplay(cell, type: .cell, section: section, gridRect: rect)
    }
    
    func willDisplayHeader(_ header: UIView, section: Int, gridRect: CGRect = .zero) {
        let rect = gridRect == .zero ? tableView.frame : gridRect
        reloadAnimator?.willDisplay(header, type: .header, section: section, gridRect: rect)
    }
    
    func willDisplayFooter(_ footer: UIView, section: Int, gridRect: CGRect = .zero) {
        let rect = gridRect == .zero ? tableView.frame : gridRect
        reloadAnimator?.willDisplay(footer, type: .footer, section: section, gridRect: rect)
    }
    
}


// MARK: - GTManagerProtocol Methods
extension GTManager {
    
    var sectionsCount: Int {
        return gridSource.sectionsCount
    }
    
    func cellsCount(section: Int) -> Int? {
        return gridSource.itemsCount(section: section)
    }
    
    func header(section: Int) -> GTManagerCell? {
        guard let header = gridSource.headerItem(section: section) else { return nil }
        return (header as! GTManagerCell)
    }
    
    func footer(section: Int) -> GTManagerCell? {
        guard let footer = gridSource.footerItem(section: section) else { return nil }
        return (footer as! GTManagerCell)
    }
    
    func cells(section: Int) -> [GTManagerCell] {
        return gridSource.items(section: section) as! [GTManagerCell]
    }
    
    func cell(section: Int, index: Int) -> GTManagerCell {
        return gridSource.item(section: section, item: index) as! GTManagerCell
    }
    
    func reloadData(sections: [GridSection], animator: GridReloadAnimatorFactory?) {
        
        func waitForCellsLoaded() {
            DispatchQueue.main.async {
                guard !self.tableView.visibleCells.isEmpty else {
                    waitForCellsLoaded()
                    return
                }
                self.reloadAnimator!.handleCellsAnimation()
            }
        }
        
        reloadAnimator = animator?.animatorManager
        reloadAnimator?.animatorReleaser = self
        
        tableView.reloadData()

        if let _ = reloadAnimator {
            waitForCellsLoaded()
        }
        
    }
    
    func appendSections(_ sections: [GridSection], with animation: Animation?) {
        
        let appendRange = gridSource.appendSections(sections)
        
        updateTable(animation: animation) { animation in
            tableView.insertSections(IndexSet(integersIn: appendRange), with: animation)
        }
    }
    
    func appendCells(_ cells: [GTCellProvider], section: Int, animation: Animation?) {
        
        let items = cells.map({ $0.gtcModel })
        let appendIndexPaths = gridSource.appendItems(items, section: section)
        
        updateTable(animation: animation) { animation in
            tableView.insertRows(at: appendIndexPaths, with: animation)
        }
    }
    
    func reloadCells(_ cells: [GTCellProvider], section: Int, pattern: GridSourceMatchPattern, animation: Animation?) {
        
        let items = cells.map({ $0.gtcModel })
        let reloadIndexPaths = gridSource.reloadItems(items, section: 0, pattern: pattern)
        
        updateTable(animation: animation) { animation in
            tableView.reloadRows(at: reloadIndexPaths, with: animation)
        }
        
    }
    
    func deleteCells(section: Int, pattern: GridSourceMatchPattern, animation: Animation?) {
        
        let deleteeIndexPaths = gridSource.deleteItems(section: section, pattern: pattern)
        
        updateTable(animation: animation) { animation in
            tableView.deleteRows(at: deleteeIndexPaths, with: animation)
        }
        
    }
    
    func updateHeader(_ header: GTCellProvider, section: Int, animation: Animation?) {
        
        gridSource.updateHeader(header.gtcModel, atSection: section)
        
        guard let headerView = tableView.headerView(forSection: section) else {
            updateTable(animation: animation) { animation in
                tableView.reloadSections(IndexSet(arrayLiteral: section), with: animation)
            }
            return
        }
        
        _ = self.header(section: section)!.configureHeaderFooter(headerView)
    }
    
    func updateFooter(_ footer: GTCellProvider, section: Int, animation: Animation?) {
        
        gridSource.updateFooter(footer.gtcModel, atSection: section)
        
        guard let footerView = tableView.footerView(forSection: section) else {
            updateTable(animation: animation) { animation in
                tableView.reloadSections(IndexSet(arrayLiteral: section), with: animation)
            }
            return
        }
        
        _ = self.footer(section: section)!.configureHeaderFooter(footerView)
    }
    
}


// MARK: - GridReloadAnimatorManagerReleaser
extension GTManager: GridReloadAnimatorManagerReleaser {
    
    func releaseAnimatorManager() {
        reloadAnimator = nil
    }
    
}


// MARK: - Private methods
private extension GTManager {
    
    private func updateTable(animation: Animation?, block: (Animation) -> Void) {
        guard let animation = animation else {
            tableView.reloadData()
            return
        }
        block(animation)
    }
    
}
