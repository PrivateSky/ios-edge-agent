//
//  LineAnimationView.swift
//  TestLayerMask
//
//

import UIKit

class LineAnimationView: UIView {
    
    struct Constraints {
        let bottomSpaceToSV: NSLayoutConstraint
        let height: NSLayoutConstraint
    }
    
    enum Direction {
        case top
        case bottom
        
        var opposite: Direction {
            switch self {
            case .top:
                return .bottom
            case .bottom:
                return .top
            }
        }
    }
    
    func begin(from: Direction) {
        setConstaintFor(direction: from)
        layoutIfNeeded()
        continueTo(direction: from.opposite)
    }
    
    func stop() {
        currentAnimator?.stopAnimation(true)
    }
    
    private var currentAnimator: UIViewPropertyAnimator?
    
    var lineColor: UIColor = .clear {
        didSet {
            lineViewInfo.view.backgroundColor = lineColor
        }
    }
    
    private lazy var lineViewInfo: (view: UIView, constraints: Constraints) = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        let bottomSpace = view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        let left = leftAnchor.constraint(equalTo: view.leftAnchor)
        let right = rightAnchor.constraint(equalTo: view.rightAnchor)
        let height = view.heightAnchor.constraint(equalToConstant: 5)
        NSLayoutConstraint.activate([left, right, height, bottomSpace])
        return (view, Constraints(bottomSpaceToSV: bottomSpace, height: height))
    }()
    
    
    private func continueTo(direction: Direction) {
        setConstaintFor(direction: direction)
        
        let currentAnimator = UIViewPropertyAnimator(duration: 2.5, curve: .easeInOut) { [weak self] in
            self?.layoutIfNeeded()
        }
        
        currentAnimator.addCompletion { [weak self] (position) in
            if position == .end {
                self?.continueTo(direction: direction.opposite)
            }
        }
        
        currentAnimator.startAnimation()
        self.currentAnimator = currentAnimator
    }
    
    private func setConstaintFor(direction: Direction) {
        let value: CGFloat = {
            switch direction {
            case .top:
                return -frame.height + lineViewInfo.constraints.height.constant
            case .bottom:
                return 0
            }
        }()
        lineViewInfo.constraints.bottomSpaceToSV.constant = value
    }
}
