//
//  CollectionViewCell.swift
//  SKUFilterDemo
//
//  Created by 李响 on 2019/1/3.
//  Copyright © 2019 swift. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    func set(text: String?) {
        label.text = text
    }
    
    func set(enabled: Bool) {
        label.textColor = enabled ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    }
    
    func set(selected: Bool) {
        label.textColor = selected ? #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1) : label.textColor
    }
}
