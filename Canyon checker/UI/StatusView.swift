//
//  StatusView.swift
//  Canyon checker
//
//  Created by Sébastien Hannay on 01/08/2021.
//

import UIKit

class StatusView: UIView {
    
    @IBOutlet weak var sizeLabel: UILabel?
    
    override func draw(_ rect: CGRect) {
        self.sizeLabel?.layer.cornerRadius = (self.sizeLabel?.bounds.height ?? 8) * 0.5
    }
    
    
    var size : String? {
        didSet {
            self.sizeLabel?.text = size
        }
    }
    
    var color : UIColor = .systemGray {
        didSet {
            self.sizeLabel?.backgroundColor = color
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.sizeLabel?.text = size
        self.sizeLabel?.backgroundColor = color
    }

}
