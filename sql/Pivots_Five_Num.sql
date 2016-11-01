--- TIA2003 Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [SPY], [TLT], 'TIA2003' as DataSet
from (
select T.db_strTicker, FN.db_dt as dt, FN.db_rank 
from IDToDSN_DKC.dbo.tbl_FiveNum FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('SPY',	'TLT')
and FN.db_dt > '12-31-2002'
) as Src
PIVOT
(	sum(Src.db_rank)
	FOR Src.db_strTicker in ([SPY],[TLT])
) as Pvt
--- TIA2003 Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([SPY],2) as SPY,round([TLT],2) as TLT, 'TIA2003' as DataSet
from (
select T.db_strTicker , FN.db_dt as dt, FN.db_close 
from IDToDSN_DKC.dbo.tbl_FiveNum FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('SPY','TLT')
and FN.db_dt > '12-31-2002'

) as Src
PIVOT
(	sum(Src.db_close)
	FOR Src.db_strTicker in ([SPY],[TLT])
) as Pvt

--- TDA Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [VTI],	[VEU],	[VNQ],	[TLT], 'TDA' as DataSet
from (
select T.db_strTicker, FN.db_dt as dt, FN.db_rank 
from IDToDSN_DKC.dbo.tbl_FiveNum FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('VTI',	'VEU',	'VNQ',	'TLT')
and FN.db_dt > '12-31-2006'
) as Src
PIVOT
(	sum(Src.db_rank)
	FOR Src.db_strTicker in ([VTI],	[VEU],	[VNQ],	[TLT])
) as Pvt
--- TDA Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([VTI],2) as VTI, round([VEU],2) as VEU,round([VNQ],2) as VNQ,round([TLT],2) as TLT, 'TDA' as DataSet
from (
select T.db_strTicker , FN.db_dt as dt, FN.db_close 
from IDToDSN_DKC.dbo.tbl_FiveNum FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('VTI',	'VEU',	'VNQ',	'TLT')
and FN.db_dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.db_close)
	FOR Src.db_strTicker in ([VTI],	[VEU],	[VNQ],	[TLT])
) as Pvt

--- TDA_CAP Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [IVV],[VO],[VB],[VNQ],[TLT], 'TDA_CAP' as DataSet
from (
select T.db_strTicker , FN.db_dt as dt, FN.db_rank 
from IDToDSN_DKC.dbo.tbl_FiveNum FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('IVV',	'VO','VB','VNQ',	'TLT')
and FN.db_dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.db_rank)
	FOR Src.db_strTicker in ([IVV],[VO],[VB],[VNQ],[TLT])
) as Pvt

--- TDA_CAP Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([IVV],2) as IVV,round([VO],2) as VO,round([VB],2) as VB,round([VNQ],2) as VNQ,round([TLT],2) as TLT, 'TDA_Cap' as DataSet
from (
select T.db_strTicker , FN.db_dt as dt, FN.db_close
from IDToDSN_DKC.dbo.tbl_FiveNum FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('IVV',	'VO','VB','VNQ',	'TLT')
and FN.db_dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.db_close)
	FOR Src.db_strTicker in ([IVV],[VO],[VB],[VNQ],[TLT])
) as Pvt

--- FID Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [IWV],[EEM],[IYR],[TLT], 'FID' as DataSet
from (
select T.db_strTicker , FN.db_dt as dt, FN.db_rank 
from IDToDSN_DKC.dbo.tbl_FiveNum FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('IWV',	'EEM','IYR','TLT')
and FN.db_dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.db_rank)
	FOR Src.db_strTicker in ([IWV],[EEM],[IYR],[TLT])
) as Pvt
--- FID Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([IWV],2) as IWV,round([EEM],2) as EEM,round([IYR],2) as IYR,round([TLT],2) as TLT, 'FID' as DataSet
from (
select T.db_strTicker , FN.db_dt as dt, FN.db_close
from IDToDSN_DKC.dbo.tbl_FiveNum FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('IWV',	'EEM','IYR','TLT')
and FN.db_dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.db_close)
	FOR Src.db_strTicker in ([IWV],[EEM],[IYR],[TLT])
) as Pvt

--- TIA Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [IVV],[TLT], 'TIA' as DataSet
from (
select T.db_strTicker , FN.db_dt as dt, FN.db_rank 
from IDToDSN_DKC.dbo.tbl_FiveNum FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('IVV',	'TLT')
and FN.db_dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.db_rank)
	FOR Src.db_strTicker in ([IVV],[TLT])
) as Pvt

--- TIA Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([IVV],2) as IVV,round([TLT],2) as TLT, 'TIA' as DataSet
from (
select T.db_strTicker , FN.db_dt as dt, FN.db_close 
from IDToDSN_DKC.dbo.tbl_FiveNum FN
inner join IDToDSN_DKC.dbo.tbl_Ticker T on FN.db_ticker_id  = T.db_ticker_id    
where T.db_strticker in ('IVV',	'TLT')
and FN.db_dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.db_close)
	FOR Src.db_strTicker in ([IVV],[TLT])
) as Pvt