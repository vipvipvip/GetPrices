USE [StockDB]
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[XTBL](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Ticker] [varchar](50) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


-- gen dupes by inserting the same data three times
insert XTBL
select db_strTicker
from tbl_Ticker
insert XTBL
select db_strTicker
from tbl_Ticker
insert XTBL
select db_strTicker
from tbl_Ticker

select * from XTBL
where Ticker = 'A'


select M.id, M.Ticker, M.rk
from XTBL X, 
(
select A.id, A.Ticker,
RANK() over ( Partition by Ticker order by id) rk
from XTBL A
) as M
where X.Ticker = M.Ticker
and M.rk > 1

drop table XTBL
