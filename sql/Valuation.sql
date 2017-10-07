-- StockAna.xls method
SELECT T.[db_ticker_id]
,T.db_strTicker
,S.[db_revenue]
,S.[db_net_income]
,S.[db_share_outstanding]
,P.db_close
,convert(dec(9,2),(S.db_revenue*power(1+S.db_RevGrowth,5) * S.db_ProfitMargin/S.db_share_outstanding) * (P.db_close / S.db_EPS)) as ProjPrice
,convert(dec(9,2),(S.db_revenue*power(1+S.db_RevGrowth,5) * S.db_ProfitMargin/S.db_share_outstanding) * (P.db_close / S.db_EPS) / power(1.15,5)) as BuyPrice
,convert(dec(5,2),S.db_EPS) as EPS
,S.db_RevGrowth as RevGrowth
,S.db_ProfitMargin
,convert(dec(9,2),(P.db_close / S.db_EPS)) as PE
,convert(dec(34,0),S.db_revenue*power(1+S.db_RevGrowth,5)) as Sales
,convert(dec(34,0),S.db_revenue*power(1+S.db_RevGrowth,5) * S.db_ProfitMargin) as NI
,convert(dec(9,2),S.db_revenue*power(1+S.db_RevGrowth,5) * S.db_ProfitMargin/S.db_share_outstanding) as EPS
, case 
when (S.db_revenue*power(1+S.db_RevGrowth,5) * S.db_ProfitMargin/S.db_share_outstanding) * (P.db_close / S.db_EPS) / power(1.15,5) > P.db_close then 1
else 0
END as BUY
FROM [StockDB].[dbo].[tbl_Stats] S, tbl_Ticker T, tbl_Prices P
where S.db_ticker_id = T.db_ticker_id 
and T.db_ticker_id = P.db_ticker_id
and P.db_dt = (select max(db_dt) from tbl_Prices where db_ticker_id = 3)
and S.db_EPS > 0
and S.db_RevGrowth > 0
and S.db_RevGrowth  <= .30
and S.db_share_outstanding > 0
and (S.db_revenue*power(1+S.db_RevGrowth,5) * S.db_ProfitMargin/S.db_share_outstanding) * (P.db_close / S.db_EPS) / power(1.15,5) > P.db_close
and S.db_BookValue > 0
and S.db_Revgrowth < 1.0
and (P.db_close / S.db_EPS) < 30
and (P.db_close / S.db_BookValue) <= 1
and S.db_ProfitMargin <= .50
order by T.db_strTicker --P.db_close / S.db_BookValue


/*
declare @tbl table (tid int, tick varchar(10), val dec(9,3), price dec(9,3), div dec(9,3), bv dec(9,3), pmargin dec(9,3))
insert @tbl
select T.db_ticker_id, T.db_strTicker  
,(S.db_ProfitMargin + (S.db_DividendShare/P.db_close))/(P.db_close/S.db_BookValue)
--,S.db_EPS/(P.db_close/S.db_BookValue)
,P.db_close
,S.db_DividendShare, S.db_BookValue, S.db_ProfitMargin 
from tbl_Ticker T, tbl_Stats S, tbl_Prices P
where T.db_ticker_id = S.db_ticker_id
and S.db_ticker_id = P.db_ticker_id
and P.db_dt = '7-21-2017'
and S.db_DividendShare is not null
and S.db_EPS > 0
and S.db_BookValue is not null
select * from @tbl T, tbl_Stats S
where T.tid = S.db_ticker_id
--and T.tick = 'cutr'
--and val >= 10
order by val desc
*/
