---
name: iOS Chore Tracking App
overview: Build an iOS chore tracking app with advanced recurrence patterns, multi-user household support via CloudKit sharing, and comprehensive task management features using CloudKit private database with local storage.
todos: []
---

# iOS Chore Tracking App Development Plan

## Architecture Overview

The app will use:

- **CloudKit Private Database**: Primary data storage with automatic iCloud sync
- **Core Data + CloudKit**: Local persistence with CloudKit integration
- **CloudKit Sharing**: Enable household members to share chore lists
- **SwiftUI**: Modern iOS UI framework
- **Combine**: Reactive programming for data flow

## App Store Metadata & Branding

### Family-Friendly Designations

- **"Designed for Families"**: Label app with this designation in App Store Connect
  - Helps parents identify family-appropriate apps
  - Aligns with Kids Category compliance
  - Signals commitment to family privacy

### Terminology Guidelines

- **Avoid "tracking" terminology**: Use "progress" instead
  - "Chore progress" instead of "chore tracking"
  - "Progress monitoring" instead of "tracking"
  - "Completion progress" instead of "completion tracking"
  - This avoids negative connotations and privacy concerns
  - More positive, family-friendly language

## Privacy & Compliance

### Data Protection Principles

- **Data Minimization**: Only collect data necessary for app functionality
- **Local-First Storage**: All data stored locally with CloudKit sync (no external servers)
- **Private Database**: CloudKit private database ensures data is only accessible to the user's iCloud account
- **No Third-Party Analytics**: No tracking or analytics services that share data externally
- **No Advertising**: No ad networks or advertising SDKs

### App Store "Made for Kids" / Kids Category Compliance

To qualify for the Kids Category and "Made for Kids" designation:

1. **No Advertising**:

   - ❌ No ad networks or advertising SDKs
   - ❌ No in-app purchases for ads
   - ✅ App must be completely ad-free

2. **Two Very Different Meanings of "Analytics"**:

**❌ Disallowed (for kids apps)** - This is what Apple and COPPA care about:

- Analytics you (the developer) can see
- Cross-user metrics
- Engagement tracking
- Funnel analysis
- Anything that leaves the family's iCloud
- Even if "only parents use it," if you can see it → not allowed
- ❌ No Firebase Analytics
- ❌ No Mixpanel
- ❌ No Amplitude
- ❌ No behavioral profiling
- ❌ No third-party SDKs that collect user data
- ❌ No analytics services that send data to external servers

**✅ Allowed (and safe)** - Personal, on-device or iCloud-scoped analytics:

- Personal statistics that only the parent can see within their iCloud account
- Examples: "Chores completed this week", "Streaks", "Most skipped chore", "Average completion time"
- All data stays in the family's iCloud account
- Data never leaves the family's iCloud account and is not visible to developer
- **Key rule**: If the data never leaves the family's iCloud account and is not visible to you (the developer), it is not considered analytics in Apple's sense. It's just app functionality.
- ✅ Apple Analytics (basic, aggregated) is acceptable if used

3. **Restricted Data Collection**:

   - ❌ Avoid free-form notes unless truly necessary for functionality
   - ❌ Avoid photos unless absolutely required
   - ✅ Use structured data inputs instead of free-form text where possible
   - ✅ If notes are needed, keep them minimal and structured

4. **Privacy-First Design**:

   - All data stays within user's iCloud account
   - No external data transmission
   - No social features that expose user data

### COPPA Compliance (Children's Online Privacy Protection Act)

Since the app may be used by children under 13:

1. **Parental Consent Required**:

   - When creating a supervised account, parent must provide consent
   - Record `parentalConsentDate` in User record
   - Display consent form/agreement in app
   - Store consent acknowledgment

2. **Limited Data Collection for Minors**:

   - Only collect data necessary for chore tracking
   - No location data beyond what's needed for timezone
   - No behavioral tracking
   - No social features that expose child data

3. **Parental Controls**:

   - Parents have full visibility into supervised account activity
   - Parents can delete supervised account and all associated data
   - Parents control what data is shared with guardians

4. **Clear Parent Control Model**:

   - **Parent is the owner** of the chore set and all data
   - **Supervised user permissions** (if they have their own device):
     - ✅ Can mark chores complete
     - ✅ Can add personal chores (optional, parent-controlled)
     - ❌ Cannot delete chores or templates
     - ❌ Cannot modify recurrence rules
     - ❌ Cannot share with others
   - **Parent permissions**:
     - ✅ View everything (all supervised account activity)
     - ✅ Create/edit/delete all chores and templates
     - ✅ Revoke access instantly (unshare supervised account)
     - ✅ Delete all data (per supervised user or entire family)
     - ✅ Control what supervised users can do
   - This maps cleanly to CloudKit sharing permissions (parent = owner, supervised = participant with limited permissions)

5. **Data Deletion & Revocation (Required)**:

   - **Delete all data**:
     - Per supervised user: Delete all their chore instances, templates, and statistics
     - Per family: Delete entire household data
     - UI must provide clear deletion options in settings
   - **Unshare (Revoke Access)**:
     - Parent can instantly remove supervised user's access
     - CloudKit share is revoked
     - Supervised user's local data is removed (via CloudKit sync)
   - **Automatic Orphan Cleanup**:
     - When supervised account is deleted, clean up all associated records
     - Remove ChoreInstance records assigned to deleted user
     - Handle ChoreTemplate records created by deleted user
     - CloudKit helps with cascading deletes, but UI must handle edge cases
   - **Deletion UI Requirements**:
     - Clear warnings before deletion
     - Confirmation dialogs
     - Progress indicators for large deletions
     - Verification that deletion completed successfully

### App Store Requirements

1. **Privacy Manifest**:

   - Declare all data collection types
   - Specify data usage purposes
   - List any third-party SDKs (minimal/none in this app)

2. **Privacy Nutrition Labels**:

   - Accurately describe data collection
   - Specify if data is linked to user identity
   - Note data used for tracking (none in this app)

3. **Age Rating**:

   - Consider 4+ rating (no objectionable content)
   - May need to note "Unrestricted Web Access" if any web features added later

4. **Family Sharing Considerations**:

   - CloudKit sharing respects iCloud Family Sharing
   - Ensure supervised accounts work within family structure

### Data Security

- **Encryption**: CloudKit encrypts data in transit and at rest
- **Authentication**: Uses Apple's iCloud authentication (no custom auth needed)
- **Access Control**: CloudKit sharing provides granular permissions
- **No Data Export**: Data stays within user's iCloud account ecosystem

### Security Best Practices

**Do (Required)**:

- ✅ **Use CloudKit private database only**: All data stored in private database, never public
- ✅ **Use CKShare permissions**: Leverage CloudKit's built-in permission system for access control
- ✅ **Validate share access on every read/write**: Check permissions before allowing operations
  - Verify user has access to record before reading
  - Verify user has write permission before modifying
  - Handle permission errors gracefully
- ✅ **Assume shares can disappear at any time**:
  - Handle share revocation gracefully
  - Check share status before operations
  - Provide clear UI feedback when access is revoked
  - Clean up local data when share is removed

**Don't (Security Risks)**:

- ❌ **Cache sensitive data unencrypted**:
  - If caching is needed, use iOS Keychain for sensitive data
  - Core Data local storage is acceptable (iOS encrypts at rest)
  - Never store sensitive data in UserDefaults or plain files
- ❌ **Mirror CloudKit data to your own server**:
  - All data must stay in CloudKit only
  - No backend servers or external databases
  - No data synchronization to third-party services
- ❌ **Log chore content**:
  - Do not log chore names, descriptions, or user data
  - Only log technical errors and system events
  - Use structured logging that excludes user data
  - Ensure production builds have no debug logging of user content

### Privacy Policy Requirements

Must include:

- What data is collected (chore data, completion times, user names)
- How data is used (chore tracking, statistics, household sharing)
- Who data is shared with (only within household via CloudKit sharing)
- Data retention (as long as user maintains account)
- User rights (access, deletion, export)
- COPPA-specific disclosures for supervised accounts
- Contact information for privacy inquiries

### Supervised Account Considerations

1. **Terminology**: Use "supervised account" instead of "child account" to:

   - Support adults who may need supervision (elderly, special needs)
   - Avoid age-specific language
   - Comply with inclusive design principles

2. **Device Management**:

   - Supervised users may or may not have their own device
   - If no device: parent manages entirely
   - If device: supervised user can interact, but completions require review

3. **Edge Case: When Supervised Users Get Their Own Device**:

CloudKit sharing handles device transitions elegantly without migration code:

- **Same Apple ID** (supervised user uses parent's Apple ID):

  - Seamless transition - data already synced via CloudKit
  - No migration needed
  - Supervised user can immediately access their chores on new device

- **New Apple ID** (supervised user gets their own child Apple ID):

  - Parent simply re-shares the chore list with the new Apple ID
  - CloudKit share invitation sent to new account
  - Supervised user accepts share on new device
  - All existing data becomes available via CloudKit sync
  - No migration code needed - CloudKit handles everything

- **Architectural Benefit**:
  - This is a huge architectural win - no complex migration logic required
  - CloudKit's sharing model naturally handles account transitions
  - Parent maintains ownership, supervised user gets access via share
  - Works whether supervised user starts with device or gets one later

4. **Review Requirements**:

   - All supervised account completions require parent/guardian review
   - Prevents false completions
   - Provides accountability and teaching moments

5. **Data Visibility**:

   - Parents/guardians see all supervised account activity
   - Supervised users see their own data plus shared household data
   - Clear indication when account is supervised

6. **Consent & Onboarding**:

   - Clear explanation of what data is collected
   - Parent/guardian must explicitly create supervised account
   - Consent acknowledgment stored in User record

7. **Parent Setup Screen (Optional but Recommended)**:

   - **Purpose**: Extra safety measure for family apps
   - **Content**:
     - Welcome message explaining app purpose
     - Privacy overview (what data is collected, how it's stored)
     - Parent control explanation (what parents can do)
     - Supervised account creation guidance
     - Link to full privacy policy
   - **Benefits**:
     - Ensures parents understand app before use
     - Sets expectations about data and controls
     - Provides clear starting point for family setup
     - Can be shown on first launch or accessible from settings
   - **Implementation**:
     - Show on first app launch for parent accounts
     - Make accessible from settings for review
     - Simple, clear UI with bullet points
     - Optional skip (but encourage review)

### Additional Considerations for Supervised Users with Devices

1. **Screen Time & Usage**:

   - App should be designed to minimize screen time
   - Focus on quick task completion, not extended engagement
   - No gamification that encourages excessive use

2. **Notification Management**:

   - Parents control notification settings for supervised accounts
   - Notifications should be helpful reminders, not intrusive
   - Option to disable notifications entirely for supervised accounts

3. **Data Access Transparency**:

   - Supervised users should understand their activity is visible to parents
   - Clear UI indicators when account is supervised
   - No hidden data collection or tracking

4. **Age-Appropriate Design**:

   - Simple, clear interface for younger users
   - Large touch targets
   - Clear visual feedback
   - Minimal text, icon-based where possible

5. **Parental Oversight**:

   - Parents can view all supervised account activity
   - Parents receive notifications when chores are marked complete (pending review)
   - Parents can modify or delete supervised account data at any time

6. **Educational Value**:

   - Use completion as teaching opportunity
   - Review process allows parents to provide feedback
   - Statistics can help supervised users see progress and build habits

7. **Safety & Security**:

   - No external communication features
   - No social sharing or public profiles
   - All data stays within household via CloudKit sharing
   - No location tracking beyond timezone needs

## Core Data Models

### ChoreTemplate (CKRecord)

- `id`: UUID
- `name`: String
- `description`: String (optional)
- `category`: String (indoor, outdoor, weekly, monthly, etc.)
- `estimatedDuration`: TimeInterval (optional)
- `recurrenceRule`: JSON string (complex recurrence pattern)
- `assignedTo`: CKRecord.Reference (optional, to User)
- `createdBy`: CKRecord.Reference (to User)
- `createdAt`: Date
- `isActive`: Bool

### ChoreInstance (CKRecord)

- `id`: UUID
- `templateId`: CKRecord.Reference (to ChoreTemplate)
- `dueDate`: Date
- `completedAt`: Date? (optional)
- `completedBy`: CKRecord.Reference? (optional, to User)
- `notes`: String? (optional, **restricted** - avoid free-form notes per Kids Category rules, use structured inputs if needed)
- `status`: String (pending, completed, skipped, pending_review)
- `requiresReview`: Bool (true if assigned to supervised account)
- `reviewedAt`: Date? (optional)
- `reviewedBy`: CKRecord.Reference? (optional, to User - parent/guardian who approved)
- `reviewStatus`: String? (approved, rejected, null)
- `rejectionReason`: String? (optional)
- `actualDuration`: TimeInterval? (optional, time taken to complete)
- `createdAt`: Date

### User (CKRecord)

- `id`: UUID (maps to iCloud user ID)
- `name`: String
- `email`: String? (optional)
- `avatar`: CKAsset? (optional)
- `userType`: String (parent, supervised, guardian)
- `parentId`: CKRecord.Reference? (optional, to User - for supervised accounts)
- `guardianIds`: [CKRecord.Reference]? (optional, array of User references - parents/guardians who can review)
- `hasDevice`: Bool (whether supervised user has their own device)
- `isMinor`: Bool (true if user is under 13/18, for COPPA compliance)
- `parentalConsentDate`: Date? (when parental consent was obtained, if applicable)
- `currentGoalStreak`: Int (current consecutive days of goal completion)
- `longestGoalStreak`: Int (all-time longest streak)
- `lastGoalCompletionDate`: Date? (last date goals were completed)

### DailyGoalCompletion (CKRecord)

- `id`: UUID
- `userId`: CKRecord.Reference (to User)
- `date`: Date (day for which goal was completed)
- `allChoresCompleted`: Bool (true if all assigned chores for the day were completed)
- `totalChoresCount`: Int (total chores assigned for the day)
- `completedChoresCount`: Int (number completed)
- `totalTimeSpent`: TimeInterval (sum of actualDuration for completed chores)
- `createdAt`: Date

### RecurrenceRule Structure (JSON)

```json
{
  "frequency": "weekly|monthly|yearly|custom",
  "interval": 1,
  "daysOfWeek": [1, 3, 5],
  "dayOfMonth": null,
  "dayOfMonthWithFallback": { "day": 30, "fallbackToLastDay": true },
  "nthWeekdayOfMonth": { "weekday": 1, "nth": 3 },
  "lastWeekdayOfMonth": { "weekday": 5 },
  "lastDayOfMonth": false,
  "endDate": null,
  "occurrenceCount": null,
  "skipPattern": null
}
```

**Pattern Examples**:

- `dayOfMonth: 15` - 15th of every month
- `dayOfMonthWithFallback: { "day": 30, "fallbackToLastDay": true }` - 30th of month, or last day if month has fewer days
- `lastDayOfMonth: true` - Always the last day of the month

## Key Features Implementation

### 1. Advanced Recurrence Engine

- **RecurrenceRule Parser**: Parse JSON recurrence rules into date calculations
- **Date Generator**: Generate next occurrence dates based on rules
- **Pattern Builder UI**: SwiftUI form for creating complex patterns:
  - Every X days/weeks/months
  - Specific days of week
  - Specific day of month (e.g., 15th of every month)
  - Day of month with fallback (e.g., 30th of month, or last day if month is shorter)
  - Last day of month
  - Nth weekday of month (e.g., 3rd Monday)
  - Last weekday of month (e.g., last Friday)
  - Custom skip patterns

### 2. CloudKit Integration

- **CKContainer Setup**: Configure private database and sharing
- **Record Sync**: Automatic sync between local Core Data and CloudKit
- **Conflict Resolution**: Handle merge conflicts for shared records
- **Share Management**: Create/accept/manage CloudKit shares for household lists

### 3. Task Management

- **Template Management**: Create/edit/delete chore templates
- **Instance Generation**: Auto-generate ChoreInstance records based on recurrence
- **Completion Tracking**: Mark instances complete with timestamp and user
- **Assignment System**: Assign chores to household members (including supervised accounts)
- **Status Management**: Pending, completed, skipped, pending_review states
- **Supervised Account Support**: Create and manage supervised accounts under parent account
- **Parent Review System**: Parents/guardians review and approve supervised account chore completions

### 4. Notifications & Reminders

- **Local Notifications**: Schedule reminders based on due dates
- **Notification Center**: Display upcoming and overdue chores
- **Customizable Reminders**: Set reminder time before due date

### 5. Statistics & Analytics (Personal, iCloud-Scoped)

**Important**: These statistics are **allowed and compliant** because they are:

- Personal to the family (only visible within their iCloud account)
- Stored in CloudKit private database (never leaves family's iCloud)
- Not visible to the developer
- Not sent to external analytics services
- This is app functionality, not "analytics" in Apple's/COPPA's sense

- **Big Number Metrics** (prominently displayed):

  - **Total Chores Completed**: Count of all completed ChoreInstance records
  - **Total Time Spent**: Sum of all `actualDuration` values from completed chores
  - **Current Goal Streak**: Consecutive days where all assigned chores were completed
  - **Longest Goal Streak**: All-time record for consecutive goal completion days

- **Goal Completion Tracking**:

  - Daily goal = all assigned chores for a day are completed
  - Track goal completion per day in `DailyGoalCompletion` records
  - Streak calculation: consecutive days with `allChoresCompleted = true`
  - Streak resets to 0 when a day is missed (not all chores completed)
  - Update streak on User record when daily goal is achieved or missed

- **Completion Rates**: Track completion percentage per user/category (personal to family)
- **Time Analysis**: Average time to complete, most common categories (personal to family)
- **Charts**: Swift Charts integration for visualizations (streak history, completion trends)
  - All data for charts comes from family's CloudKit private database
  - No external data transmission
  - Only visible to family members with access

### 6. Supervised Accounts & Parent Review System

- **Supervised Account Creation**: Parents can create supervised accounts linked to their account

  - Supervised accounts can have their own iCloud identity (if they have a device)
  - Or be managed entirely by parent (if supervised user has no device)
  - Each supervised account has a `parentId` reference and optional `guardianIds` array
  - Parental consent required and recorded for accounts marked as minor (`isMinor: true`)

- **Guardian Sharing**: Supervised accounts can be shared with multiple guardians

  - Another parent/guardian can be added as a reviewer
  - All guardians can review and approve supervised account completions
  - CloudKit sharing enables cross-account access

- **Completion Workflow for Supervised Accounts**:

  1. Supervised user (or parent on their behalf) marks chore as complete
  2. Status changes to `pending_review`
  3. `requiresReview` flag set to `true`
  4. Notification sent to all parents/guardians
  5. Parent/guardian reviews in Review Queue
  6. Parent approves or rejects with optional structured feedback (avoid free-form notes per Kids Category rules)
  7. If approved: status → `completed`, `reviewedAt` and `reviewedBy` set
  8. If rejected: status → `pending`, `rejectionReason` stored, supervised user notified

- **Review Queue Interface**:

  - Dedicated view showing all chores pending review
  - Filter by supervised user, date range, chore category
  - Quick approve/reject actions
  - Detail view with completion details (**avoid photos per Kids Category rules**, use structured completion status instead)
  - Review history tracking

- **Device Management**:
  - Parent can indicate if supervised user has their own device
  - If no device: parent manages all supervised user interactions
  - If device: supervised user can use app independently, but completions still require review

## Technical Implementation

### Project Structure

```
ChoreTracker/
├── Models/
│   ├── ChoreTemplate.swift
│   ├── ChoreInstance.swift
│   ├── User.swift
│   └── RecurrenceRule.swift
├── Services/
│   ├── CloudKitService.swift
│   ├── RecurrenceEngine.swift
│   ├── NotificationService.swift
│   ├── StatisticsService.swift
│   ├── PrivacyService.swift
│   └── DeletionService.swift
├── ViewModels/
│   ├── ChoreListViewModel.swift
│   ├── ChoreDetailViewModel.swift
│   ├── RecurrenceBuilderViewModel.swift
│   ├── StatisticsViewModel.swift
│   ├── SupervisedAccountViewModel.swift
│   └── ReviewQueueViewModel.swift
├── Views/
│   ├── ChoreListView.swift
│   ├── ChoreDetailView.swift
│   ├── ChoreCompletionView.swift
│   ├── RecurrenceBuilderView.swift
│   ├── StatisticsView.swift
│   ├── SettingsView.swift
│   ├── SupervisedAccountManagementView.swift
│   ├── ReviewQueueView.swift
│   ├── ReviewDetailView.swift
│   └── ParentSetupView.swift
└── Utilities/
    ├── CloudKitExtensions.swift
    └── DateExtensions.swift
```

### Core Services

**CloudKitService.swift**

- Initialize CloudKit container
- CRUD operations for ChoreTemplate and ChoreInstance
- **Validate share access on every read/write** (security requirement)
- Handle CloudKit sharing (create shares, accept invitations)
- **Handle share revocation gracefully** (assume shares can disappear)
- Sync local Core Data with CloudKit
- Error handling and retry logic
- **Never log chore content or user data** (security requirement)

**RecurrenceEngine.swift**

- Parse RecurrenceRule JSON
- Calculate next occurrence dates
- Handle day-of-month patterns with fallback logic:
  - For `dayOfMonthWithFallback`: Check if target day exists in month, use last day if not
  - Example: 30th of month → Jan 30, Feb 28/29, Mar 30, Apr 30, etc.
- Generate date ranges for instances
- Validate recurrence patterns
- Handle edge cases (leap years, varying month lengths)

**NotificationService.swift**

- Schedule local notifications for due chores
- Cancel notifications for completed/skipped chores
- Handle notification permissions
- Update notifications when due dates change
- Notify parents/guardians when supervised user marks chore complete (pending review)
- Notify supervised users when parent approves/rejects completion

**ReviewService.swift**

- Manage parent review queue (chores pending approval)
- Handle approval/rejection workflow
- Track review history
- Filter reviews by supervised user, date, status

**DeletionService.swift**

- Delete all data for a supervised user:
  - Delete all ChoreInstance records assigned to user
  - Delete ChoreTemplate records created by user
  - Delete DailyGoalCompletion records for user
  - Delete User record
  - Revoke CloudKit share
- Delete all family data:
  - Delete all records for all users in household
  - Revoke all CloudKit shares
- Automatic orphan cleanup:
  - Clean up ChoreInstance records when assigned user is deleted
  - Handle ChoreTemplate records when creator is deleted
  - Ensure no dangling references
- Unshare/Revoke Access:
  - Remove CloudKit share for supervised account
  - Trigger local data cleanup on supervised user's device
  - Handle edge cases (device offline, sync conflicts)

**StatisticsService.swift**

- Calculate total chores completed (count of completed ChoreInstance records)
- Calculate total time spent (sum of actualDuration from completed chores)
- Track daily goal completion:
  - Check if all assigned chores for a day are completed
  - Create/update DailyGoalCompletion record
  - Update User streak fields (currentGoalStreak, longestGoalStreak, lastGoalCompletionDate)
- Streak calculation logic:
  - When goal achieved: increment currentGoalStreak, update longestGoalStreak if new record
  - When goal missed: reset currentGoalStreak to 0
  - Handle edge cases (multiple completions in one day, timezone issues)
- Generate statistics for charts (all data from CloudKit private database)
- Filter statistics by user, date range, category
- **Important**: All statistics are personal to the family, stored in their iCloud account, never sent externally

## Data Flow

1. **Creating Chore Template**: User creates template → Save to Core Data → Sync to CloudKit
2. **Generating Instances**: Background job checks templates → Generates instances for upcoming period → Saves to Core Data → Syncs to CloudKit
3. **Completing Chore**: User marks complete → Update instance → Sync to CloudKit → Update statistics
4. **Sharing**: User creates share → CloudKit sends invitation → Recipient accepts → Records sync to their device

## CloudKit Sharing Implementation

- Use `CKShare` to share chore lists (templates and instances)
- **Sharing Scenarios**:

  1. **Parent-Supervised Sharing**: Parent shares their chore list with supervised user's iCloud account (if supervised user has device) OR manages on behalf of supervised user (if no device)
  2. **Parent-Guardian Sharing**: Parent shares with another parent/guardian so both can review supervised account completions
  3. **Household Sharing**: All adult members share the same chore list

- Each user (parent, supervised, guardian) gets their own iCloud account
- CloudKit handles authentication automatically
- Share permissions (maps to Parent Control Model):
  - **Parents/Guardians (Owners)**:
    - Full read/write access
    - Review permissions
    - Can delete and modify all records
    - Can revoke access instantly
  - **Supervised Users (Participants)**:
    - Read access to assigned chores
    - Can mark chores complete (requires review)
    - Can add personal chores (if enabled by parent)
    - Cannot delete or modify templates
    - Cannot share with others
    - Access can be revoked by parent at any time
- **Supervised Account Management**: Supervised accounts are created under parent's account but can have their own iCloud identity (if they have a device) or be managed by parent
- **Device Transition Support**: When supervised user gets their own device (same or new Apple ID), CloudKit sharing handles transition seamlessly - no migration code needed

## Local Storage Strategy

- **Core Data Stack**: Local SQLite database
- **CloudKit Integration**: Core Data + CloudKit automatic sync
- **Offline Support**: Full CRUD operations work offline, sync when online
- **Conflict Resolution**: Last-write-wins with timestamp comparison

## UI/UX Considerations

- **SwiftUI Lists**: Display chores with filtering (upcoming, overdue, completed, pending review)
- **Recurrence Builder**: Step-by-step form for complex patterns
- **Statistics Dashboard**:
  - Big number cards: Total chores completed, Total time spent, Current streak, Longest streak
  - Charts showing completion trends (separate views for supervised accounts)
  - Streak visualization (calendar view showing goal completion days)
  - Time breakdown by category/user
- **Assignment UI**: Easy assignment to household members (including supervised accounts)
- **Supervised Account Management**:
  - Create/edit supervised accounts
  - Manage device status
  - Handle parental consent
  - **Revoke access instantly** (unshare functionality)
  - **Delete supervised account and all data** (with confirmation)
- **Review Queue**: Dedicated view for parents to review pending supervised account completions
- **Data Deletion UI**:
  - Delete all data per supervised user
  - Delete all family data
  - Clear warnings and confirmations
  - Progress indicators
- **Review Detail View**: Show completion details, approve/reject with optional structured feedback (**avoid photos and free-form notes per Kids Category rules**)
- **Role-Based UI**: Different interfaces for parents vs supervised users
- **Parent Setup Screen**: Optional welcome/setup screen for parents (extra safety measure)
- **Family-Friendly Language**: Use "progress" instead of "tracking" throughout UI
- **Dark Mode**: Full support for light/dark appearance

## Development Phases

### Phase 1: Core Foundation

- Set up Xcode project with CloudKit + Core Data
- Implement basic data models
- Create CloudKitService with basic CRUD
- Simple UI for viewing/creating chores

### Phase 2: Recurrence Engine

- Build RecurrenceRule parser
- Implement date generation logic
- Create RecurrenceBuilderView UI
- Test complex recurrence patterns

### Phase 3: Multi-User & Sharing

- Implement CloudKit sharing
- User management (household members)
- Assignment system
- Share invitation flow

### Phase 3.5: Supervised Accounts & Parent Review

- Supervised account creation and management
- Parent-supervised relationship modeling
- Parental consent collection and storage (COPPA compliance)
- Guardian sharing (multiple parents can review)
- Supervised account completion workflow (mark complete → pending review)
- Parent review UI and approval/rejection system
- Support for supervised users without devices (parent manages on their behalf)
- Device transition support (when supervised user gets their own device - same or new Apple ID)
- Review queue and notifications
- Privacy policy implementation:
  - Create privacy policy document with plain-English bullets
  - Include all required statements (no data collection, iCloud storage, deletion rights)
  - Display in app settings
  - Link from App Store listing
- Data deletion functionality for supervised accounts:
  - Delete all data per supervised user
  - Delete all family data
  - Unshare/revoke access functionality
  - Automatic orphan cleanup
- Privacy manifest and App Store privacy labels
- Kids Category compliance:
  - Remove any third-party analytics SDKs (Firebase, Mixpanel, Amplitude)
  - Ensure no developer-visible analytics (no cross-user metrics, no external data transmission)
  - Verify all statistics are personal, iCloud-scoped only
  - Ensure no ads
  - Restrict free-form notes and photos
  - Verify Apple Analytics only (if used, and only basic aggregated data)

### Phase 4: Advanced Features

- Notification system
- Statistics and analytics:
  - DailyGoalCompletion tracking
  - Goal streak calculation and updates
  - Big number metrics (total completed, total time, streaks)
  - Statistics dashboard UI with charts
- Categories and filtering
- Structured completion details (avoid free-form notes and photos per Kids Category rules)
- Time tracking (actualDuration recording)

### Phase 5: Polish

- UI refinements
- Error handling improvements
- Performance optimization
- Testing and bug fixes
- Family-friendly enhancements:
  - Parent Setup screen implementation
  - Terminology review (replace "tracking" with "progress")
  - App Store metadata ("Designed for Families" designation)

## Key Files to Create

1. `ChoreTracker.xcodeproj` - Xcode project with CloudKit capability
2. `Models/ChoreTemplate.swift` - Core data model
3. `Models/ChoreInstance.swift` - Instance model
4. `Models/RecurrenceRule.swift` - Recurrence pattern model
5. `Services/CloudKitService.swift` - CloudKit operations
6. `Services/RecurrenceEngine.swift` - Date calculation engine
7. `Services/NotificationService.swift` - Local notifications
8. `ViewModels/ChoreListViewModel.swift` - Main list logic
9. `ViewModels/SupervisedAccountViewModel.swift` - Supervised account management
10. `ViewModels/ReviewQueueViewModel.swift` - Parent review queue logic
11. `Views/ChoreListView.swift` - Primary UI
12. `Views/ChoreCompletionView.swift` - Completion interface (different for children vs adults)
13. `Views/RecurrenceBuilderView.swift` - Pattern builder UI
14. `Views/SupervisedAccountManagementView.swift` - Create/manage supervised accounts
15. `Views/ReviewQueueView.swift` - Parent review queue
16. `Views/ReviewDetailView.swift` - Individual review approval/rejection
17. `Services/ReviewService.swift` - Review workflow management
18. `Models/DailyGoalCompletion.swift` - Daily goal tracking model
19. `Services/StatisticsService.swift` - Statistics calculation and streak management
20. `ViewModels/StatisticsViewModel.swift` - Statistics view logic
21. `PrivacyInfo.xcprivacy` - Privacy manifest file (App Store requirement)
22. `Services/PrivacyService.swift` - Privacy policy display, consent management
23. `Services/DeletionService.swift` - Data deletion, unshare/revoke access, orphan cleanup
24. `Views/DataDeletionView.swift` - UI for deleting supervised account or family data
25. `Views/AccountManagementView.swift` - Parent controls for revoking access, managing permissions
26. `Views/ParentSetupView.swift` - Optional parent setup/welcome screen

## Testing Considerations

- Unit tests for RecurrenceEngine
- CloudKit testing with development environment
- Multi-device sync testing
- Offline mode testing
- Share acceptance flow testing
- Supervised account creation and management
- Parental consent flow (COPPA compliance)
- Parent review workflow (approve/reject)
- Guardian sharing scenarios
- Supervised account completion without device (parent manages)
- Device transition scenarios (same Apple ID vs new Apple ID)
- Data deletion for supervised accounts (per user and family-wide)
- Unshare/revoke access functionality
- Automatic orphan cleanup when accounts deleted
- Privacy policy compliance:
  - Plain-English privacy policy with required statements
  - Display in app and link from App Store
- Security implementation:
  - Share access validation
  - Share revocation handling
  - Secure data storage practices
  - No sensitive data logging
- Privacy manifest file creation
- Age-appropriate UI considerations for supervised users
- Kids Category compliance verification:
  - No third-party analytics (Firebase, Mixpanel, Amplitude)
  - No developer-visible analytics (no cross-user metrics, no external data transmission)
  - Verify all statistics are personal, iCloud-scoped only (allowed)
  - No ads
  - Restricted free-form notes and photos
  - Parent control model implementation
- Security best practices implementation:
  - Share access validation on all read/write operations
  - Handle share revocation gracefully
  - No unencrypted sensitive data caching
  - No external server mirroring
  - No chore content logging
- Review queue filtering and notifications
- Goal completion tracking and streak calculation
- Statistics calculation accuracy (total time, completion counts)
- Streak reset logic when goals are missed
