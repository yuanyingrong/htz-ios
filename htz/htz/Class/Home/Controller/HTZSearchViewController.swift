//
//  HTZSearchViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/16.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZSearchViewController: UIViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()

        
        addSearchController()
    }
    
    private func addSearchController() {
        
        
        self.searchViewController.didSearchBlock = {(searchViewController, searchBar, searchText) in
            print(searchText)
        }
        
        let nav = HTZNavigationController(rootViewController: self.searchViewController)
        self.addChild(nav)
        self.view.addSubview(nav.view)
        nav.view.frame = self.view.bounds
    }
    
    private lazy var searchViewController: PYSearchViewController = {
        let searchViewController = PYSearchViewController(hotSearches: nil, searchBarPlaceholder: nil)
        searchViewController?.searchHistoryStyle = PYSearchHistoryStyle.default
        searchViewController?.delegate = self
        return searchViewController!
    }()

}

/// PYSearchViewControllerDelegate
extension HTZSearchViewController: PYSearchViewControllerDelegate {
    
    func searchViewController(_ searchViewController: PYSearchViewController!, searchTextDidChange searchBar: UISearchBar!, searchText: String!) {
        
//        searchViewController.searchSuggestions =
    }
}
