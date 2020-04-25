//
//  HTZRefreshTool.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/24.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZRefreshTool: NSObject {
    
    static func prepareHeaderRefresh(_ tableView: UITableView, block:@escaping () -> ()) {
        
        let header = MJRefreshNormalHeader {
            block()
        }
        tableView.mj_header = header
        
        header.stateLabel?.font = UIFont.systemFont(ofSize: 15)
        header.lastUpdatedTimeLabel?.font = UIFont.systemFont(ofSize: 14)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            tableView.mj_header?.endRefreshing()
        }
        
    }

    static func prepareFooterRefresh(_ tableView: UITableView, block:@escaping () -> Void) {
        
        let footer = MJRefreshAutoNormalFooter {
            block()
        }
        tableView.mj_footer = footer
        
        footer.stateLabel?.font = UIFont.systemFont(ofSize: 15)
//        footer.lastUpdatedTimeLabel?.font =
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                tableView.mj_footer?.endRefreshing()
        }
        
    }

}
