//
//  ErrorHandler.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CloudKit
import CoreData

/// Centralized error handling with user-friendly messages
enum ErrorHandler {
    
    /// Converts any error to a user-friendly message
    static func userFriendlyMessage(for error: Error) -> String {
        // CloudKit errors
        if let ckError = error as? CKError {
            return cloudKitMessage(for: ckError)
        }
        
        if let nsError = error as NSError?,
           nsError.isCloudKitError,
           let ckError = nsError.asCloudKitError {
            return cloudKitMessage(for: ckError)
        }
        
        // Core Data errors
        if let nsError = error as NSError?,
           nsError.domain == NSCocoaErrorDomain {
            return coreDataMessage(for: nsError)
        }
        
        // Generic error
        return "Something went wrong. Please try again."
    }
    
    private static func cloudKitMessage(for error: CKError) -> String {
        switch error.code {
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        case .notAuthenticated:
            return "Please sign in to iCloud in Settings to sync your progress."
        case .quotaExceeded:
            return "Your iCloud storage is full. Please free up space to continue syncing."
        case .serviceUnavailable:
            return "iCloud is temporarily unavailable. Please try again in a moment."
        case .requestRateLimited:
            return "Too many requests. Please wait a moment before trying again."
        case .invalidArguments:
            return "Invalid information provided. Please check your input and try again."
        case .partialFailure:
            return "Some operations failed. Please try again."
        case .serverRecordChanged:
            return "The data was changed by another device. Please refresh and try again."
        case .serverResponseLost:
            return "Connection lost. Please check your internet and try again."
        case .unknownItem:
            return "The item was not found. It may have been deleted."
        default:
            return "A sync error occurred. Please try again."
        }
    }
    
    private static func coreDataMessage(for error: NSError) -> String {
        // Core Data validation errors are in the range 1000-1999
        let validationErrorRange = 1000..<2000
        
        if validationErrorRange.contains(error.code) {
            // Core Data validation error codes
            switch error.code {
            case 101: // NSValidationErrorMinimum
                return "Invalid data provided. Please check your input."
            case 102: // NSValidationErrorMaximum
                return "Value too large. Please enter a smaller value."
            case 152: // NSValidationErrorRelationshipLacksMinimumCount
                return "Required information is missing. Please fill in all required fields."
            case 153: // NSValidationErrorRelationshipExceedsMaximumCount
                return "Too many items. Please remove some and try again."
            default:
                return "Invalid data provided. Please check your input and try again."
            }
        }
        
        // Other Core Data errors
        switch error.code {
        case 134030: // NSPersistentStoreIncompatibleVersionHashError
            return "Database version mismatch. The app needs to update its data."
        default:
            return "A data error occurred. Please try again."
        }
    }
}

