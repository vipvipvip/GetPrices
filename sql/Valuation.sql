--select * 
--from tbl_Stats
--where db_DividendShare is not null

declare @tbl table (tid int, tick varchar(10), val dec(9,3), price dec(9,3), div dec(9,3), bv dec(9,3), pmargin dec(9,3))
insert @tbl
select T.db_ticker_id, T.db_strTicker  
--,(S.db_ProfitMargin + (S.db_DividendShare/P.db_close))/(P.db_close/S.db_BookValue)
,S.db_EPS/(P.db_close/S.db_BookValue)
,P.db_close
,S.db_DividendShare, S.db_BookValue, S.db_ProfitMargin 
from tbl_Ticker T, tbl_Stats S, tbl_Prices P
where T.db_ticker_id = S.db_ticker_id
and S.db_ticker_id = P.db_ticker_id
and P.db_dt = '5-19-2017'
and S.db_DividendShare is not null
and S.db_EPS > 0
and S.db_BookValue is not null
select * from @tbl T, tbl_Stats S
where T.tid = S.db_ticker_id
--and T.tick = 'cutr'
--and val >= 10
order by val desc
