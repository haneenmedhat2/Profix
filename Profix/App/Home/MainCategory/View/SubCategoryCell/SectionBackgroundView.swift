//
//  SectionBackgroundView.swift
//  Profix
//
//  Created by Haneen on 06/01/2026.
//

import Foundation
import UIKit

final class SectionBackgroundView: UICollectionReusableView {
    
    static let elementKind = "SectionBackgroundView"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .grayBG
        layer.cornerRadius = 16
        layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
