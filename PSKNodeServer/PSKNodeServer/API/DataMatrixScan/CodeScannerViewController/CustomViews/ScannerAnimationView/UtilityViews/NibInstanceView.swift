//
//  NibInstanceView.swift

//

import UIKit

class NibInstanceView: UIView {
    
    private(set) var contentView: UIView?
    private var nibName: String? {
        return NSStringFromClass(self.classForCoder).substringAfterFirstOccurence(of: ".")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadViewFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadViewFromNib()
    }
    
    override var backgroundColor: UIColor? {
        didSet {
            contentView?.backgroundColor = backgroundColor
        }
    }
    
    func viewDidLoadFromNib() {
    
    }

    private func loadViewFromNib() {
        guard let nibName = self.nibName else { return }
        let nib: UINib = UINib(nibName: nibName, bundle: Bundle(for: self.classForCoder))
        let views = nib.instantiate(withOwner: self, options: nil)
        
        guard let firstView = views.first as? UIView else { return }
        contentView = firstView
        addSubview(firstView)
        firstView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: firstView.bottomAnchor),
            topAnchor.constraint(equalTo: firstView.topAnchor),
            leftAnchor.constraint(equalTo: firstView.leftAnchor),
            rightAnchor.constraint(equalTo: firstView.rightAnchor)
        ])
        
        viewDidLoadFromNib()
        backgroundColor = .clear
    }
}

fileprivate extension String {
    func substringAfterFirstOccurence(of string: String) -> String {
        guard let occurence = self.range(of: string) else { return self }
        return String(self[occurence.upperBound...])
    }
}
