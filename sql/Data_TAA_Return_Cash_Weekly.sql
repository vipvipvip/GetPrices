select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, 
coalesce(round([AAPL],2),0) as AAPL,
coalesce(round([AGG],2),0) as AGG,
coalesce(round([AMZN],2),0) as AMZN,
coalesce(round([DIA],2),0) as DIA,
coalesce(round([IJR],2),0) as IJR,
coalesce(round([MSFT],2),0) as MSFT,
coalesce(round([QQQ],2),0) as QQQ,
coalesce(round([RSP],2),0) as RSP,
coalesce(round([SPY],2),0) as SPY, 
coalesce(round([TLT],2),0) as TLT,
 'Weekly' as DataSet
from (
select T.db_strTicker , P.db_dt as dt, P.db_close 
from tbl_Prices P
inner join tbl_Ticker T on P.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('AAPL', 'AGG', 'AMZN', 'DIA','IJR', 'MSFT', 'QQQ', 'RSP', 'SPY','TLT')
and P.db_dt > '1-1-2006'
) as Src
PIVOT
( sum(Src.db_close)
  FOR Src.db_strTicker in ([AAPL], [AGG], [AMZN], [DIA],[IJR],[MSFT],[QQQ], [RSP], [SPY],[TLT])
) as Pvt
order by dt asc


select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, 
coalesce(round([AAPL],2),0) as AAPL,
coalesce(round([AMZN],2),0) as AMZN, 
coalesce(round([DIA],2),0) as DIA,
coalesce(round([IJR],2),0) as IJR,
coalesce(round([MSFT],2),0) as MSFT,
coalesce(round([IJR],2),0) as QQQ,
coalesce(round([RSP],2),0) as RSP,
coalesce(round([SPY],2),0) as SPY, 
coalesce(round([TLT],2),0) as TLT,
 'Weekly' as DataSet
from (
select T.db_strTicker , P.db_dt as dt, case when db_MA15<> 0 and db_EMA10<> 0 and db_MA50 <> 0 and db_MA50 <> 0 and db_EMA10 >= db_MA15 and db_EMA10 >= db_MA50  then 1 else 0 end as Signal 
from tbl_Prices P
inner join tbl_Ticker T on P.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('AAPL', 'AMZN', 'DIA','IJR', 'MSFT', 'QQQ', 'RSP','SPY','TLT')
and P.db_dt > '1-1-2006'
) as Src
PIVOT
( sum(Src.Signal)
  FOR Src.db_strTicker in ([AAPL],[AMZN], [DIA],[IJR],[MSFT],[QQQ], [RSP], [SPY],[TLT])
) as Pvt
order by dt asc
