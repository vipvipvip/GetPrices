USE [IDToDSN_DKC]
GO
/****** Object:  Table [dbo].[tbl_Ticker]    Script Date: 02/05/2011 17:26:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Ticker](
	[db_ticker_id] [int] NOT NULL,
	[db_strTicker] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_tbl_Ticker] PRIMARY KEY CLUSTERED 
(
	[db_ticker_id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
USE [IDToDSN_DKC]
GO
/****** Object:  Table [dbo].[tbl_Prices]    Script Date: 02/05/2011 17:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Prices](
	[db_row_id] [int] IDENTITY(1,1) NOT NULL,
	[db_ticker_id] [int] NOT NULL,
	[db_volume] [int] NULL,
	[db_dt] [smalldatetime] NULL,
	[db_close] [real] NULL,
	[db_mult] [real] NULL,
	[db_avg] [real] NULL,
	[db_index] [real] NULL,
	[db_rank] [smallint] NULL,
	[db_mult_avg_ratio] [smallint] NULL,
 CONSTRAINT [PK_tbl_Prices] PRIMARY KEY CLUSTERED 
(
	[db_row_id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
