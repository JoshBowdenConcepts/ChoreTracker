//
//  CloudKitExtensions.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CloudKit

extension CKRecord {
    /// Safely gets a string value from a CloudKit record
    func safeString(forKey key: String) -> String? {
        return self[key] as? String
    }
    
    /// Safely gets a date value from a CloudKit record
    func safeDate(forKey key: String) -> Date? {
        return self[key] as? Date
    }
    
    /// Safely gets a UUID value from a CloudKit record
    func safeUUID(forKey key: String) -> UUID? {
        if let uuidString = self[key] as? String {
            return UUID(uuidString: uuidString)
        }
        return nil
    }
}

extension CKError {
    /// Returns a user-friendly error message
    var userFriendlyMessage: String {
        switch self.code {
        case .networkUnavailable:
            return "Network unavailable. Please check your connection."
        case .notAuthenticated:
            return "Please sign in to iCloud to sync your chores."
        case .quotaExceeded:
            return "iCloud storage quota exceeded. Please free up space."
        case .serviceUnavailable:
            return "iCloud service is temporarily unavailable. Please try again later."
        case .requestRateLimited:
            return "Too many requests. Please wait a moment and try again."
        default:
            return "An error occurred: \(self.localizedDescription)"
        }
    }
}

extension NSError {
    /// Checks if error is a CloudKit error
    var isCloudKitError: Bool {
        return domain == CKError.errorDomain
    }
    
    /// Converts to CKError if possible
    var asCloudKitError: CKError? {
        guard isCloudKitError else { return nil }
        return CKError(_nsError: self)
    }
}

