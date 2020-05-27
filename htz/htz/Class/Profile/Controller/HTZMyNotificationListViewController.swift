//
//  HTZMyNotificationViewController.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/20.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZMyNotificationListViewController: HTZBaseViewController {
    
    private var dataArr = [HTZNotificationsModel?]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NetWorkRequest(API.notifications(page_index: 0, page_size: 10), completion: { (response) -> (Void) in
            printLog(response)
            self.loginButton.isHidden = response["code"].rawString() == "200"
            if response["code"].rawString() == "200" {
                self.dataArr = [HTZNotificationsModel].deserialize(from: response["data"].rawString()) ?? []
                self.tableView.reloadData()
            }
        }) { (error) -> (Void) in
            
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    @objc private func loginButtonClickAction() { // 跳转登陆
        HTZLoginManager.shared.jumpToWechatLogin(controller: self)
    }
    
    override func configSubView() {
        super.configSubView()
        
        view.addSubview(tableView)
        view.addSubview(loginButton)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        loginButton.snp.makeConstraints { (make) in
            make.center.equalTo(view)
        }
    }
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        //        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HTZMyNotificationCellReuseID")
        return tableView
    }()
    
    private lazy var loginButton: UIButton = {
        let loginButton = UIButton(type: .custom)
        loginButton.setTitle("登录后查看更多精彩内容", for: .normal)
        loginButton.setTitleColor(.darkText, for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonClickAction), for: .touchUpInside)
        loginButton.isHidden = true
        return loginButton
    }()
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZMyNotificationListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        var cell =  tableView.dequeueReusableCell(withIdentifier: "HTZMyNotificationCellReuseID", for: indexPath)
        var cell =  tableView.dequeueReusableCell(withIdentifier: "HTZMyNotificationCellReuseID")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HTZMyNotificationCellReuseID")
            let line = UIView()
            line.backgroundColor = .groupTableViewBackground
            cell?.contentView.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.left.bottom.right.equalToSuperview()
                make.height.equalTo(1)
            }
        }
        cell?.textLabel?.text = dataArr[indexPath.row]?.title
        cell?.detailTextLabel?.text = dataArr[indexPath.row]?.msg
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = HTZMyNotificationDetailViewController()
        vc.title = dataArr[indexPath.row]?.title
        vc.content = dataArr[indexPath.row]?.msg
        vc.content = "孟子原文：公孫丑曰：「何謂知言？」孟子曰：「詖辭知其所蔽；淫辭知其所陷；邪辭知其所離；遁辭知其所窮。生於其心，害於其事；發於其事，害於其政；聖人復起，必從吾言矣。」這段文章出現在孟子公孫丑上章，談到「不動心」的章節裡。在這段文章之前，孟子先是提到「我知言，我善養吾浩然之氣。」在解說了如何養浩然之氣之後，接著再補充了這段知言的說明。為什麼孟子談浩然正氣，要先提到「知言」這個主題呢？可見這個「言」字，對於能否養得起浩然正氣的關係非常重大，故而孟子要特別加以申論。什麼是真正的「言」呢？「言」者”心聲”也。對自己內心所發出的聲音，不論是好是壞，是正是邪，都瞭如指掌，叫做「知言」。「知言」就是瞭解自己當下的存心是正是邪，進而有機會掃除心內的無明，走向光明正大純潔無暇的坦途。有個很好的例子，可以突顯「知言」的重要性。美國曾經針對八千多位中學生做了一項心裡測驗及調查，這些受訪的學生裡面，百分之七十一的學生作過弊，百分之六十八的學生常打架，百分之三十五的學生在商店裡偷過東西。而品德測驗的結果，卻有百分之九十六的孩子，覺得他的品德良好！在這個活生生的真實例子裡面，可以看到這些孩子對於自己內心時常發生的不淨心思，簡直可以說是毫無所知！如此一來這些孩子還有進步的空間嗎？因此「知言」的功夫對於一個人的人格發展是非常重要的，而這也正是佛家「明心」的基礎功夫之一！然而孟子所謂的「知言」，指的不只是觀照出自己的心聲與習性，也包括能體察出他人的心聲與習性。道德經說「知人者智，自知者明」，不能知自己的言，簡直就是無明，豈能修得了自身；不能知別人的言，也就無法辨別是非曲直，豈有智慧可言。例如從一個人說的話、做的事，便可以知道誰好誰壞、誰忠誰奸，也可以知道誰在收買你、吹捧你、誰在貶損你、抵制你、誰是君子君而不黨、誰是小人黨而不群、誰是益者三友、誰是損者三友…分辨得出這些是非曲直，凡事清楚明白，這才是智慧。佛家所說的智慧，便是孟子的「知言」的效應。這個「言」字不止代表心思，當然也包括語言、舉止、行為在內。例如一個眼神也是言，當你說了一句話，惹得有一個人怒眼瞪著你，這眼神也已經明確的表示出他不喜歡你的心聲了！然而他的嘴巴卻說：「沒有啊！我哪有不喜歡你！」然而明眼人一看便知到他的內心根本不喜歡你！這個內心的想法透過他的眼神，早就表露無遺了，任他嘴巴再怎麼說喜歡你，此刻已經變得毫無意義了。所以從根本處來說，真正的「言」不是他在說什麼話，也不是在他的眼神、也不是在他的動作，真正的言只發生在一個人的「內心」！在他未說話，未動作之前，這個聲音就已經先在他的內心迴盪已久了！一切的「言」都是發自內心，心裏面的聲音、感受、念頭，才是真正的「言」！公孫丑問孟子什麼是「知言」？孟子用下面這段文章來解釋「知言」。曰：「詖辭知其所蔽；淫辭知其所陷；邪辭知其所離；遁辭知其所窮。生於其心，害於其事，發於其事，害於其政；聖人復起，必從吾言矣。」這段話裡面最重要的是「生於其心」這四個字。由於這四個字的指引，我們便可以清楚的知道，所謂詖辭、淫辭、邪辭、遁辭等等的「言」，指的不是一個人嘴巴所說的話或肢體做的事，而是指內心的聲音。內心一有貪嗔好惡的剎那，才是「言」的所在！「言」是發自心上的，這一點要先確定方向，才不會使這段文章的解釋有所偏差。「詖辭知其所蔽」：先解釋什麼是「辭」。辭有看不見的意思，也有語言、心聲的意思。躲在內心深處那個看不見的真話，就叫做「辭」，這裡的「辭」也就是知言的「言」，但「言」字比較容易被解讀為狹義的「語言」，所以在這裡改成「辭」字來突顯“躲在內心”的未盡之意。「辭」字還含有辭別、辭去的意思。意即「不存在你的面前，但卻存在背後的某處」的意思。所以古人常用「辭」這個字來影射「表面上看不到，卻隱藏在你內心的那個聲音」。"
        navigationController?.pushViewController(vc, animated: true)
        
    }
}
