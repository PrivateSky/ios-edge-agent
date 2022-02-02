//
//  MaskView.swift
//  TestLayerMask
//
//  Created by Costin Andronache on 1/5/21.
//

import UIKit

class MaskView: UIView {
    
    struct AnimationOptions {
        let duration: TimeInterval
        let timingFunction: CAMediaTimingFunction
    }
    
    private var shape: CGPath?
    
    private lazy var maskLayer: CAShapeLayer = {
        let mask = CAShapeLayer()
        layer.mask = mask
        return mask
    }()
        
    var contentView: UIView? {
        willSet {
            contentView?.removeFromSuperview()
        }
        didSet {
            contentView?.frame = bounds
            contentView.map(self.addSubview(_:))
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView?.frame = bounds
        set(shape: shape)
    }
    
    func set(shape: CGPath?, animatingWith options: AnimationOptions? = nil) {
        self.shape = shape
        guard let shape = shape else {
            layer.mask = nil
            return
        }
        
        let path = UIBezierPath(cgPath: shape)
        path.append(UIBezierPath(rect: bounds))
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        maskLayer.fillColor = UIColor.black.cgColor
        let newPath = path.reversing().cgPath
        
        if let options = options {
            let anim = CABasicAnimation(keyPath: "path")
            anim.fromValue = maskLayer.path
            anim.toValue = newPath
            anim.fillMode = .forwards
            anim.duration = options.duration
            anim.isRemovedOnCompletion = false
            anim.timingFunction = options.timingFunction
            maskLayer.add(anim, forKey: nil)
        } else {
            maskLayer.path = path.reversing().cgPath
        }
    }
}
