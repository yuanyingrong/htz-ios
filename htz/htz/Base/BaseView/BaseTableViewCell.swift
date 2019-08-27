//
//  BaseTableViewCell.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class BaseTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        configInterface()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configInterface()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configInterface() {
        configSelf()
        configSubView()
        configConstraint()
    }
    
    public func configSelf() {}
    
    public func configSubView() {}
    
    public func configConstraint() {}
    
    public func configCellData(_ data: Any) {}
    
    public func calculateCellHeight(_ data: Any) {}
}
