CREATE TABLE [dbo].[Customers]
(
    [CustomerId]   INT            IDENTITY (1, 1) NOT NULL,
    [FirstName]    NVARCHAR (100) NOT NULL,
    [LastName]     NVARCHAR (100) NOT NULL,
    [Email]        NVARCHAR (255) NOT NULL,
    [Phone] NVARCHAR (20) NULL,
    [CreatedDate]  DATETIME2      CONSTRAINT [DF_Customers_CreatedDate] DEFAULT (SYSUTCDATETIME()) NOT NULL,
    CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([CustomerId] ASC),
    CONSTRAINT [UQ_Customers_Email] UNIQUE ([Email])
);
