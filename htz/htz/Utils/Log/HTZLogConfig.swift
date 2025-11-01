//
//  HTZLogConfig.swift
//  htz
//
//  Created by 黄庭禅 on 2025.
//  Copyright © 2025 黄庭禅. All rights reserved.
//

import Foundation

// MARK: - 日志配置管理器
public class HTZLogConfig {
    
    // MARK: - Properties
    public static let shared = HTZLogConfig()
    
    // MARK: - Private Properties
    private var logLevel: HTZLogLevel = .debug
    
    private init() {
        configureDefaultSettings()
    }
    
    // MARK: - Public Methods
    public func configureDefaultSettings() {
        #if DEBUG
        // 调试模式下使用详细日志
        setLogLevel(.debug)
        #else
        // 发布模式下使用简明日志
        setLogLevel(.info)
        #endif
    }
    
    public func setLogLevel(_ level: HTZLogLevel) {
        self.logLevel = level
        HTZLogger.shared.setLevel(level)
    }
    
    public func currentLogLevel() -> HTZLogLevel {
        return self.logLevel
    }
    
    // MARK: - 预留扩展功能
    public func enableFileLogging(_ enabled: Bool) {
        // TODO: 预留文件日志功能开关
    }
    
    public func setMaxFileSize(_ sizeInMB: Int) {
        // TODO: 预留最大文件大小设置
    }
    
    public func setMaxFileCount(_ count: Int) {
        // TODO: 预留最大文件数量设置
    }
    
    public func enableNetworkLogging(_ enabled: Bool) {
        // TODO: 预留网络请求日志功能开关
    }
    
    public func enableCrashLogging(_ enabled: Bool) {
        // TODO: 预留崩溃日志功能开关
    }
    
    public func clearLogs() {
        // TODO: 预留清理日志功能
    }
    
    public func exportLogs(to path: String) {
        // TODO: 预留导出日志功能
    }
}

// MARK: - 应用启动时配置日志
public extension HTZLogConfig {
    static func setup() {
        shared.configureDefaultSettings()
    }
}