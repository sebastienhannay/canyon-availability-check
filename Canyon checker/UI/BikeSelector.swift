//
//  BikeSeletor.swift
//  BikeSeletor
//
//  Created by Sébastien Hannay on 04/08/2021.
//

import UIKit
import WebKit

class BikeSelector : UIViewController, WKNavigationDelegate {
    
    private let prefKey = "last_visited_page"
    
    var bike : Bike? {
        didSet {
            DispatchQueue.main.async {
                self.bookmarkButton.isEnabled = self.bike != nil
            }
        }
    }
    
    @IBOutlet weak var webView : WKWebView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var bookmarkButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        let url = UserDefaults.standard.url(forKey: prefKey) ?? URL(string: "https://www.canyon.com/")!
        webView.load(URLRequest(url: url))
        BikeChecker.shared.bike(from: url, completion: { self.bike = $0 })
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "URL", let url = self.webView.url {
            UserDefaults.standard.set(url, forKey: prefKey)
            BikeChecker.shared.bike(from: url, completion: { self.bike = $0 })
        }
        DispatchQueue.main.async {
            if keyPath == "title" {
                if let title = self.webView.title {
                    self.title = title
                }
            }
            if keyPath == "canGoBack" {
                self.backButton.isEnabled = self.webView.canGoBack
            }
            if keyPath == "canGoForward" {
                self.forwardButton.isEnabled = self.webView.canGoForward
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let host = navigationAction.request.url?.host {
            if host.contains("canyon.com") {
                decisionHandler(.allow)
                return
            }
        }
        decisionHandler(.cancel)
    }
    
    @IBAction func goBack(_ sender: Any) {
        webView.goBack()
    }
    
    @IBAction func goForward(_ sender: Any) {
        webView.goForward()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let bikeAdder = segue.destination as? BikeAdder  {
            if bike != nil {
                bikeAdder.bike = bike
            } else if let url = webView.url {
                BikeChecker.shared.bike(from: url, completion: { bikeAdder.bike = $0})
            }
        }
    }
}
