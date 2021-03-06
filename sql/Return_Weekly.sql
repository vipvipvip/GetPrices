USE [IDToDSN_DKC]
GO
declare @TickInvest varchar(10)
declare @TickBond varchar(10)

set @TickInvest = 'MDY'
set @TickBond = 'TLT'


EXEC	[dbo].[csp_Calc_Ret_Weekly]
		@db_dt = '12-29-2006',
		@tick_id = 0,
		@str_ticker = @TickInvest 

EXEC	[dbo].[csp_Calc_Ret_Weekly]
		@db_dt = '12-29-2006',
		@tick_id = 0,
		@str_ticker = @TickBond 


select db_dt, db_close, 'Equity' as Equity
from tbl_Ticker T, tbl_Prices P
where T.db_ticker_id = P.db_ticker_id 
and T.db_strTicker = @TickInvest 
and db_dt > '1-1-2006'
order by db_dt

select db_dt, db_close, 'Bond' as Bond
from tbl_Ticker T, tbl_Prices P
where T.db_ticker_id = P.db_ticker_id 
and T.db_strTicker = @TickBond 
and db_dt > '1-1-2006'
order by db_dt
