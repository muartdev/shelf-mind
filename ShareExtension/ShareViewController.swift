//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Murat on 9.02.2026.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Extract shared URL
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            close()
            return
        }
        
        // Check if it's a URL
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                guard let self = self else { return }
                
                if let url = item as? URL {
                    DispatchQueue.main.async {
                        self.showShareUI(url: url.absoluteString, title: extensionItem.attributedContentText?.string)
                    }
                } else if let error = error {
                    print("Error loading URL: \(error)")
                    self.close()
                }
            }
        } else {
            close()
        }
    }
    
    private func showShareUI(url: String, title: String?) {
        let shareView = ShareExtensionView(
            url: url,
            suggestedTitle: title,
            onSave: { [weak self] in
                self?.close()
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )
        
        let hostingController = UIHostingController(rootView: shareView)
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }
    
    private func close() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
