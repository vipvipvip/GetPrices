--select * from tbl_Ticker where db_strTicker in ('SPY', 'TLT')

select * from tbl_Ticker
where db_ticker_id not in (select tid from tbl_return_rank where dt = '7-1-2015')
and db_type = 1
and db_ticker_id in ( select T.db_ticker_id
from tbl_Ticker T, tbl_Prices P
where T.db_ticker_id = P.db_ticker_id
and T.db_type = 1
and P. db_dt = '12-29-2005'
)

-- Step 3 - Calc Rankings
EXEC	[dbo].[csp_Calc_Ret_Monthly]
		@sdt = '7-1-2015' -- change date to first trading day of the month.
		,@tick='HT'
		,@srcFN=null

select strTicker, count(*)
from tbl_Return_Rank
where tid in ( select T.db_ticker_id
from tbl_Ticker T, tbl_Prices P
where T.db_ticker_id = P.db_ticker_id
and T.db_type = 1
and P. db_dt = '12-29-2005'
)
group by strTicker
order by count(*)

--select * from tbl_Prices where db_ticker_id in (select db_ticker_id from tbl_Ticker where db_strTicker = 'icpt') order by db_dt
--select * from tbl_Return_Rank where strticker='icpt' and dt > '12-1-2006' order by dt

select RR.tid, RR.price, RR.strTicker,RR.dt, RR.rRank, RR.r1, P.db_slope
		from tbl_Return_Rank RR , tbl_Prices P
		where RR.tid = P.db_ticker_id
		and RR.dt = P.db_dt 
		and P.db_slope is null
		and RR.dt > '12-31-2006'
		and RR.tid in (select db_ticker_id from tbl_Ticker where db_type = 1)
		order by RR.dt desc

		