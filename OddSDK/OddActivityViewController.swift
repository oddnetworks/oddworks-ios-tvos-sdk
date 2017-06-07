//
//  OddActivityViewController.swift
//  OddSDK
//
//  Created by Patrick McConnell on 4/25/17.
//  Copyright © 2017 Patrick McConnell. All rights reserved.
//

// hat tip: http://stackoverflow.com/a/33558097

import UIKit

public class OddActivityViewController: UIViewController {

    //    private let activityView = ActivityView()
    
    public init(message: String, backgroundColor: UIColor, yOffset: CGFloat = 0) {
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
        
        view = ActivityView(message: message, boundingBoxBackgroundColor: backgroundColor, yOffset: yOffset)
    }
    
    convenience public init(message: String) {
        self.init(message: message, backgroundColor: UIColor(white: 0.0, alpha: 0.5), yOffset: 0)
    }
    
    convenience public init() {
        self.init(message: "Loading...", backgroundColor: UIColor(white: 0.0, alpha: 0.5), yOffset: 0)
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class ActivityView: UIView {
    
    #if os(iOS)
    let boxHeight: CGFloat = 160
    let boxWidth: CGFloat = 160
    #elseif os(tvOS)
    let boxHeight: CGFloat = 320
    let boxWidth: CGFloat = 320
    #endif
    
    
    let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    let boundingBoxView = UIView(frame: CGRect.zero)
    let messageLabel = UILabel(frame: CGRect.zero)
    var yOffset: CGFloat = 0
    
    init(message: String, boundingBoxBackgroundColor: UIColor, yOffset: CGFloat) {
        super.init(frame: CGRect.zero)
        
        self.yOffset = yOffset
        
        backgroundColor = UIColor(white: 0.0, alpha: 0.5)

        boundingBoxView.backgroundColor = boundingBoxBackgroundColor
        boundingBoxView.layer.cornerRadius = 12.0
        
        activityIndicatorView.startAnimating()
        
        messageLabel.text = message
        // this might need a rework?
        let font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        messageLabel.font = UIFont.boldSystemFont(ofSize: font.pointSize)
        messageLabel.textColor = UIColor.white
        messageLabel.textAlignment = .center
        messageLabel.shadowColor = UIColor.black
        messageLabel.shadowOffset = CGSize(width: 0.0, height: 1.0)
        messageLabel.numberOfLines = 0
        
        addSubview(boundingBoxView)
        addSubview(activityIndicatorView)
        addSubview(messageLabel)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        frame = CGRect(x: 0, y: self.yOffset, width: self.frame.width, height: self.frame.height)
        
        boundingBoxView.frame.size.width = self.boxWidth
        boundingBoxView.frame.size.height = self.boxHeight
        boundingBoxView.frame.origin.x = ceil((bounds.width / 2.0) - (boundingBoxView.frame.width / 2.0))
        boundingBoxView.frame.origin.y = ceil((bounds.height / 2.0) - (boundingBoxView.frame.height / 2.0))
        
        activityIndicatorView.frame.origin.x = ceil((bounds.width / 2.0) - (activityIndicatorView.frame.width / 2.0))
        activityIndicatorView.frame.origin.y = ceil((bounds.height / 2.0) - (activityIndicatorView.frame.height / 2.0))
        
        let messageLabelSize = messageLabel.sizeThatFits(CGSize(width: self.boxWidth - 20.0 * 2.0, height: CGFloat.greatestFiniteMagnitude))
        messageLabel.frame.size.width = messageLabelSize.width
        messageLabel.frame.size.height = messageLabelSize.height
        messageLabel.frame.origin.x = ceil((bounds.width / 2.0) - (messageLabel.frame.width / 2.0))
        messageLabel.frame.origin.y = ceil(activityIndicatorView.frame.origin.y + activityIndicatorView.frame.size.height + ((boundingBoxView.frame.height - activityIndicatorView.frame.height) / 4.0) - (messageLabel.frame.height / 2.0))
    }
}
