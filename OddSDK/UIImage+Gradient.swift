//
//  UIImage+Gradient.swift
//  
//
//  Created by Patrick McConnell on 8/20/15.
//  Copyright (c) 2015 Patrick McConnell. All rights reserved.
//

import UIKit
import AVFoundation


class ImageViewWithGradient: UIImageView {
  var edgeColor: UIColor = .clear
  var centerColor: UIColor = .black
  
  let myGradientLayer: CAGradientLayer = CAGradientLayer()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }
  
  class func initWithFrame(_ frame: CGRect, edgeColor: UIColor, centerColor: UIColor) -> ImageViewWithGradient {
    let ivg = ImageViewWithGradient(frame: frame)
    ivg.edgeColor = edgeColor
    ivg.centerColor = centerColor
    ivg.setup()
    return ivg
  }
  
  func setup() {
    myGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
    myGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
    let colors: [CGColor] = [
      edgeColor.cgColor,
      centerColor.cgColor,
      edgeColor.cgColor
    ]
    myGradientLayer.colors = colors
    myGradientLayer.isOpaque = false
    myGradientLayer.locations = [0.0, 0.5, 1.0]
    self.layer.addSublayer(myGradientLayer)
  }
  
  override func layoutSubviews() {
    myGradientLayer.frame = self.layer.bounds
  }
}
