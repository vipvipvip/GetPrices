-- 4/30/2015 - At the end of the month, duplicate the EOM price to the first of the next month's price - 
-- so that Rank can be calculated. After preparing Scott's XLS, do Step 7
--declare @tbl table (idx int identity, db_ticker_id int, db_volume int, db_dt datetime, db_close dec(9,3))

--insert tbl_Prices (db_ticker_id, db_volume, db_dt, db_close)
--select A.TICKID, 0, '5-1-2015',A.PRICE
--from (
--select db_ticker_id as TICKID, db_close as PRICE from tbl_Prices
--where db_dt = '4-30-2015' and ( db_ticker_id in (538, 471) or db_type = 2 )
--) A

--select db_ticker_id, db_dt,db_close, db_rank from tbl_Prices
--where ( db_ticker_id in (538, 471) or db_type = 2 )
--and db_dt >= '12-31-2004'
--order by db_dt

	declare @sdt datetime
	set @sdt = '5-1-2015'

	select max(db_dt) from tbl_Prices where YEAR(db_dt)=YEAR(@sdt) and MONTH(db_dt)=MONTH(@sdt) and db_ticker_id = 538

	select * from tbl_Return_Rank
	where strTicker = 'TLT'
	order by dt

	select * from tbl_Prices where db_dt = '5-1-2015'
	select * from tbl_Return_Rank where dt = '5-1-2015' order by strTicker
-- ==============================================
-- check first if avg are calculated - run csp_Calc_Averages_2 and EMA_WIP.sql if needed
--select * from tbl_Ticker
--where db_ticker_id in (select db_ticker_id
--from tbl_Prices
--where (db_close is null or db_mult is null or db_avg is null)
--and db_dt = '8-3-2015'
--)

--Step 1 - update STrend Tab
EXEC	[dbo].[csp_Calc_FiveNum_Trend_Monthly] 
GO

-- Step 2 - Update AD1 in TDA_Cap Tab and in Fid_MF
EXEC	[dbo].[csp_GetActualMonthValues]

-- Step 3 - Calc Rankings
EXEC	[dbo].[csp_Calc_Ret_Monthly]
		@sdt = '12-1-2016' -- change date to first trading day of the month.
		,@tick=null
		,@srcFN='etf.csv'


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
	'1-2-2017'
	)
and Year(A.dt) = Year(B.db_dt) and Month(A.dt) = Month(B.db_dt)
) A
where tid = A.db_ticker_id and Year(dt) = Year(A.DTE) and Month(dt) = Month(A.DTE)


-- Step 5 -- Run Pivots_All_Return_Rank.sql
-- Step 6 -- Run Pivots_Return_Rank.sql

-- Step 7 -- delete from tbl_Return_Rank where db_dt = '5-1-2015xx' delete from tbl_Prices where db_dt = '5-1-2015xx'


