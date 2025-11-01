//
//  HTZLogger.swift
//  htz
//
//  Created by 黄庭禅 on 2025.
//  Copyright © 2025 黄庭禅. All rights reserved.
//

import Foundation

// MARK: - 日志级别枚举
public enum HTZLogLevel: Int, CaseIterable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case severe = 5
    
    var description: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .severe: return "SEVERE"
        }
    }
    
    var color: String {
        switch self {
        case .verbose: return "\u{001B}[0;37m" // 白色
        case .debug: return "\u{001B}[0;36m"   // 青色
        case .info: return "\u{001B}[0;32m"    // 绿色
        case .warning: return "\u{001B}[0;33m" // 黄色
        case .error: return "\u{001B}[0;31m"   // 红色
        case .severe: return "\u{001B}[0;35m"  // 紫色
        }
    }
}

// MARK: - 日志类型协议
public protocol HTZLoggerType {
    func log(level: HTZLogLevel, tag: String, message: String, file: String, function: String, line: Int)
    func setLevel(_ level: HTZLogLevel)
    func isEnabled(_ level: HTZLogLevel) -> Bool
}

// MARK: - 基础日志工具
public class HTZLogger: HTZLoggerType {
    
    // MARK: - Properties
    private var minimumLogLevel: HTZLogLevel = .debug
    private let queue = DispatchQueue(label: "com.htz.logger.queue", qos: .utility)
    
    // MARK: - Singleton
    public static let shared = HTZLogger()
    
    private init() {}
    
    // MARK: - Public Methods
    public func setLevel(_ level: HTZLogLevel) {
        queue.sync {
            self.minimumLogLevel = level
        }
    }
    
    public func isEnabled(_ level: HTZLogLevel) -> Bool {
        return level.rawValue >= minimumLogLevel.rawValue
    }
    
    public func log(level: HTZLogLevel, tag: String, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        // 检查日志级别
        guard isEnabled(level) else { return }
        
        // 格式化日志消息
        let formattedMessage = formatMessage(level: level, tag: tag, message: message, file: file, function: function, line: line)
        
        // 输出日志
        queue.async {
            print(formattedMessage)
            self.writeToLogFile(message: formattedMessage)
        }
    }
    
    // MARK: - Private Methods
    private func formatMessage(level: HTZLogLevel, tag: String, message: String, file: String, function: String, line: Int) -> String {
        let timestamp = getCurrentTimestamp()
        let fileName = (file as NSString).lastPathComponent
        
        // 格式: [时间戳] [级别] [标签] [文件名:行号] 函数名 - 消息
        return "[\(timestamp)] [\(level.description)] [\(tag)] [\(fileName):\(line)] \(function) - \(message)"
    }
    
    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    
    // 预留：写入日志文件功能
    private func writeToLogFile(message: String) {
        // TODO: 实现日志文件写入功能
        #if DEBUG
        // 在调试模式下，可以选择不写入文件，只在控制台输出
        #else
        // 在发布模式下，可以实现文件写入
        #endif
    }
    
    // MARK: - 预留扩展能力
    public func addOutput(_ output: HTZLoggerType) {
        // TODO: 预留多输出源功能
    }
    
    public func addFilter(_ filter: (HTZLogLevel, String, String) -> Bool) {
        // TODO: 预留日志过滤功能
    }
    
    public func flush() {
        // TODO: 预留刷新日志缓冲区功能
    }
    
    public func cleanupOldLogs() {
        // TODO: 预留清理旧日志功能
    }
}

// MARK: - 便捷日志方法
public extension HTZLogger {
    func verbose(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .verbose, tag: tag, message: message, file: file, function: function, line: line)
    }
    
    func debug(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, tag: tag, message: message, file: file, function: function, line: line)
    }
    
    func info(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, tag: tag, message: message, file: file, function: function, line: line)
    }
    
    func warning(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, tag: tag, message: message, file: file, function: function, line: line)
    }
    
    func error(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, tag: tag, message: message, file: file, function: function, line: line)
    }
    
    func severe(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .severe, tag: tag, message: message, file: file, function: function, line: line)
    }
}

// MARK: - 日志宏定义（便于使用）
public struct HTZLog {
    
    // MARK: - 便捷方法
    public static func verbose(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        HTZLogger.shared.verbose(tag, message, file: file, function: function, line: line)
    }
    
    public static func debug(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        HTZLogger.shared.debug(tag, message, file: file, function: function, line: line)
    }
    
    public static func info(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        HTZLogger.shared.info(tag, message, file: file, function: function, line: line)
    }
    
    public static func warning(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        HTZLogger.shared.warning(tag, message, file: file, function: function, line: line)
    }
    
    public static func error(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        HTZLogger.shared.error(tag, message, file: file, function: function, line: line)
    }
    
    public static func severe(_ tag: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        HTZLogger.shared.severe(tag, message, file: file, function: function, line: line)
    }
    
    // MARK: - 预留配置方法
    public static func setLevel(_ level: HTZLogLevel) {
        HTZLogger.shared.setLevel(level)
    }
    
    public static func isEnabled(_ level: HTZLogLevel) -> Bool {
        return HTZLogger.shared.isEnabled(level)
    }
}