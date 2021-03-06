--Step 1 - update STrend Tab
EXEC	[dbo].[csp_Calc_FiveNum_Trend_Monthly] 
GO

-- Step 2 - Update SnP Tab
EXEC	[dbo].[csp_GetActualMonthValues]

-- Step 3 - Calc Rankings
EXEC	[dbo].[csp_Calc_Ret_Monthly]
		@sdt = '8-2-2017' -- change date to first trading day of the month.
		,@tick=null
		,@srcFN='etf.csv'

select * from tbl_Return_Rank
where dt >= '10-1-2017'
order by rRank desc

-- Step 4 - Update prices - should be second biz day of the month
-- Import tickers from csv
declare @tbl table (s varchar(50), id int default(0))

insert @tbl (s)
--EXEC	[dbo].[csp_ReadCSV]
--		@filename = N'etf.csv',
--		@dbDir = N'c:\stockmon',
--		@whereclause = N'1=1'
select db_strTicker from tbl_Ticker where db_type=2 order by db_strTicker

update @tbl
set id = A.TICKID
from (select db_ticker_id TICKID, db_strTicker SYMBOL from tbl_Ticker) A
where s = A.SYMBOL

select * from @tbl

update tbl_Return_Rank
set price = CLS
from ( select db_close CLS, db_dt DTE, db_ticker_id from tbl_Prices, 
		(select * from @tbl) X
		where X.id = db_ticker_id
	) A 
where tid = db_ticker_id and dt = DTE

-- Alternate update to get next day's price
update tbl_Return_Rank
set price = CLS
from ( 
select B.db_close CLS, A.dt DTE, B.db_ticker_id
from tbl_Return_Rank A, tbl_Prices B,(select * from @tbl) X
where B.db_ticker_id = A.tid
and X.id = B.db_ticker_id
and X.id = A.tid
and B.db_dt = A.dt+1
) A
where tid = A.db_ticker_id and dt = A.DTE

--non-consecutive dates which are not updated via dt+1.
update tbl_Return_Rank
set price = CLS
from ( 
select B.db_close CLS, A.dt DTE, B.db_ticker_id
from tbl_Return_Rank A, tbl_Prices B,(select * from @tbl) X
where B.db_ticker_id = A.tid
and X.id = B.db_ticker_id
and X.id = A.tid
and B.db_ticker_id = A.tid
and B.db_dt in 
	('6-4-2007',
	'2-4-2008',
	'8-4-2008',
	'1-5-2009',
	'5-4-2009',
	'4-5-2010',
	'4-4-2011',
	'6-5-2011',
	'6-4-2012',
	'2-4-2013',
	'3-4-2013',
	'11-4-2013',
	'8-4-2014',
	'1-5-2015',
	'5-4-2015',
	'4-4-2016',
	'7-5-2016',
	'10-3-2016',
	'11-1-2016',
	'1-2-2017',
	'4-3-2017',
	'7-3-2017',
	'10-2-2017'
	)
and Year(A.dt) = Year(B.db_dt) and Month(A.dt) = Month(B.db_dt)
) A
where tid = A.db_ticker_id and Year(dt) = Year(A.DTE) and Month(dt) = Month(A.DTE)

EXECUTE [csp_Calc_FiveNum_Monthly] 
   @sdt='12-31-2006'
select FN.db_dt, FN.db_rank, count(*) cnt
from tbl_FiveNum FN, tbl_Ticker T
where T.db_type = 2
and FN.db_dt > '12-31-2006'
and FN.db_ticker_id = T.db_ticker_id
group by FN.db_dt,FN.db_rank 
order by FN.db_dt asc,FN.db_rank asc

EXECUTE [dbo].[csp_Calc_Averages] 
   @s_date = '2016-1-1'
  ,@typ =2



/*
For monthyly OneSheet. P2 Pangin portfolio 
*/
select P.db_dt,
case when db_MA15<> 0 and db_EMA10<> 0 and db_MA50 <> 0 and db_MA50 <> 0 
--and db_EMA10 >= db_MA15 and db_EMA10 >= db_MA50  then 1 else 0 end as Signal 
and db_MA50 >= db_MA200 then 1 else 0 end as Signal 
from tbl_Ticker T, tbl_Prices P, tbl_Return_Rank RR
where T.db_ticker_id = P.db_ticker_id
and P.db_ticker_id = RR.tid
and P.db_dt = RR.dt
and T.db_strTicker = 'SPY'
and P.db_dt >= '12-1-2006'
order by RR.dt


-- Step 5 -- Run Piovts_All_Return_Rank.sql
-- Step 6 -- Run Piovts_Return_Rank.sql

-- Step 7 -- delete from tbl_Return_Rank where db_dt = '5-1-2015xx' delete from tbl_Prices where db_dt = '5-1-2015xx'


