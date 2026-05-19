import OSLog

// Shared application logger using the unified logging system.
// Use this throughout the app for consistent, filterable log output.
// Filter in Console.app: subsystem == "com.gaurav.MacPerformanceMonitor"
let appLogger = Logger(subsystem: "com.gaurav.MacPerformanceMonitor", category: "app")

// Category-specific loggers for finer-grained filtering
let monitorLogger = Logger(subsystem: "com.gaurav.MacPerformanceMonitor", category: "monitors")
let uiLogger = Logger(subsystem: "com.gaurav.MacPerformanceMonitor", category: "ui")
