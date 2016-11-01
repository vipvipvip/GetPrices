USE [IDToDSN_DKC]
GO

/****** Object:  Table [dbo].[tbl_FiveNum]    Script Date: 12/22/2012 18:13:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbl_FiveNum](
	[db_ticker_id] [int] NOT NULL,
	[db_dt] [smalldatetime] NOT NULL,
	[db_close] [real] NOT NULL,
	[db_min] [real] NULL,
	[db_HL] [real] NULL,
	[db_median] [real] NULL,
	[db_HU] [real] NULL,
	[db_max] [real] NULL,
	[db_rank] [tinyint] NULL,
 CONSTRAINT [PK_tbl_FiveNum] PRIMARY KEY CLUSTERED 
(
	[db_ticker_id] ASC,
	[db_dt] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


