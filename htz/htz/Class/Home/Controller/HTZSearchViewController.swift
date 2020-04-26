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
        
        addSearchController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.backBarButtonItem = nil
        let backItem = UIBarButtonItem(title: nil, style: .done, target: nil, action: nil)
//        navigationItem.backBarButtonItem = backItem
        navigationItem.leftBarButtonItem = backItem
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
        
        NetWorkRequest(API.search(key: searchText, output_offset: 0, max_outputs: 10)) {[weak self] (response) -> (Void) in
            
            printLog(response)
            if response["code"].stringValue == "200" {
                let dict = response["data"]
                let items = [HTZSutraItemModel].deserialize(from: dict["items"].rawString())
                let num_docs = dict["num_docs"]
                let tokens = dict["tokens"]
                
                printLog("items:==\(items!)")
                printLog("num_docs:==\(num_docs)")
                printLog("tokens:==\(tokens)")
                var arr:[String] = []
                for item in items! {
                    arr.append(item?.title ?? "--")
                }
                self?.searchSuggestions = arr
            }
            
        }
    }
    
    
    
    func searchViewController(_ searchViewController: PYSearchViewController!, didSelectSearchSuggestionAt indexPath: IndexPath!, searchBar: UISearchBar!) {
        
        printLog(indexPath.row)
        
        let vc = HTZPlayViewController.sharedInstance
        //        let music = HTZMusicModel()
        //        music.fileName = self.dataArr[indexPath.row]?.audio
        //        music.lrcName = self.dataArr[indexPath.row]?.lyric
        //        music.name = self.dataArr[indexPath.row]?.title
        //        music.icon = "chuan_xi_lu"
        //        music.singer = "dddd"
        //        music.singerIcon = "chuan_xi_lu"
//        vc.title = self.dataArr[indexPath.row]?.album_title
//        vc.setPlayerList(playList: dataArr as! [HTZMusicModel])
//        vc.playMusic(index: indexPath.row, isSetList: true)
//        let nav = UINavigationController(rootViewController: vc)
//        nav.modalPresentationStyle = .fullScreen
//        self.present(nav, animated: true, completion: nil)
    }
    
    func didClickCancel(_ searchViewController: PYSearchViewController!) {
        navigationController?.popViewController(animated: true)
    }
}

extension HTZSearchViewController: PYSearchViewControllerDataSource {
    
    func searchSuggestionView(_ searchSuggestionView: UITableView!, cellForRowAt indexPath: IndexPath!) -> UITableViewCell! {
        let cellID = "searchSuggestionCellID"
        var cell = searchSuggestionView.dequeueReusableCell(withIdentifier: cellID)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellID)
            
            cell?.textLabel?.textColor = .darkGray
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 14)
            cell?.backgroundColor = .clear
            let line = UIImageView(image: Bundle.py_imageNamed("cell-content-line"))
            line.py_height = 0.5
            line.alpha = 0.7
            line.py_x = CGFloat(kGlobelMargin)
            line.py_y = 43
            line.py_width = kScreenWidth;
            cell?.contentView.addSubview(line)
        }
        cell?.imageView?.image = Bundle.py_imageNamed("search")
        cell?.textLabel?.text = self.searchSuggestions[indexPath.row]
        return cell;
    }
}
