//
//  ScannerAnimationView.swift
//  TestLayerMask
//
//  Created by Costin Andronache on 1/5/21.
//

import UIKit

class ScannerAnimationView: NibInstanceView {
    
    override var bounds: CGRect {
        didSet {
            lineView?.stop()
            lineView?.begin(from: .top)

        }
    }
    
    @IBOutlet private var maskingView: MaskView?
    @IBOutlet private var lineView: LineAnimationView?
    @IBOutlet private var focusView: ScannerFocusView?
    
    override func viewDidLoadFromNib() {
        lineView?.lineColor = .systemGreen
        maskingView?.contentView = lineView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        focusView?.center = center
        maskingView?.set(shape: UIBezierPath(rect: focusView!.frame).cgPath)
    }
    
    func focusOn(rect: CGRect, completion: (() -> Void)?) {
        
        lineView?.stop()
        maskingView?.set(shape: UIBezierPath(rect: rect).cgPath, animatingWith: .init(duration: 0.26, timingFunction: .init(name: .easeInEaseOut)))
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            self.focusView?.frame = rect
        } completion: { (_) in
            self.focusView?.animateColorSwitch(to: .white, completion: completion)
        }
        
    }
    
}
