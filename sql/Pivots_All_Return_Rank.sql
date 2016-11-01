if 1=0
begin
--- All Strategy Tickers Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte,
 [VTI],
[VEU],
[VNQ],
[TIP],
[TLT],
[IVV],
[VO],
[VB],
[ACWX],
[IYR],
[AGG],
[VCR],
[VDC],
[VDE],
[VFH],
[VHT],
[VIS],
[VAW],
[VGT],
[VPU],
[IWV],
[IJH],
[IJR],
[EEM],
[LQD],
[BLV],
[EMB],
[HYG],
[ONEQ],
[GLD],
 'ALL' as DataSet
from (
select T.db_strTicker, FN.dt as dt, coalesce(FN.rRank,0) as rRank
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VTI',
'VEU',
'VNQ',
'TIP',
'TLT',
'IVV',
'VO',
'VB',
'ACWX',
'IYR',
'AGG',
'VCR',
'VDC',
'VDE',
'VFH',
'VHT',
'VIS',
'VAW',
'VGT',
'VPU',
'IWV',
'IJH',
'IJR',
'EEM',
'LQD',
'BLV',
'EMB',
'HYG',
'ONEQ',
'GLD'
)
and FN.dt > '12-31-2006'
) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([VTI],
[VEU],
[VNQ],
[TIP],
[TLT],
[IVV],
[VO],
[VB],
[ACWX],
[IYR],
[AGG],
[VCR],
[VDC],
[VDE],
[VFH],
[VHT],
[VIS],
[VAW],
[VGT],
[VPU],
[IWV],
[IJH],
[IJR],
[EEM],
[LQD],
[BLV],
[EMB],
[HYG],
[ONEQ],
[GLD])
) as Pvt
order by dt
--- All Strategy Tickers Prices
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte,
 round([VTI],2) as VTI,
round([VEU],2) as VEU,
round([VNQ],2) as VNQ,
round([TIP],2) as TIP,
round([TLT],2) as TLT,
round([IVV],2) as IVV,
round([VO],2) as VO,
round([VB],2) as VB,
round([ACWX],2) as ACWX,
round([IYR],2) as IYR,
round([AGG],2) as AGG,
round([VCR],2) as VCR,
round([VDC],2) as VDC,
round([VDE],2) as VDE,
round([VFH],2) as VFH,
round([VHT],2) as VHT,
round([VIS],2) as VIS,
round([VAW],2) as VAW,
round([VGT],2) as VGT,
round([VPU],2) as VPU,
round([IWV],2) as IWV,
round([IJH],2) as IJH,
round([IJR],2) as IJR,
round([EEM],2) as EEM,
round([LQD],2) as LQD,
round([BLV],2) as BLV,
round([EMB],2) as EMB,
round([HYG],2) as HYG,
round([ONEQ],2) as ONEQ,
round([GLD],2) as GLD,
'ALL' as DataSet
from (
select T.db_strTicker , FN.dt as dt, coalesce(FN.price,0) as price
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VTI',
'VEU',
'VNQ',
'TIP',
'TLT',
'IVV',
'VO',
'VB',
'ACWX',
'IYR',
'AGG',
'VCR',
'VDC',
'VDE',
'VFH',
'VHT',
'VIS',
'VAW',
'VGT',
'VPU',
'IWV',
'IJH',
'IJR',
'EEM',
'LQD',
'BLV',
'EMB',
'HYG',
'ONEQ',
'GLD')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([VTI],
[VEU],
[VNQ],
[TIP],
[TLT],
[IVV],
[VO],
[VB],
[ACWX],
[IYR],
[AGG],
[VCR],
[VDC],
[VDE],
[VFH],
[VHT],
[VIS],
[VAW],
[VGT],
[VPU],
[IWV],
[IJH],
[IJR],
[EEM],
[LQD],
[BLV],
[EMB],
[HYG],
[ONEQ],
[GLD])
) as Pvt
order by dt
end
/**********************************************************/
--- All Strategy Tickers Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte,
[VTI],
[VNQ],
[ONEQ],
[VEU],
[EEM],
[TIP],
[LQD],
[EMB],
[HYG],
[GLD],
[TLT],
[AGG],
 'ALL' as DataSet
from (
select T.db_strTicker, FN.dt as dt, coalesce(FN.rRank,0) as rRank
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VTI',
'VNQ',
'ONEQ',
'VEU',
'EEM',
'TIP',
'LQD',
'EMB',
'HYG',
'GLD',
'TLT',
'AGG'
)
and FN.dt > '12-31-2006'
) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([VTI],
[VNQ],
[ONEQ],
[VEU],
[EEM],
[TIP],
[LQD],
[EMB],
[HYG],
[GLD],
[TLT],
[AGG])
) as Pvt
order by dt
--- All Strategy Tickers Prices
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte,
 round([VTI],2) as VTI,
round([VNQ],2) as VNQ,
round([ONEQ],2) as ONEQ,
round([VEU],2) as VEU,
round([EEM],2) as EEM,
round([TIP],2) as TIP,
round([LQD],2) as LQD,
round([EMB],2) as EMB,
round([HYG],2) as HYG,
round([GLD],2) as GLD,
round([TLT],2) as TLT,
round([AGG],2) as AGG,
'ALL' as DataSet
from (
select T.db_strTicker , FN.dt as dt, coalesce(FN.price,0) as price
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VTI',
'VNQ',
'ONEQ',
'VEU',
'EEM',
'TIP',
'TLT',
'AGG',
'LQD',
'EMB',
'HYG',
'GLD',
'TLT',
'AGG')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([VTI],
[VNQ],
[ONEQ],
[VEU],
[EEM],
[TIP],
[LQD],
[EMB],
[HYG],
[GLD],
[TLT],
[AGG])
) as Pvt
order by dt