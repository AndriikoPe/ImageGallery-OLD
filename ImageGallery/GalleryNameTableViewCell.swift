//
//  GalleryNameTableViewCell.swift
//  ImageGallery
//
//  Created by Пермяков Андрей on 4/8/19.
//  Copyright © 2019 Пермяков Андрей. All rights reserved.
//

import UIKit

class GalleryNameTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.delegate = self
        }
    }
    
    public func configureTextField(_ text: String) {
        textField.text = text
    }
    
    var resignationHandler: (() -> Void)?
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        resignationHandler?()
        textField.isUserInteractionEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
