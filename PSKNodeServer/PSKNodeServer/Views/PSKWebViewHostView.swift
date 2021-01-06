//
//  PSKWebView.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 1/6/21.
//

import Foundation
import UIKit

class PSKWebViewHostView: UIView {
    
    override var safeAreaInsets: UIEdgeInsets {
        var superInsets = super.safeAreaInsets
        superInsets.bottom = 0
        return superInsets
    }
    
    func constrain(webView: UIView) {
        webView.removeFromSuperview()
        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.topAnchor.constraint(equalTo: webView.topAnchor),
            bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            leftAnchor.constraint(equalTo: webView.leftAnchor),
            rightAnchor.constraint(equalTo: webView.rightAnchor)
        ])
    }
}
