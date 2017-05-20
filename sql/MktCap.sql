declare @tbl table (s varchar(50), tid int)
insert @tbl
EXEC	[dbo].[csp_ReadCSV]
		@cols='Ticker, 0',
		@filename = N'IVV.csv',
		@dbDir = N'C:\stockmon',
		@whereclause = N'1=1'


update @tbl
set tid = A.TICKID
from (select db_ticker_id TICKID, db_strTicker TICKER from tbl_Ticker) as A
where s = A.TICKER


delete from @tbl where tid = 0

declare @dt1 datetime

select @dt1 = max(db_dt)
from tbl_Prices
where db_ticker_id = 538

--select * from @tbl
--where tid not in
--(
select T.db_ticker_id
, T.db_strTicker, convert(money, P.db_close*S.db_share_outstanding/1000000000) as MKTCAP
--,RR.r1, RR.r3, RR.r6, RR.r12
from tbl_Prices P, tbl_Ticker T, tbl_Stats S
--, tbl_Return_Rank RR
where P.db_ticker_id = T.db_ticker_id
and T.db_ticker_id = S.db_ticker_id
--and S.db_ticker_id = RR.tid
and T.db_ticker_id in (select tid from @tbl)
and P.db_dt = @dt1
--and RR.dt = '2017-4-3'
--)
order by P.db_close*S.db_share_outstanding desc
