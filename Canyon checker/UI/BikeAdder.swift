//
//  BikeAdder.swift
//  BikeAdder
//
//  Created by Sébastien Hannay on 04/08/2021.
//

import UIKit

class BikeAdder: UIViewController {
    
    var imageLoaded = false
    
    var canyonBike : CanyonBike? {
        didSet {
            populate()
        }
    }
    
    var sizesToCheck = Set<String>()
    
    private func populate() {
        if self.isViewLoaded {
            bikePicture.image = UIImage(named: "CANYON_LOGO-transparent-black")
            if let imageURL = canyonBike?.imageUrl {
                let task = URLSession(configuration: .default).dataTask(with: imageURL) { data, response, error in
                    if let data = data, error == nil {
                        DispatchQueue.main.async {
                            self.bikePicture.image = UIImage(data: data) ?? UIImage(named: "CANYON_LOGO-transparent-black")
                            self.imageLoaded = true
                        }
                    }
                }
                task.resume()
            }
            label.text = canyonBike?.name
            colorLabel.text = canyonBike?.colorName
            if let leftHex = canyonBike?.colors?.first {
                leftColor.backgroundColor = UIColor(hex: leftHex)
            }
            if let leftHex = canyonBike?.colors?.last {
                rightColor.backgroundColor = UIColor(hex: leftHex)
            }
            stackView.clear()
            for data in canyonBike?.sizeIds ?? [String]() {
                if let statusView = UINib(nibName: "StatusView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? StatusView {
                    statusView.size = data
                    statusView.color = .systemGray.withAlphaComponent(0.4)
                    statusView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectSize(_:))))
                    stackView.addArrangedSubview(statusView)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populate()
    }
    
    @objc func selectSize(_ sender : UITapGestureRecognizer) {
        if let view = sender.view as? StatusView, let size = view.size {
            if sizesToCheck.contains(size) {
                sizesToCheck.remove(size)
                view.color = .systemGray.withAlphaComponent(0.4)
            } else {
                sizesToCheck.insert(size)
                view.color = .systemGray
            }
        }
    }
    
    @IBAction func validate(_ sender: Any) {
        if sizesToCheck.count == 0 {
            let alert = UIAlertController(title: "No size selected", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if let canyonBike = canyonBike {
            let bike = Bike()
            bike.image = imageLoaded || canyonBike.imageUrl == nil ? bikePicture.image : (try? UIImage(data: Data(contentsOf: canyonBike.imageUrl!)) ?? UIImage(named: "CANYON_LOGO-transparent-black"))
            bike.sizesToCheck = canyonBike.sizeIds!.filter( { sizesToCheck.contains($0) })
            bike.selectedColor = canyonBike.selectedColorInfo?.id
            bike.canyonBike = canyonBike
            
            
            BikeChecker.shared.append(bike)
            self.dismiss(animated: true)
        }
    }
    
    @IBOutlet private weak var bikePicture: UIImageView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var colorLabel: UILabel!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var leftColor: UIView!
    @IBOutlet private weak var rightColor: UIView!

}
