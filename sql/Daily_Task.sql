-- Trend
EXEC [dbo].[csp_Calc_FiveNum_Trend_Monthly]

-- Weekly
declare @TickInvest varchar(10)
declare @TickBond varchar(10)

set @TickInvest = 'IJH'
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


-- Fans
declare @s_date datetime
declare @e_date datetime
declare @actual_date datetime
declare @slope_sdate datetime

-- to process for 6/26/2015 use these days
set @s_date = '6-25-2015'
set @e_date = '6-27-2015'
set @actual_date = '6-26-2015'
set @slope_sdate = '6-21-2015'

select convert(date,@s_date) sDate, 
convert(date, @slope_sdate) as slope_sdate,
convert(date,@actual_date) ActualDate, convert(date,@e_date) eDate

--if exists (select db_row_id from tbl_Prices where db_ticker_id = 1 and db_mult is null and db_dt = @e_date -1)
	EXECUTE [csp_Calc_Averages_2] 
	   @s_date=@s_date
	  ,@e_date=@e_date
	  ,@typ = 1
--if exists (select db_row_id from tbl_Prices where db_ticker_id = 827 and db_mult is null and db_dt = @e_date -1)
	EXECUTE [csp_Calc_Averages_2] 
	   @s_date=@s_date
	  ,@e_date=@e_date
	  ,@typ = 2

-- calc slope
EXECUTE [csp_Calc_Update_Slope_2]
@slope_sdate, @actual_date, @typ=2
EXECUTE [csp_Calc_Update_Slope_2]
@slope_sdate, @actual_date, @typ=1

EXECUTE [csp_CollectFans] 
   @sdt = @s_date
  ,@typ= 1
EXECUTE [csp_CollectFans] 
   @sdt = @s_date
  ,@typ= 2
