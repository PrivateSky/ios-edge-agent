//
//  JsCameraUIView.swift
//  jscamera
//
//  Created by Yves Delacrétaz on 22.06.21.
//

import SwiftUI
import WebKit

struct CameraWebview: UIViewControllerRepresentable {
    typealias UIViewControllerType = CameraWebViewController
    
    func makeCoordinator() -> () {
        return Coordinator()
    }
    
    func makeUIViewController(context: Context) -> CameraWebViewController {
        return CameraWebViewController()
    }
    
    func updateUIViewController(_ uiViewController: CameraWebViewController, context: Context) {
        // required, unused
    }
    
    static func dismantleUIViewController(_ uiViewController: CameraWebViewController, coordinator: ()) {
        // not used
    }
    
}



struct CameraWebview_Previews: PreviewProvider {
    static var previews: some View {
        CameraWebview()
    }
}
