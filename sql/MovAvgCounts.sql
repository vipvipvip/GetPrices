--declare @tbl table (s varchar(50))
--insert @tbl
--EXEC	[dbo].[csp_ReadCSV]
--		@filename = N'IVV.csv',
--		@dbDir = N'C:\temp',
--		@whereclause = N'1=1'

declare @tbl_Data table (idx int identity, dt datetime, cntA int, cntB int)

insert @tbl_Data
select dt,0,0 from tbl_Return_Rank where dt > '12-31-2006' and tid = 442
order by dt

update @tbl_Data
set cntA = A.cnt
from (
select P.db_dt DTE, count(*) cnt
from tbl_Prices P, tbl_Ticker T, tbl_Return_Rank RR
where T.db_type = 2
and P.db_ticker_id = T.db_ticker_id
and RR.tid = P.db_ticker_id
and P.db_dt = RR.dt
and P.db_dt > '12-31-2006'
and RR.dt > '12-31-2006'
and P.db_close > P.db_MA200
group by P.db_dt
) as A
where dt = A.DTE


update @tbl_Data
set cntB = A.cnt
from (
select P.db_dt DTE, count(*) cnt
from tbl_Prices P, tbl_Ticker T, tbl_Return_Rank RR
where T.db_type = 2
and P.db_ticker_id = T.db_ticker_id
and RR.tid = P.db_ticker_id
and P.db_dt = RR.dt
and P.db_dt > '12-31-2006'
and RR.dt > '12-31-2006'
and P.db_close < P.db_MA200
group by P.db_dt
) as A
where dt = A.DTE

select * from @tbl_Data
order by dt