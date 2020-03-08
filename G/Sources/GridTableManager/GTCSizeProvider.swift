//
//  GTCSizeProvider.swift
//  G
//
//  Created by Eugene on 17.02.2020.
//  Copyright © 2020 Eugene. All rights reserved.
//

import UIKit

protocol GTCSizeProvider: AnyObject {
    
    func size<S: GTCSetupable>(in rect: CGRect, gtcModel: GTCellModel<S>) -> CGSize
    
}

final class GTCSizeProviderImp: GTCSizeProvider {
    
    private var prototypeCells: [String: AnyObject] = [:]
    private var sizeCache: [GCIndexPath: CGSize] = [:]
    
    func size<S: GTCSetupable>(in rect: CGRect, gtcModel: GTCellModel<S>) -> CGSize {
        
        let identifier = S.className
        
        guard let cachedSize = sizeCache[gtcModel.gcIndexPath] else {
            
            if prototypeCells[identifier] == nil {
                prototypeCells.updateValue(S.createSelf(), forKey: identifier)
            }
            
            (prototypeCells[identifier] as! S).setup(gtcModel: gtcModel)
            
            let size = (prototypeCells[identifier] as! S).size(in: rect, gtcModel: gtcModel)
            
            sizeCache.updateValue(size, forKey: gtcModel.gcIndexPath)
            
            return size
        }
        
        return cachedSize
    }

}
