//
//  HTZSearchViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/16.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZSearchViewController: PYSearchViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.delegate = self
//        self.backButton = nil
        self.backBarButtonItem = nil
        
        addSearchController()
    }
    
    private func addSearchController() {
        
        
//        self.searchViewController.didSearchBlock = {(searchViewController, searchBar, searchText) in
//            print(searchText)
//        }
        
//        let nav = HTZNavigationController(rootViewController: self.searchViewController)
//        self.addChild(nav)
//        self.view.addSubview(nav.view)
//        nav.view.frame = self.view.bounds
    }
    
//    private lazy var searchViewController: PYSearchViewController = {
//        let searchViewController = PYSearchViewController(hotSearches: nil, searchBarPlaceholder: nil)
//        searchViewController?.searchHistoryStyle = PYSearchHistoryStyle.default
//        searchViewController?.delegate = self
//        return searchViewController!
//    }()

}

/// PYSearchViewControllerDelegate
extension HTZSearchViewController: PYSearchViewControllerDelegate {
    
    func searchViewController(_ searchViewController: PYSearchViewController!, searchTextDidChange searchBar: UISearchBar!, searchText: String!) {
        
//        searchViewController.searchSuggestions =
        
        NetWorkRequest(API.search(key: searchText, output_offset: 0, max_outputs: 10)) { (response) -> (Void) in
            
            printLog(response)
            if response["code"].stringValue == "200" {
                let dict = response["data"]
                let items = [HTZSutraItemModel].deserialize(from: dict["items"].rawString())
                let num_docs = dict["num_docs"]
                let tokens = dict["tokens"]
                
                printLog("items:==\(items!)")
                printLog("num_docs:==\(num_docs)")
                printLog("tokens:==\(tokens)")
            }
            
        }
    }
    
    func didClickCancel(_ searchViewController: PYSearchViewController!) {
        navigationController?.popViewController(animated: true)
    }
}
