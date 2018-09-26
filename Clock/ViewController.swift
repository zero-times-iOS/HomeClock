//
//  ViewController.swift
//  Clock
//
//  Created by 梦烙时光 on 2018/9/18.
//  Copyright © 2018年 StarHoa. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    
    fileprivate let isHome = false
    
    fileprivate enum State {
        case Default//白
        case Error//红
        case Normal//绿
    }
    
    fileprivate struct CmdMsg {
        static let facetime = "FT01"
    }
    
    fileprivate static let facetimeAddress = "121349450@qq.com";
    
    fileprivate var timer: Timer?
    fileprivate var foldClock: XLFoldClock?
    fileprivate var stateBg: UIView?
    fileprivate var logMsg: String! {
        set {
            DispatchQueue.main.async {
                if newValue == "" {
                    self.logTextView.text = newValue
                }
                else {
                    self.logTextView.text += newValue
                }
            }
        }
        
        get {
            return self.logTextView.text
        }
    }
    @IBOutlet var reqButton: UIButton!
    @IBOutlet var adminStateBg: UIView!
    @IBOutlet var logTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isHome {
            setupHomeUI()
            loginHome()
            addDelegate()
        }
        else {
            setupAdminUI()
            loginAdmin()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

// home
extension ViewController: RCIMClientReceiveMessageDelegate {
    
    @objc fileprivate func updateTimeLabel() {
        foldClock?.date = Date.init()
    }
    
    // 添加接收代理
    fileprivate func addDelegate() {
        
        RCIMClient.shared()?.setReceiveMessageDelegate(self, object: nil)
    }
    
    // 登录home用户
    fileprivate func loginHome() {
        
        let homeToken = "xaNplDoLZa/i7mUoWHeXcwrCondFKKmS+TvK6DD3IQmHA6P9GZVhLe4vm/q2xmryoQKXV7GlfmTLsyUrvgYvEg=="
        RCIMClient.shared()?.connect(withToken: homeToken, success: { [unowned self]userId in
            self.changeHomeState(state: .Normal)
        }, error: { error in
            self.changeHomeState(state: .Error)
        }, tokenIncorrect: { })
        
    }
    
    //  更改状态
    fileprivate func changeHomeState(state: State) {
        
        var color = UIColor.white
        switch state {
        case .Normal: color = .green
        case .Error: color = .red
        default:
            break
        }
        
        DispatchQueue.main.async { [unowned self] in
            self.stateBg?.backgroundColor = color == .green ? self.reqButton.backgroundColor! : color
        }
    }
    
    // home界面初始化
    fileprivate func setupHomeUI() {
        
        foldClock = XLFoldClock.init()
        foldClock?.frame = self.view.bounds
        foldClock?.date = Date.init()
        self.view.addSubview(foldClock!)
        
        stateBg = UIView.init(frame: CGRect.init(x: 20, y: 10, width: 20, height: 20))
        stateBg?.layer.cornerRadius = 10
        changeHomeState(state: .Default)
        foldClock?.addSubview(stateBg!)
        
        let updateDateTimeInterval: TimeInterval = 1
        timer = Timer.scheduledTimer(timeInterval: updateDateTimeInterval, target: self, selector: #selector(updateTimeLabel), userInfo: nil, repeats: true)
    }
    
    // 拔打facetime
    fileprivate func startFacetime() {
        if let url = URL.init(string: "facetime://"+ViewController.facetimeAddress) {
            UIApplication.shared.openURL(url)
        }
    }
    
    // 接收到消息
    func onReceived(_ message: RCMessage!, left nLeft: Int32, object: Any!) {
        
        let onlyResponseUserId = "admin"
        if onlyResponseUserId == message.senderUserId {
            
            if let data = message.content.encode() {
                
                if let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
                    
                    if let contentValue = dict?["content"] as? String {
                        if contentValue == CmdMsg.facetime {
                            startFacetime()
                        }
                    }
                }
                
            }
        }
    }
}

// admin
extension ViewController {
    
    // 发送通讯指令
    @IBAction func requestMessage(_ sender: UIButton) {
        
        let cmdMsg = RCTextMessage.init(content: CmdMsg.facetime)
        RCIMClient.shared()?.sendMessage(RCConversationType.ConversationType_PRIVATE, targetId: "home", content: cmdMsg, pushContent: nil, pushData: nil, success: { code in
            self.logMsg = "发送请求通讯命令成功: \(code) \r\n"
        }, error: { (errCode, code) in
            self.logMsg = "发送请求通讯命令异常: \(code) || \(errCode) \r\n"
        })
        
    }
    
    // 清除log信息
    @IBAction func clear(_ sender: UIButton) {
        
        self.logMsg = ""
    }
    
    // 初始化adminUI界面
    fileprivate func setupAdminUI() {
        
        adminStateBg?.layer.cornerRadius = 10
        changeAdminState(state: .Default)
        
        logTextView.layer.cornerRadius = 10
        
        reqButton.layer.cornerRadius = 10
    }
    
    // 更新状态
    fileprivate func changeAdminState(state : State) {
        
        var color = UIColor.white
        switch state {
        case .Normal: color = .green
        case .Error: color = .red
        default:
            break
        }
        
        DispatchQueue.main.async { [unowned self] in
            self.adminStateBg?.backgroundColor = state == .Normal ? self.reqButton.backgroundColor ?? .green : color
        }
    }
    
    
    // 登录admin用户
    fileprivate func loginAdmin() {
        
        let adminToken = "7y8/gCmdnPyDCkQhxc3pMgrCondFKKmS+TvK6DD3IQmHA6P9GZVhLVMhZ6/6sfFXsYLLBLdd4XVN48UVVQBv2g=="
        RCIMClient.shared()?.connect(withToken: adminToken, success: { userId in
            
            if let userId = userId {
                self.changeAdminState(state: .Normal)
                self.logMsg = "登录成功，用户: \(userId) \r\n"
            }
            
        }, error: { error in
            self.logMsg = "登录异常，error code: \(error.rawValue) \r\n"
            self.changeAdminState(state: .Error)
            
        }, tokenIncorrect: {
        })
    }
    
    
    
    
}
