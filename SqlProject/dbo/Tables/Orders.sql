CREATE TABLE [dbo].[Orders]
(
    [OrderId]      INT            IDENTITY (1, 1) NOT NULL,
    [CustomerId]   INT            NOT NULL,
    [OrderDate]    DATETIME2      CONSTRAINT [DF_Orders_OrderDate] DEFAULT (SYSUTCDATETIME()) NOT NULL,
    [TotalAmount]  DECIMAL (10,2) NOT NULL,
    [Status]       NVARCHAR (50)  CONSTRAINT [DF_Orders_Status] DEFAULT ('Pending') NOT NULL,
    CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED ([OrderId] ASC),
    CONSTRAINT [FK_Orders_Customers] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customers] ([CustomerId])
);
