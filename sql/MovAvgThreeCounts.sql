declare @tbl_Dates table (idx int identity, dt datetime)

insert @tbl_Dates
--select db_dt
--from tbl_Prices
--where db_dt in (
--SELECT * FROM [dbo].[fn_GetWeeklyDates] (
--   '1-1-2007'
--  ,'SPY')
--)
--and db_ticker_id = (select db_ticker_id from tbl_Ticker where db_strTicker = 'SPY')
--order by db_dt

select dt
from tbl_Return_Rank
where tid = 442
and dt >= '1-1-2007'

declare @sdt datetime
declare @typ int
set @typ = 2
declare @tbl table (s varchar(30))
declare @stks table (idx int identity, dt datetime, cntA int, cntB int, cntC int)

declare @idx int
set @idx=1

insert @tbl
--EXEC	[dbo].[csp_ReadCSV]
--		@filename = N'etf.csv',
--		@dbDir = N'c:\stockmon',
--		@whereclause = N'1=1'
select db_strTicker from tbl_Ticker where db_type = @typ

while exists (select * from @tbl_Dates where idx = @idx)
 begin
	select @sdt = dt from @tbl_Dates where idx = @idx

	insert @stks
	select P.db_dt, count(*),0,0
	from tbl_Prices P, tbl_Ticker T,  @tbl TBL
	where P.db_ticker_id = T.db_ticker_id
	and TBL.s = T.db_strTicker
	and T.db_type=@typ
	and db_dt = @sdt
	and P.db_close > 10
	and P.db_ticker_id = T.db_ticker_id
	and P.[db_MA50] is not null
	and P.[db_MA50] is not null
	and P.[db_EMA25] is not null
	and P.[db_MA15] is not null
	and P.[db_EMA10] is not null
	and P.db_EMA10 >= P.db_MA15
	and P.db_MA15 >= P.db_MA50
	and P.db_EMA10 >= P.db_MA50
	and P.db_MA50 >= P.db_MA200
	group by P.db_dt


	update @stks
	set cntB = A.cnt
	from (
	SELECT P.db_dt DTE, count(*) as cnt 
	FROM [StockDB].[dbo].[tbl_Prices] P, tbl_Ticker T
	where T.db_type = @typ
	and P.db_ticker_id = T.db_ticker_id
	and P.[db_MA50] is not null
	  and P.[db_MA50] is not null
	  and P.[db_MA200] is not null
	  and P.[db_EMA25] is not null
	  and P.[db_MA15] is not null
	  and P.[db_EMA10] is not null

	  and P.db_close <= P.db_MA50
	  and P.db_close >= P.db_MA200

	  and P.db_EMA10 >= P.db_MA15
	  and P.db_EMA10 <= P.db_MA50

	  and P.db_MA50 >= P.db_MA200
	and P.db_dt = @sdt
	group by P.db_dt
	) as A
	where dt = A.DTE
	--and idx = @idx

	update @stks
	set cntC = A.cnt
	from (
	SELECT P.db_dt DTE, count(*) as cnt 
	FROM [StockDB].[dbo].[tbl_Prices] P, tbl_Ticker T
	where T.db_type = @typ
	and P.db_ticker_id = T.db_ticker_id
	and P.[db_MA50] is not null
	and P.[db_MA200] is not null
	and P.[db_EMA25] is not null
	and P.[db_MA15] is not null
	and P.[db_EMA10] is not null

	and P.db_MA50 >= P.db_MA200
	and P.db_EMA10 >= P.db_MA15
	and P.db_MA15 <= P.db_MA200
	and P.db_EMA10 <= P.db_MA200
	and P.db_dt = @sdt
	group by P.db_dt
	) as A
	where dt = A.DTE
	--and idx = @idx

	set @idx= @idx+1
  end

select * from @stks
/*
	SELECT 
      T.[db_ticker_id]
	  ,T.db_strTicker
      ,P.[db_close]
      ,P.[db_MA50]
      ,P.[db_MA50]
      ,P.[db_EMA25]
      ,P.[db_MA15]
      ,P.[db_EMA10]
  FROM [StockDB].[dbo].[tbl_Prices] P, tbl_Ticker T
  where T.db_type = @typ
  and P.db_ticker_id = T.db_ticker_id
	and P.[db_MA50] is not null
	  and P.[db_MA50] is not null
	  and P.[db_MA200] is not null
	  and P.[db_EMA25] is not null
	  and P.[db_MA15] is not null
	  and P.[db_EMA10] is not null

	  and P.db_close <= P.db_MA50
	  and P.db_close >= P.db_MA200

	  and P.db_EMA10 >= P.db_MA15
	  and P.db_EMA10 <= P.db_MA50

	  and P.db_MA50 >= P.db_MA200
  and P.db_dt = @sdt
  order by db_strTicker

SELECT 
T.[db_ticker_id]
,T.db_strTicker
,P.[db_close]
,P.[db_MA50]
,P.[db_MA50]
,P.[db_EMA25]
,P.[db_MA15]
,P.[db_EMA10]
FROM [StockDB].[dbo].[tbl_Prices] P, tbl_Ticker T
where T.db_type = @typ
and P.db_ticker_id = T.db_ticker_id
	and P.[db_MA50] is not null
	and P.[db_MA200] is not null
	and P.[db_EMA25] is not null
	and P.[db_MA15] is not null
	and P.[db_EMA10] is not null

	and P.db_MA50 >= P.db_MA200
	and P.db_EMA10 >= P.db_MA15
	and P.db_MA15 <= P.db_MA200
	and P.db_EMA10 <= P.db_MA200

and P.db_dt = @sdt
order by db_strTicker
*/
