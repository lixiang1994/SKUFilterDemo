//
//  CollectionReusableView.swift
//  SKUFilterDemo
//
//  Created by 李响 on 2019/1/3.
//  Copyright © 2019 swift. All rights reserved.
//

import UIKit

class CollectionReusableView: UICollectionReusableView {
        
    @IBOutlet weak var label: UILabel!
    
    func set(text: String?) {
        label.text = text
    }
}
