//
//  BikeCell.swift
//  Canyon checker
//
//  Created by Sébastien Hannay on 01/08/2021.
//

import UIKit

class BikeCell: UITableViewCell {
    
    var loading : Bool = false {
        didSet {
            stackView.isHidden = loading
            activityIndicator.isHidden = !loading
            loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        }
    }
    
    var bike : Bike? {
        didSet {
            bikePicture.image = bike?.image ?? UIImage(named: "CANYON_LOGO-transparent-black")
            label.text = bike?.name
            colorLabel.text = bike?.colorName
            if let leftHex = bike?.colors?.first {
                leftColor.backgroundColor = UIColor(hex: leftHex)
            }
            if let leftHex = bike?.colors?.last {
                rightColor.backgroundColor = UIColor(hex: leftHex)
            }
            stackView.clear()
            for data in bike?.availabilities ?? [BikeAvailability]() {
                if let statusView = UINib(nibName: "StatusView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? StatusView {
                    statusView.size = data.size
                    statusView.color = (data.available ? UIColor.systemGreen : UIColor.systemGray4).withAlphaComponent(0.8)
                    stackView.addArrangedSubview(statusView)
                }
            }
        }
    }

    @IBOutlet private weak var bikePicture: UIImageView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var colorLabel: UILabel!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var leftColor: UIView!
    @IBOutlet private weak var rightColor: UIView!
    
}
