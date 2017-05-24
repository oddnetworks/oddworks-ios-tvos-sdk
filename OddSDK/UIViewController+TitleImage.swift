//
//  UIViewController+TitleImage.swift
//  
//
//  Created by Patrick McConnell on 8/20/15.
//  Copyright (c) 2015 Patrick McConnell. All rights reserved.
//

import UIKit

extension UIViewController {

  func setImageForTitleView( _ imageName: String, size: CGSize, centerForMissingRightButton: Bool ) {
    if let headerImage = UIImage(named: imageName) {
      let imageView = UIImageView(image: headerImage)
      imageView.contentMode = .scaleAspectFit
      self.navigationItem.titleView = imageView

      self.navigationItem.titleView?.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
    
    if centerForMissingRightButton == true {
      addFakeBackButton()
    }
  }
  
  func addFakeBackButton() {
    // this is a hack to center the logo image when only one bar button item is present.
    // iOS automatically gives the title view all the available space and centers the
    // title within.
    // we are adding a fake right bar button to compensate
    let backButtonWidth: CGFloat = 58
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView:  UIView(frame: CGRect(x: 0, y: 0, width: backButtonWidth, height: 0)) )
  }
  
}
