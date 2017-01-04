declare @sdt datetime = '12-29-2016'
declare @edt datetime = dateadd(d,11,@sdt)
print @edt
declare @tbl table (s varchar(50))
declare @stks table (tick varchar(10), tickId int, dt datetime, cls dec(9,2), Allocation dec(9,2), InvestAmt dec(9,2),  Shares int  )

insert @tbl
--EXEC	[dbo].[csp_ReadCSV]
--		@filename = N'etf.csv',
--		@dbDir = N'c:\stockmon',
--		@whereclause = N'1=1'
select db_strTicker from tbl_Ticker where db_type in (2)

if (1=1)
begin
insert @stks
select T.db_strTicker, P.db_ticker_id, P.db_dt, P.db_close, 0,0,0
--, P.db_MA50, P.db_EMA25, case when P.db_EMA25 > P.db_MA50 then 1 else 0 end as Signal
from tbl_Prices P, tbl_Ticker T,  @tbl TBL
--,tbl_Stats S
where P.db_ticker_id = T.db_ticker_id
--P.db_ticker_id = S.db_ticker_id
and TBL.s = T.db_strTicker
and db_dt = @sdt
and P.db_close > 10
--and S.db_net_income/S.db_share_outstanding > S.db_EPS
--and P.db_close between P.db_MA50 and P.db_MA200
and P.db_EMA25 <= P.db_MA50
and P.db_MA50 >= P.db_MA200
and P.db_close <= P.db_MA50
and P.db_close >= P.db_MA200
order by T.db_strTicker
--,13.58 * S.db_EPS / db_current_price desc
--P.db_EMA25 / P.db_close desc
end

declare @tot dec(9,2)
select @tot = sum(cls) from @stks

if @tot > 0
update @stks
set Allocation = convert(dec(9,0), cls/@tot*100)
, InvestAmt = convert(dec(9,0), 100000.00*cls/@tot)
, Shares = convert(int, 100000.00*cls/@tot/cls)

select * from @stks
where Allocation > 5
order by tickId

select db_ticker_id, db_dt, db_close from tbl_Prices
where db_ticker_id in (select tickId from @stks where Allocation > 5)
and db_dt >= @sdt
and db_dt <= @edt
group by db_ticker_id, db_dt, db_close
order by db_ticker_id