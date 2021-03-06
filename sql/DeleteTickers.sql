declare @tbl table (idx int identity, tick varchar(10), tid int)
--insert @tbl
--select db_strTicker,db_ticker_id 
--from tbl_Ticker where db_ticker_id in (
--select db_ticker_id from tbl_Prices
--where db_close <= 2.0
--and db_dt = '1-10-2014'
--)

--insert @tbl
--select db_strticker, db_ticker_id from tbl_Ticker 
--where db_ticker_id not in (
--select distinct(db_ticker_id) from tbl_Prices where db_dt='1-13-2014')
--and db_type=1

  --insert @tbl
  --select T.db_strTicker, T.db_ticker_id
  --FROM [IDToDSN_DKC].[dbo].[tbl_Prices] P, tbl_Ticker T
  --where P.db_ticker_id = T.db_ticker_id
  --and db_dt = (select max(db_dt)
		--		from tbl_Prices
		--		where db_ticker_id = 538)
  --and P.db_mult > P.db_avg
  --and P.db_avg > db_index
  --and P.db_close < 3.0

declare @tbl_csv table (idx int identity, s varchar(50))

insert @tbl_csv
EXEC	[dbo].[csp_ReadCSV]
		@filename = N'del.txt',
		@dbDir = N'c:\temp',
		@whereclause = N'1=1'



delete from @tbl_csv
where idx >= (select top 1 idx from @tbl_csv where s is null)

insert @tbl
select s, 0 from @tbl_csv
  
if 1=0
begin
insert @tbl
select 'CTW',0
union
select 'UAN',0
union
select 'NEV',0
union
select'MPA',0
union
select'EIA',0
union
select'PTM',0
union
select'AIW',0
union
select'GEK',0
union
select'RCKB',0
union
select'EVN',0
union
select'MUA',0
union
select'PYK',0
union
select'SZO',0
union
select'INFL',0
union
select'MAV',0
union
select'AI',0
end

update @tbl
set tid = A.TID
from (select db_ticker_id TID, db_strTicker TICKER from tbl_Ticker where db_strTicker in (select tick from @tbl)) as A
where tick = A.TICKER 

select * from tbl_Ticker where db_ticker_id in (select tid from @tbl)

delete from tbl_Prices
where db_ticker_id in ( select tid from @tbl)
delete from tbl_FiveNum
where db_ticker_id in ( select tid from @tbl )
delete from tbl_FiveNum_Daily
where db_ticker_id in ( select tid from @tbl )
delete from tbl_FiveNum_Weekly
where db_ticker_id in ( select tid from @tbl )
delete from tbl_Freq_Rank
where db_ticker_id in ( select tid from @tbl )
delete from tbl_Return_Rank
where tid in ( select tid from @tbl )
delete from tbl_Stats
where db_ticker_id in ( select tid from @tbl )
delete from tbl_Ticker 
where db_ticker_id in ( select tid from @tbl )

select * from tbl_Ticker where db_ticker_id in (select tid from @tbl)
select COUNT(*) as NumTickers from tbl_Ticker
/*
  select P.db_ticker_id, T.db_strTicker, P.db_mult-P.db_avg+P.db_avg-P.db_index as IDX
  FROM [IDToDSN_DKC].[dbo].[tbl_Prices] P, tbl_Ticker T
  where P.db_ticker_id = T.db_ticker_id
  and db_dt = '12-31-2013'
  and P.db_mult > P.db_avg
  and P.db_avg > db_index
  and P.db_close >= 10.0
  and P.db_mult-P.db_avg+P.db_avg-P.db_index >= .29
  order by IDX
 */ 