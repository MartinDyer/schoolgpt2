-- ================================================================
-- School Safe AI App - Database Schema Initialization Script
-- ================================================================
-- 
-- This script creates the required tables for:
-- 1. Chat history storage and display
-- 2. Comprehensive audit logging 
-- 3. Content filter violation tracking
-- 4. User session management
-- 5. School-specific reporting
--
-- Run this script after deploying the Azure infrastructure
-- ================================================================

-- Enable necessary features
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================================
-- Table: Users - Track authenticated users (students/teachers)
-- ================================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
CREATE TABLE [dbo].[Users] (
    [UserId] UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    [EntraIdObjectId] NVARCHAR(50) NOT NULL UNIQUE,
    [UserPrincipalName] NVARCHAR(255) NOT NULL,
    [DisplayName] NVARCHAR(255) NOT NULL,
    [UserType] NVARCHAR(20) NOT NULL CHECK (UserType IN ('Student', 'Teacher', 'Admin')),
    [Grade] NVARCHAR(10) NULL, -- For students
    [Department] NVARCHAR(100) NULL, -- For teachers
    [IsActive] BIT DEFAULT 1,
    [FirstLogin] DATETIME2 DEFAULT GETUTCDATE(),
    [LastLogin] DATETIME2 DEFAULT GETUTCDATE(),
    [CreatedAt] DATETIME2 DEFAULT GETUTCDATE(),
    [UpdatedAt] DATETIME2 DEFAULT GETUTCDATE()
)
GO

-- ================================================================
-- Table: ChatSessions - Group related chat messages
-- ================================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ChatSessions' AND xtype='U')
CREATE TABLE [dbo].[ChatSessions] (
    [SessionId] UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    [UserId] UNIQUEIDENTIFIER NOT NULL,
    [SessionTitle] NVARCHAR(255) NULL,
    [Subject] NVARCHAR(100) NULL, -- e.g., Math, Science, History
    [StartTime] DATETIME2 DEFAULT GETUTCDATE(),
    [EndTime] DATETIME2 NULL,
    [MessageCount] INT DEFAULT 0,
    [IsActive] BIT DEFAULT 1,
    [CreatedAt] DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
)
GO

-- ================================================================
-- Table: ChatHistory - Store all chat interactions for display
-- ================================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ChatHistory' AND xtype='U')
CREATE TABLE [dbo].[ChatHistory] (
    [ChatId] UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    [SessionId] UNIQUEIDENTIFIER NOT NULL,
    [UserId] UNIQUEIDENTIFIER NOT NULL,
    [UserMessage] NVARCHAR(MAX) NOT NULL,
    [AIResponse] NVARCHAR(MAX) NOT NULL,
    [ResponseTime] DATETIME2 DEFAULT GETUTCDATE(),
    [TokensUsed] INT NULL,
    [Model] NVARCHAR(50) NOT NULL DEFAULT 'gpt-35-turbo',
    [Temperature] DECIMAL(3,2) DEFAULT 0.1,
    [IsEducational] BIT DEFAULT 1,
    [Subject] NVARCHAR(100) NULL,
    [Grade] NVARCHAR(10) NULL,
    [Sentiment] NVARCHAR(20) NULL, -- Positive, Neutral, Negative
    [CreatedAt] DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (SessionId) REFERENCES ChatSessions(SessionId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
)
GO

-- ================================================================
-- Table: AuditLog - Comprehensive audit trail of all activities
-- ================================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='AuditLog' AND xtype='U')
CREATE TABLE [dbo].[AuditLog] (
    [AuditId] UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    [UserId] UNIQUEIDENTIFIER NULL,
    [SessionId] UNIQUEIDENTIFIER NULL,
    [ChatId] UNIQUEIDENTIFIER NULL,
    [EventType] NVARCHAR(50) NOT NULL, -- Login, Logout, ChatMessage, ContentFilter, SystemAccess
    [EventDescription] NVARCHAR(MAX) NOT NULL,
    [UserAgent] NVARCHAR(500) NULL,
    [IPAddress] NVARCHAR(45) NULL,
    [UserMessage] NVARCHAR(MAX) NULL,
    [AIResponse] NVARCHAR(MAX) NULL,
    [TokensUsed] INT NULL,
    [Model] NVARCHAR(50) NULL,
    [Timestamp] DATETIME2 DEFAULT GETUTCDATE(),
    [Severity] NVARCHAR(20) DEFAULT 'Info', -- Info, Warning, Error, Critical
    [Source] NVARCHAR(100) DEFAULT 'SchoolGPT',
    [AdditionalData] NVARCHAR(MAX) NULL, -- JSON for extra context
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (SessionId) REFERENCES ChatSessions(SessionId),
    FOREIGN KEY (ChatId) REFERENCES ChatHistory(ChatId)
)
GO

-- ================================================================
-- Table: ContentFilterViolations - Track content filter triggers
-- ================================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ContentFilterViolations' AND xtype='U')
CREATE TABLE [dbo].[ContentFilterViolations] (
    [ViolationId] UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    [UserId] UNIQUEIDENTIFIER NULL,
    [SessionId] UNIQUEIDENTIFIER NULL,
    [UserMessage] NVARCHAR(MAX) NOT NULL,
    [FilterType] NVARCHAR(50) NOT NULL, -- Hate, Sexual, Violence, SelfHarm, Custom
    [Severity] NVARCHAR(20) NOT NULL, -- Low, Medium, High, Critical
    [FilterResponse] NVARCHAR(MAX) NULL,
    [ActionTaken] NVARCHAR(100) NOT NULL, -- Blocked, Warning, Logged
    [RequiresReview] BIT DEFAULT 1,
    [ReviewedBy] UNIQUEIDENTIFIER NULL,
    [ReviewedAt] DATETIME2 NULL,
    [ReviewNotes] NVARCHAR(MAX) NULL,
    [UserAgent] NVARCHAR(500) NULL,
    [IPAddress] NVARCHAR(45) NULL,
    [Timestamp] DATETIME2 DEFAULT GETUTCDATE(),
    [NotificationSent] BIT DEFAULT 0,
    [ParentNotified] BIT DEFAULT 0, -- For serious violations
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (SessionId) REFERENCES ChatSessions(SessionId),
    FOREIGN KEY (ReviewedBy) REFERENCES Users(UserId)
)
GO

-- ================================================================
-- Table: SystemMetrics - Track system usage and performance
-- ================================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SystemMetrics' AND xtype='U')
CREATE TABLE [dbo].[SystemMetrics] (
    [MetricId] UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    [MetricDate] DATE DEFAULT CAST(GETUTCDATE() AS DATE),
    [TotalUsers] INT DEFAULT 0,
    [ActiveUsers] INT DEFAULT 0,
    [TotalSessions] INT DEFAULT 0,
    [TotalMessages] INT DEFAULT 0,
    [ContentFilterTriggers] INT DEFAULT 0,
    [AverageResponseTime] DECIMAL(10,2) DEFAULT 0,
    [TotalTokensUsed] BIGINT DEFAULT 0,
    [SystemErrors] INT DEFAULT 0,
    [CreatedAt] DATETIME2 DEFAULT GETUTCDATE()
)
GO

-- ================================================================
-- Create Indexes for Performance
-- ================================================================

-- Indexes for ChatHistory (most frequently queried table)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ChatHistory_UserId_CreatedAt')
CREATE NONCLUSTERED INDEX IX_ChatHistory_UserId_CreatedAt 
ON [dbo].[ChatHistory] ([UserId], [CreatedAt] DESC)
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ChatHistory_SessionId')
CREATE NONCLUSTERED INDEX IX_ChatHistory_SessionId 
ON [dbo].[ChatHistory] ([SessionId])
GO

-- Indexes for AuditLog
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLog_UserId_Timestamp')
CREATE NONCLUSTERED INDEX IX_AuditLog_UserId_Timestamp 
ON [dbo].[AuditLog] ([UserId], [Timestamp] DESC)
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLog_EventType_Timestamp')
CREATE NONCLUSTERED INDEX IX_AuditLog_EventType_Timestamp 
ON [dbo].[AuditLog] ([EventType], [Timestamp] DESC)
GO

-- Indexes for ContentFilterViolations
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ContentFilter_RequiresReview')
CREATE NONCLUSTERED INDEX IX_ContentFilter_RequiresReview 
ON [dbo].[ContentFilterViolations] ([RequiresReview], [Timestamp] DESC)
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ContentFilter_UserId_Timestamp')
CREATE NONCLUSTERED INDEX IX_ContentFilter_UserId_Timestamp 
ON [dbo].[ContentFilterViolations] ([UserId], [Timestamp] DESC)
GO

-- Indexes for Users
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_EntraIdObjectId')
CREATE UNIQUE NONCLUSTERED INDEX IX_Users_EntraIdObjectId 
ON [dbo].[Users] ([EntraIdObjectId])
GO

-- ================================================================
-- Create Views for Common Queries
-- ================================================================

-- View: Active chat sessions with user details
IF OBJECT_ID('vw_ActiveChatSessions', 'V') IS NULL
EXEC('CREATE VIEW vw_ActiveChatSessions AS
SELECT 
    cs.SessionId,
    cs.SessionTitle,
    cs.Subject,
    cs.StartTime,
    cs.MessageCount,
    u.DisplayName,
    u.UserType,
    u.Grade,
    u.Department
FROM ChatSessions cs
INNER JOIN Users u ON cs.UserId = u.UserId
WHERE cs.IsActive = 1')
GO

-- View: Recent content filter violations requiring review
IF OBJECT_ID('vw_ContentFilterReview', 'V') IS NULL
EXEC('CREATE VIEW vw_ContentFilterReview AS
SELECT 
    cfv.ViolationId,
    cfv.UserMessage,
    cfv.FilterType,
    cfv.Severity,
    cfv.Timestamp,
    u.DisplayName,
    u.UserType,
    u.Grade
FROM ContentFilterViolations cfv
LEFT JOIN Users u ON cfv.UserId = u.UserId
WHERE cfv.RequiresReview = 1
  AND cfv.Timestamp >= DATEADD(day, -30, GETUTCDATE())')
GO

-- View: Daily usage statistics
IF OBJECT_ID('vw_DailyUsageStats', 'V') IS NULL
EXEC('CREATE VIEW vw_DailyUsageStats AS
SELECT 
    CAST(ch.CreatedAt AS DATE) as UsageDate,
    COUNT(DISTINCT ch.UserId) as UniqueUsers,
    COUNT(DISTINCT ch.SessionId) as UniqueSessions,
    COUNT(*) as TotalMessages,
    AVG(CAST(ch.TokensUsed AS FLOAT)) as AvgTokensPerMessage,
    SUM(ch.TokensUsed) as TotalTokens
FROM ChatHistory ch
WHERE ch.CreatedAt >= DATEADD(day, -90, GETUTCDATE())
GROUP BY CAST(ch.CreatedAt AS DATE)')
GO

-- ================================================================
-- Create Stored Procedures for Common Operations
-- ================================================================

-- Procedure: Insert or update user from Entra ID
IF OBJECT_ID('sp_UpsertUser', 'P') IS NULL
EXEC('CREATE PROCEDURE sp_UpsertUser
    @EntraIdObjectId NVARCHAR(50),
    @UserPrincipalName NVARCHAR(255),
    @DisplayName NVARCHAR(255),
    @UserType NVARCHAR(20),
    @Grade NVARCHAR(10) = NULL,
    @Department NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE Users AS target
    USING (SELECT @EntraIdObjectId as EntraIdObjectId) AS source
    ON target.EntraIdObjectId = source.EntraIdObjectId
    WHEN MATCHED THEN
        UPDATE SET 
            UserPrincipalName = @UserPrincipalName,
            DisplayName = @DisplayName,
            UserType = @UserType,
            Grade = @Grade,
            Department = @Department,
            LastLogin = GETUTCDATE(),
            UpdatedAt = GETUTCDATE(),
            IsActive = 1
    WHEN NOT MATCHED THEN
        INSERT (EntraIdObjectId, UserPrincipalName, DisplayName, UserType, Grade, Department)
        VALUES (@EntraIdObjectId, @UserPrincipalName, @DisplayName, @UserType, @Grade, @Department);
        
    SELECT UserId FROM Users WHERE EntraIdObjectId = @EntraIdObjectId;
END')
GO

-- Procedure: Log content filter violation
IF OBJECT_ID('sp_LogContentFilterViolation', 'P') IS NULL
EXEC('CREATE PROCEDURE sp_LogContentFilterViolation
    @UserId UNIQUEIDENTIFIER,
    @SessionId UNIQUEIDENTIFIER = NULL,
    @UserMessage NVARCHAR(MAX),
    @FilterType NVARCHAR(50),
    @Severity NVARCHAR(20),
    @FilterResponse NVARCHAR(MAX) = NULL,
    @ActionTaken NVARCHAR(100),
    @UserAgent NVARCHAR(500) = NULL,
    @IPAddress NVARCHAR(45) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ViolationId UNIQUEIDENTIFIER = NEWID();
    
    INSERT INTO ContentFilterViolations 
    (ViolationId, UserId, SessionId, UserMessage, FilterType, Severity, 
     FilterResponse, ActionTaken, UserAgent, IPAddress)
    VALUES 
    (@ViolationId, @UserId, @SessionId, @UserMessage, @FilterType, @Severity,
     @FilterResponse, @ActionTaken, @UserAgent, @IPAddress);
     
    -- Also log to audit trail
    INSERT INTO AuditLog 
    (UserId, SessionId, EventType, EventDescription, UserMessage, Severity, UserAgent, IPAddress)
    VALUES 
    (@UserId, @SessionId, ''ContentFilterViolation'', 
     CONCAT(''Content filter triggered: '', @FilterType, '' - '', @Severity),
     @UserMessage, @Severity, @UserAgent, @IPAddress);
     
    SELECT @ViolationId as ViolationId;
END')
GO

-- ================================================================
-- Insert Sample Data for Testing (Optional)
-- ================================================================

-- Insert a system admin user (comment out in production)
/*
IF NOT EXISTS (SELECT * FROM Users WHERE EntraIdObjectId = 'system-admin')
INSERT INTO Users (EntraIdObjectId, UserPrincipalName, DisplayName, UserType, Department)
VALUES ('system-admin', 'admin@schoolgpt.edu', 'System Administrator', 'Admin', 'IT Department');
*/

-- ================================================================
-- Create Triggers for Audit Logging
-- ================================================================

-- Trigger: Log all user updates
IF OBJECT_ID('tr_Users_Audit', 'TR') IS NULL
EXEC('CREATE TRIGGER tr_Users_Audit ON Users
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AuditLog (UserId, EventType, EventDescription, Severity)
    SELECT 
        i.UserId,
        CASE WHEN EXISTS(SELECT * FROM deleted d WHERE d.UserId = i.UserId) 
             THEN ''UserUpdate'' 
             ELSE ''UserCreate'' 
        END,
        CONCAT(''User account modified: '', i.DisplayName, '' ('', i.UserPrincipalName, '')''),
        ''Info''
    FROM inserted i;
END')
GO

-- ================================================================
-- Database Setup Complete
-- ================================================================

PRINT 'School Safe AI Database Schema - Setup Complete!'
PRINT '================================================='
PRINT 'Tables Created:'
PRINT '- Users: Authentication and user management'
PRINT '- ChatSessions: Session grouping and tracking'
PRINT '- ChatHistory: Complete chat history for display'
PRINT '- AuditLog: Comprehensive audit trail'
PRINT '- ContentFilterViolations: Safety monitoring'
PRINT '- SystemMetrics: Usage analytics'
PRINT ''
PRINT 'Views Created:'
PRINT '- vw_ActiveChatSessions: Current active sessions'
PRINT '- vw_ContentFilterReview: Violations needing review'
PRINT '- vw_DailyUsageStats: Usage analytics'
PRINT ''
PRINT 'Stored Procedures Created:'
PRINT '- sp_UpsertUser: User management from Entra ID'
PRINT '- sp_LogContentFilterViolation: Safety incident logging'
PRINT ''
PRINT 'Next Steps:'
PRINT '1. Configure the application to use these tables'
PRINT '2. Set up regular monitoring of ContentFilterViolations'
PRINT '3. Create dashboard views for school administrators'
PRINT '4. Configure automated alerts for safety violations'
PRINT '================================================='
GO 