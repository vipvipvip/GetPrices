/*
DECLARE @step_id int
DECLARE @s_date datetime
DECLARE @typ int

-- TODO: Set parameter values here.
set @step_id=1
set @s_date= dateadd(d, -25, getdate())
set @typ=1
while @step_id < 9
  begin
	print 'Step ID= ' + convert(varchar, @step_id)
	EXECUTE [csp_Update_MulBDBDlier] 
	   @step_id
	  ,@s_date
	  ,@typ

	set @step_id = @step_id + 1
  end

EXEC	[sp_GenSignals] 1
EXEC	[sp_Calc_Portfolio]
SELECT     strTicker as OpenPosition, convert(char(2),month(bdate)) + '-' + convert(char(2),day(bdate)) + '-' + convert(char(4),year(bdate)) as bdt, convert(char(2),month(sdate)) + '-' + convert(char(2),day(sdate)) + '-' + convert(char(4),year(sdate)) as sdt, nshares, bprice, sprice, buy_amount, nshares*sprice as sell_amount, nshares*sprice-buy_amount as profit
FROM       tbl_Trades
where bBuy=1 and nshares > 0
order by bdate asc,strTicker, sdate asc
SELECT     strTicker, convert(char(2),month(bdate)) + '-' + convert(char(2),day(bdate)) + '-' + convert(char(4),year(bdate)) as bdt, convert(char(2),month(sdate)) + '-' + convert(char(2),day(sdate)) + '-' + convert(char(4),year(sdate)) as sdt, nshares, bprice, sprice, buy_amount, nshares*sprice as sell_amount, nshares*sprice-buy_amount as profit
FROM       tbl_Trades
where nShares > 0
ORDER BY bdate, sdate, strTicker
SELECT     strTicker, convert(char(2),month(bdate)) + '-' + convert(char(2),day(bdate)) + '-' + convert(char(4),year(bdate)) as bdt, convert(char(2),month(sdate)) + '-' + convert(char(2),day(sdate)) + '-' + convert(char(4),year(sdate)) as sdt, nshares, bprice, sprice, buy_amount, nshares*sprice as sell_amount, nshares*sprice-buy_amount as profit
FROM       tbl_Trades
ORDER BY bdate, sdate, strTicker

*/

/*

select * from 
(
select distinct(T.db_ticker_id), T.db_type, max(P.db_dt) as DT,T.db_strTicker
from tbl_Prices P, tbl_Ticker T
where P.db_ticker_id = T.db_ticker_id
group by T.db_ticker_id, T.db_type, T.db_strTicker
) A
where DT >=  '8-7-2015'


select distinct(T.db_ticker_id), T.db_type, max(P.db_dt),T.db_strTicker
from tbl_Prices P, tbl_Ticker T
where P.db_ticker_id = T.db_ticker_id
and T.db_type=2
and P.db_dt >= '2017-5-19'
group by T.db_ticker_id, T.db_type, T.db_strTicker
order by max(db_dt) desc, db_strTicker

declare @sdt1 datetime

select @sdt1 = max(db_dt)
from tbl_Prices
where db_ticker_id = 538

select @sdt1

select T.db_strticker, max(db_dt)
from tbl_Prices P, tbl_Ticker T
where P.db_ticker_id = T.db_ticker_id
and T.db_type=1
and P.db_dt = @sdt1
group by T.db_strticker, P.db_dt
order by P.db_dt


--delete from tbl_Prices
--where db_dt >= '6-02-2017'
--and db_type=1

select P.db_row_id, P.db_dt, P.db_close
from tbl_Prices P, tbl_Ticker T
where P.db_ticker_id = T.db_ticker_id
and T.db_strTicker = 'MTUM'
--and db_dt = (select max(db_dt) from tbl_Prices)
--and db_dt = @sdt1
--and T.db_ticker_id = 454
--and datepart(dw,P.db_dt) = 2 -- Monday
order by P.db_dt
--order by db_change_rank asc

select *
from tbl_Trades 
where bBuy=1 and nshares > 0
order by bdate desc,strTicker, sdate asc


select T.db_strticker, P.*
from tbl_Prices P, tbl_Ticker T
where P.db_ticker_id = T.db_ticker_id
--and db_dt = (select max(db_dt) from tbl_Prices)
and T.db_strticker = 'cmg'
--and P.db_ticker_id = 496
and P.db_dt > '1-1-2004'
--and P.db_dt >= (select min(bdate) from tbl_Trades where ticker_id = P.db_ticker_id)
--and p.db_dt <= (select max(sdate) from tbl_Trades where ticker_id = P.db_ticker_id)
order by P.db_dt desc

select T.db_strticker, P.*
from tbl_Prices P, tbl_Ticker T
where P.db_ticker_id = T.db_ticker_id
and P.db_rank = 1
and P.db_dt >= '1-1-2005'
order by P.db_dt desc

select T.db_strticker, P.*
from tbl_Prices P, tbl_Ticker T
where P.db_ticker_id = T.db_ticker_id
and P.db_change_rank <= 10
and P.db_dt >= '1-1-2005'
and datediff(d, P.db_dt, getdate() ) <= 10
and P.db_rank_change < 0
order by P.db_dt desc

select sum(buy_amount) as Purchase, sum(nshares*db_close) as Sold, sum(nshares*db_close) - sum(buy_amount) as profit
from tbl_trades, tbl_Prices
where  tbl_trades.ticker_id =  tbl_Prices.db_ticker_id
and tbl_trades.sdate =  tbl_Prices.db_dt
and bBuy=1
and nshares>0
and sdate='2-7-2012'

*/
/*
select T.db_strticker, P2.db_close/P1.db_close*100 - 100 as pct
from tbl_Prices P1, tbl_Prices P2, tbl_Ticker T
where P1.db_ticker_id = T.db_ticker_id
and P1.db_dt = '11-1-2011'
and P2.db_dt = '11-21-2011'
and P1.db_ticker_id = P2.db_ticker_id
order by pct desc

*/

/*
select db_ticker_id, count(*) from tbl_Prices group by db_ticker_id where db_ticker_id = 538

select T.db_strticker, P.db_ticker_id, T.db_ticker_id
from tbl_Prices P
right outer join tbl_Ticker T
on P.db_ticker_id = T.db_ticker_id
and db_dt >= '1-1-2001'
where P.db_ticker_id is null

declare @tid int
set @tid = 130
delete from tbl_Prices
where db_ticker_id in ( @tid)
delete from tbl_FiveNum
where db_ticker_id in ( @tid )
delete from tbl_FiveNum_Daily
where db_ticker_id in ( @tid )
delete from tbl_FiveNum_Weekly
where db_ticker_id in ( @tid )
delete from tbl_Freq_Rank
where db_ticker_id in ( @tid )
delete from tbl_Return_Rank
where tid in ( @tid )
delete from tbl_Ticker 
where db_ticker_id in ( @tid )


select db_ticker_id, min(db_dt) from tbl_Prices
where db_type=2
group by db_ticker_id
order by db_dt


select *
from tbl_Prices
where db_dt = (select max(db_dt) from tbl_Prices)
and db_ticker_id = 540

select *
from tbl_Prices
where (db_close is null or db_mult is null or db_avg is null or db_index is null or db_rank is null or db_change_rank is null)
and db_type=1

select *
from tbl_Trades
where (sdate is null or nshares is null)

select db_ticker_id, max(db_dt)
from tbl_Prices
where db_type=1
group by db_ticker_id


select P.db_ticker_id, T.db_strTicker, max(P.db_dt)
from tbl_Prices P, tbl_Ticker T
where T.db_type=1
and P.db_ticker_id = T.db_ticker_id
group by T.db_strTicker, P.db_ticker_id

*/
/*
-- Import tickers from csv
declare @tbl table (s varchar(50))

insert @tbl
EXEC	[dbo].[csp_ReadCSV]
		@filename = N'ishares_Factor.csv',
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

delete from @tbl where s like '%.%'
delete from @tbl where s like '%--%'
delete from @tbl where s like '%/%'

insert tbl_Ticker
select s, 2, null, '6/4/2017' from  @tbl 
left outer join tbl_Ticker T on T.db_strTicker = s
where db_strTicker is null
order by T.db_strTicker

*/

/*
-- Import ticker from XLS
declare @tbl table (s varchar(50), typ smallint)
DECLARE	@retval int

insert @tbl
EXEC	[dbo].[csp_ReadXLSTab]
		@ssa_filename = N'c:\TickerSymbols.xls',
		@tab = N'otherlisted',
		@retval = @retval OUTPUT

delete from @tbl where s like '%.%'
delete from @tbl where s like '%$%'

declare @tbl2 table (s varchar(50), nm varchar(500))
insert @tbl2
EXEC	[dbo].[csp_ReadXLSTab]
		@ssa_filename = N'c:\TickerSymbols.xls',
		@tab = N'nasdaqlisted',
		@retval = @retval OUTPUT

delete from @tbl2 where s like '%.%'
delete from @tbl2 where s like '%$%'
delete from @tbl2 where nm not like '%Common Stock%'

insert @tbl
select s, 1 from @tbl2
where s not in (select s from @tbl)

--insert tbl_Ticker
select s, 1, null, '11/6/2013' from @tbl where s not in (select db_strticker from tbl_Ticker)
--select * from @tbl2 where s not in (select db_strticker from tbl_Ticker)

--select * from tbl_BSE_Ticker where db_scrip_cd not in (select id from @tbl)

*/

/*
-- hi low related logic
select db_dt, db_hi_cnt, db_lo_cnt, (db_lo_cnt+1) / (db_hi_cnt+1), db_close
from tbl_Prices
where db_hi_cnt is not null and db_lo_cnt is not null
and db_ticker_id = 538
order by db_dt desc

select T.db_strticker, P.db_ticker_id, db_close, db_rank, db_change_rank
from tbl_Prices P, tbl_Ticker T
where P.db_ticker_id = T.db_ticker_id
and P.db_hi_lo = 1
and db_dt = (select max(db_dt) from tbl_Prices where db_ticker_id=538)

select T.db_strticker, P.db_ticker_id, db_close, db_rank, db_change_rank
from tbl_Prices P, tbl_Ticker T
where P.db_ticker_id = T.db_ticker_id
and T.db_type=1
--and P.db_hi_lo = 0
and db_dt = (select max(db_dt) from tbl_Prices where db_ticker_id=538)
order by db_change_rank
*/

/* Freq Related
select FR.db_ticker_id, T.db_strTicker, count(*) as cnt
FROM tbl_Freq_Rank FR, tbl_Ticker T
  where FR.db_ticker_id = T.db_ticker_id 
  and db_dt > '12-30-2006'
group by FR.db_ticker_id, T.db_strTicker

EXECUTE [csp_Calc_Freq_Monthly] 
   @sdt='7-1-2013'
  ,@tick='TLT'

EXEC	[csp_Get_FR_By_Date]
		--@sdt = N'2-1-2013'

EXECUTE [csp_Calc_Freq_For_Strategy_Tickers] @sdt='3-1-2013'
 
SELECT
	 FR.*, T.db_strTicker, P.db_close
  FROM tbl_Freq_Rank FR, tbl_Ticker T, tbl_Prices P
  where FR.db_ticker_id = T.db_ticker_id 
  and T.db_strTicker = 'TLT'
  and FR.db_dt = P.db_dt
  and FR.db_ticker_id = P.db_ticker_id
  and P.db_dt > '12-30-2006'

-- run this every month after tbl_Prices is updated.
update tbl_Freq_Rank
set db_close = CLS
from ( select db_close CLS, db_dt DTE, db_ticker_id TID from tbl_Prices) A 
where db_ticker_id = TID and db_dt = DTE  
*/
/*
-- Get data for Model XLS
SELECT
	 FR.*, T.db_strTicker, P.db_close
  FROM tbl_Freq_Rank FR, tbl_Ticker T, tbl_Prices P
  where FR.db_ticker_id = T.db_ticker_id 
  and T.db_strTicker = 'TLT'
  and FR.db_dt = P.db_dt
  and FR.db_ticker_id = P.db_ticker_id
  and P.db_dt > '12-30-2006'
*/
/*
--Five Num Related

EXEC	[csp_Calc_FiveNum_Monthly]
		@sdt = '12-31-2002',
		@tick = 'AGG'

EXECUTE [csp_Calc_FiveNum_Weekly] 
  @db_dt = '5-1-2013'
  ,@tick_id = -1
  ,@str_ticker = 'IBM'
  		
EXECUTE [csp_Get_FiveNum_By_Date] 
   @sdt = '2-1-2013'

SELECT T.db_strTicker, FN.*, P.db_close
  FROM [tbl_FiveNum] FN, tbl_Ticker T, tbl_Prices P
  where FN.db_ticker_id = T.db_ticker_id 
  and T.db_strTicker = 'vcr'
  and FN.db_dt = P.db_dt
  and FN.db_ticker_id = P.db_ticker_id
  and FN.db_dt > '12-20-2006'
   
EXECUTE [csp_Calc_FiveNum_For_Strategy_Tickers] 5, @sdt='3-6-2013'

-- run this every month after tbl_Prices is updated.
update tbl_FiveNum
set db_close = CLS
from ( select db_close CLS, db_dt DTE, db_ticker_id TID from tbl_Prices) A 
where db_ticker_id = TID and db_dt = DTE

*/

/*
-- return related
EXEC	[dbo].[csp_Calc_Ret_Monthly]
		@sdt = '11-1-2013',
		@tick = 'AOK'

EXECUTE [csp_Calc_Ret_For_Strategy_Tickers] @Curr_dt = '6-13-2014', @typ=2

SELECT  T.db_strTicker, FN.*, P.db_close, P.db_avg, P.db_mult
  FROM [tbl_Return_Rank]  FN, tbl_Ticker T, tbl_Prices P
  where FN.tid = T.db_ticker_id 
  and T.db_strTicker = 'SDS'
  and FN.dt = P.db_dt
  and FN.tid = P.db_ticker_id
  and FN.dt > '12-30-2002'
  order by FN.dt
  
-- run this every month after tbl_Prices is updated.
update tbl_Return_Rank
set price = CLS
from ( select db_close CLS, db_dt DTE, db_ticker_id from tbl_Prices) A 
where tid = db_ticker_id and dt = DTE

*/

/* Fan related
declare @s_date datetime
declare @e_date datetime
declare @typ int

set @s_date = '6-10-2014'
set @e_date = '6-14-2014'
set @typ = 1

EXECUTE [csp_Calc_Averages_2] 
   @s_date=@s_date
  ,@e_date=@e_date
  ,@typ = @typ
  --,@tick_id=177
*/

/* Fan related
declare @s_date datetime
declare @typ int

set @s_date = '1-1-2014'
set @typ = 1

EXECUTE [csp_CollectFans] 
   @sdt = @s_date
  ,@typ=@typ 

*/