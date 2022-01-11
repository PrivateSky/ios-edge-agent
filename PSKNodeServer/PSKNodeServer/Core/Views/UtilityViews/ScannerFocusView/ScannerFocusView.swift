//
//  ScannerFocusView.swift
//  TestLayerMask
//
//  Created by Costin Andronache on 1/4/21.
//

import UIKit

class ScannerFocusView: NibInstanceView {
    @IBOutlet private var cornerViews: [UIView]?
    @IBOutlet private var sizeConstraints: [NSLayoutConstraint]?
    @IBOutlet private var lengthConstraints: [NSLayoutConstraint]?
    
    var color: UIColor = .gray {
        didSet {
            cornerViews?.forEach({
                $0.backgroundColor = color
            })
        }
    }
    
    var size: CGFloat = 15.0 {
        didSet {
            sizeConstraints?.forEach({
                $0.constant = size
            })
            layoutIfNeeded()
        }
    }
    
    var length: CGFloat = 50.0 {
        didSet {
            lengthConstraints?.forEach({
                $0.constant = length
            })
            layoutIfNeeded()
        }
    }
    
    override func viewDidLoadFromNib() {
        length = 15
        color = .green
        size = 5
    }
    
    func animateColorSwitch(to: UIColor, completion: (() -> Void)?) {
        switchColors(currentLoop: 0, maxLoops: 5, from: [to, color], completion: completion)
    }
    
    private func switchColors(currentLoop: Int, maxLoops: Int, from: [UIColor], completion: (() -> Void)?) {
        
        color = from[currentLoop % from.count]
        if currentLoop == maxLoops {
            completion?()
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.switchColors(currentLoop: currentLoop + 1, maxLoops: maxLoops, from: from, completion: completion)
        }
    }
    
}
