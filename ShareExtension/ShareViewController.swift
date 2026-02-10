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
        
        // Extract shared item
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            close()
            return
        }
        
        // Check for URL or Title
        let urlType = UTType.url.identifier
        let textType = UTType.plainText.identifier
        
        if itemProvider.hasItemConformingToTypeIdentifier(urlType) {
            itemProvider.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] (item, error) in
                guard let self = self else { return }
                
                if let url = item as? URL {
                    self.proceedWithURL(url.absoluteString, title: extensionItem.attributedContentText?.string)
                } else if let urlString = item as? String {
                    self.proceedWithURL(urlString, title: extensionItem.attributedContentText?.string)
                } else if let urlData = item as? Data, let urlString = String(data: urlData, encoding: .utf8) {
                    self.proceedWithURL(urlString, title: extensionItem.attributedContentText?.string)
                } else {
                    print("❌ ShareExtension: Could not cast item to URL/String/Data. Item: \(String(describing: item))")
                    self.close()
                }
            }
        } else if itemProvider.hasItemConformingToTypeIdentifier(textType) {
            itemProvider.loadItem(forTypeIdentifier: textType, options: nil) { [weak self] (item, error) in
                guard let self = self else { return }
                
                if let text = item as? String, text.lowercased().hasPrefix("http") {
                    self.proceedWithURL(text, title: nil)
                } else {
                    print("❌ ShareExtension: Item conforms to text but is not a valid URL. Item: \(String(describing: item))")
                    self.close()
                }
            }
        } else {
            print("❌ ShareExtension: Item does not conform to URL or Text type. Types: \(itemProvider.registeredTypeIdentifiers)")
            close()
        }
    }
    
    private func proceedWithURL(_ url: String, title: String?) {
        DispatchQueue.main.async {
            self.showShareUI(url: url, title: title)
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
