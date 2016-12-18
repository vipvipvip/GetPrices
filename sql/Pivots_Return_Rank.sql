select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([SPY],2) as SPY,round([TLT],2) as TLT, 'Month Begin Price for Signal Generation' as DataSet
from (
select T.db_strTicker , FN.dt as dt, P.db_close 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id
inner join tbl_Prices P on FN.tid  = P.db_ticker_id
where T.db_strticker in ('SPY','TLT')
and FN.dt > '12-31-2002'
and P.db_dt = FN.dt
) as Src
PIVOT
(	sum(Src.db_close)
	FOR Src.db_strTicker in ([SPY],[TLT])
) as Pvt


--- TIA2003 Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [SPY], [TLT], 'TIA2003' as DataSet
from (
select T.db_strTicker, FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('SPY',	'TLT')
and FN.dt > '12-31-2002'
) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([SPY],[TLT])
) as Pvt
--- TIA2003 Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([SPY],2) as SPY,round([AGG],2) as AGG, 'TIA2003' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('SPY','AGG')
and FN.dt > '12-31-2002'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([SPY],[AGG])
) as Pvt

--- TDA Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [VTI],	coalesce([VEU],0) as VEU, [TLT], 'TDA' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VTI',	'VEU',	'TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([VTI],	[VEU],	[TLT])
) as Pvt
--- TDA Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([VTI],2) as VTI, coalesce([VEU],0) as VEU, round([TLT],2) as TLT, 'TDA' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VTI',	'VEU','TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([VTI],	[VEU], [TLT])
) as Pvt

--- TDA_Norm Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [QQQ],[TLT], 'TDA_Norm' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('QQQ',	'TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([QQQ],[TLT])
) as Pvt

--- TDA_Norm Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([QQQ],2) as QQQ,round([TLT],2) as TLT, 'TDA_Norm' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('QQQ',	'TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([QQQ],[TLT])
) as Pvt
--- FID Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [IWV],[EEM],[TLT], 'FID' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('IWV',	'EEM','TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([IWV],[EEM],[IYR],[TLT])
) as Pvt
--- FID Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([IWV],2) as IWV,round([EEM],2) as EEM,round([TLT],2) as TLT, 'FID' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('IWV',	'EEM','TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([IWV],[EEM],[TLT])
) as Pvt

if (1=0)
begin
--- SPDR Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [VCR],[VDC],[VDE],[VFH],[VHT],[VIS],[VAW],[VGT],[VPU],[VNQ],[AGG], 'SPDR' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VCR','VDC','VDE','VFH','VHT','VIS','VAW','VGT','VPU','VNQ','AGG')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([VCR],[VDC],[VDE],[VFH],[VHT],[VIS],[VAW],[VGT],[VPU],[VNQ],[AGG])
) as Pvt
order by dt
--- SPDR Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([VCR],2) as VCR,round([VDC],2) as VDC,round([VDE],2) as VDE,round([VFH],2) as VFH,round([VHT],2) as VHT,round([VIS],2) as VIS,round([VAW],2) as VAW,round([VGT],2) as VGT,round([VPU],2) as VPU,round([VNQ],2) as VNQ,round([AGG],2) as AGG, 'SPDR' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VCR','VDC','VDE','VFH','VHT','VIS','VAW','VGT','VPU','VNQ','AGG')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([VCR],[VDC],[VDE],[VFH],[VHT],[VIS],[VAW],[VGT],[VPU],[VNQ],[AGG])
) as Pvt
order by dt
end

--- TIA Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [RSP],[TLT], 'TIA' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('RSP',	'TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([RSP],[TLT])
) as Pvt

--- TIA Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([RSP],2) as RSP,round([TLT],2) as TLT, 'TIA' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('RSP',	'TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([RSP],[TLT])
) as Pvt

if (1=0)
begin
--- VG Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [VTI],	[VWO],	[VEU],	coalesce([EDV],0) as EDV, 'VG' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VTI',	'VWO',	'VEU',	'EDV')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([VTI],	[VWO],	[VEU],	[EDV])
) as Pvt
--- VG Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([VTI],2) as VTI, round([VWO],2) as VWO,round([VEU],2) as VEU, coalesce(round([EDV],2),0) as EDV, 'VG' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VTI',	'VWO',	'VEU',	'EDV')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([VTI],	[VWO],	[VEU],	[EDV])
) as Pvt
end

--- TDA_CAP Rank
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [SPY],[VO],[VB],[VEU],[TLT], 'TDA_CAP' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('SPY',	'VO','VB','VEU',	'TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([SPY],[VO],[VB],[VEU],[TLT])
) as Pvt

--- TDA_CAP Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([SPY],2) as SPY,round([VO],2) as VO,round([VB],2) as VB,round([VEU],2) as VEU,round([TLT],2) as TLT, 'TDA_Cap' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('SPY',	'VO','VB','VEU',	'TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([SPY],[VO],[VB],[VEU],[TLT])
) as Pvt

if (1=0)
begin
--AOX
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, coalesce([AOA],0) as [AOA], coalesce([AOR],0) as [AOR],	coalesce([AOM],0) as [AOM],	coalesce([AOK],0) as [AOK], [TLT], 'AOX' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('AOA',	'AOR',	'AOM',	'AOK', 'TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([AOA],	[AOR],[AOM],[AOK],[TLT])
) as Pvt
--- AOX Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, coalesce(round([AOA],2),0) as AOA, coalesce(round([AOR],2),0) as AOR,coalesce(round([AOM],2),0) as AOM,coalesce(round([AOK],2),0) as AOK, round([TLT],2) as TLT, 'AOX' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('AOA',	'AOR',	'AOM',	'AOK','TLT')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([AOA],	[AOR],	[AOM],	[AOK],[TLT])
) as Pvt
end
if (1=0)
begin
--Fid MF
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [FOCPX],	[JAVTX],	[IEV],	[FBALX], [FLBIX], 'Fid_MF' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('FOCPX',	'JAVTX',	'IEV',	'FBALX', 'FLBIX')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([FOCPX],	[JAVTX],[IEV],[FBALX], [FLBIX])
) as Pvt
--- Fid MF Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([FOCPX],2) as FOCPX, round([JAVTX],2) as JAVTX,round([IEV],2) as IEV,round([FBALX],2) as FBALX,round([FLBIX],2) as FLBIX,'Fid_MF' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('FOCPX',	'JAVTX',	'IEV',	'FBALX','FLBIX')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([FOCPX],	[JAVTX],	[IEV],	[FBALX],[FLBIX])
) as Pvt
end

if (1=0)
begin
--VG MF
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [VGSTX],	[VDIGX],	[VINEX],	[VSEQX], [VUSTX], 'VG_MF' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VGSTX',	'VDIGX',	'VINEX',	'VSEQX', 'VUSTX')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([VGSTX],	[VDIGX],[VINEX],[VSEQX],[VUSTX])
) as Pvt
--- VG MF Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([VGSTX],2) as VGSTX, round([VDIGX],2) as VDIGX,round([VINEX],2) as VINEX,round([VSEQX],2) as VSEQX, round([VUSTX], 2) as VUSTX, 'VG_MF' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VGSTX',	'VDIGX',	'VINEX',	'VSEQX', 'VUSTX')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([VGSTX],	[VDIGX],	[VINEX],	[VSEQX], [VUSTX])
) as Pvt
end

if (1=0)
begin
-- VG LifeStrategy Funds
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, [VASGX],	[VSMGX],	[VSCGX],	[VASIX], [VUSTX], 'VG_MF' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VASGX',	'VSMGX',	'VSCGX',	'VASIX', 'VUSTX')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([VASGX],	[VSMGX],[VSCGX],[VASIX],[VUSTX])
) as Pvt
--- VG LifeStrategy Funds Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, round([VASGX],2) as VASGX, round([VSMGX],2) as VSMGX,round([VSCGX],2) as VSCGX,round([VASIX],2) as VASIX, round([VUSTX], 2) as VUSTX, 'VG_MF' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('VASGX',	'VSMGX',	'VSCGX',	'VASIX', 'VUSTX')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([VASGX],	[VSMGX],	[VSCGX],	[VASIX], [VUSTX])
) as Pvt
end

if (1=0)
begin
--INCOME
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, coalesce([PFF],0) as [PFF], coalesce([IDV],0) as [IDV],	coalesce([HDV],0) as [HDV],	coalesce([HYG],0) as [HYG], [AGG], 'INCOME' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.rRank 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('PFF',	'IDV',	'HDV',	'HYG', 'AGG')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.rRank)
	FOR Src.db_strTicker in ([PFF],	[IDV],[HDV],[HYG],[AGG])
) as Pvt
--- INCOME Price
select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, coalesce(round([PFF],2),0) as PFF, coalesce(round([IDV],2),0) as IDV,coalesce(round([HDV],2),0) as HDV,coalesce(round([HYG],2),0) as HYG, round([AGG],2) as AGG, 'INCOME' as DataSet
from (
select T.db_strTicker , FN.dt as dt, FN.price 
from tbl_Return_Rank FN
inner join tbl_Ticker T on FN.tid  = T.db_ticker_id    
where T.db_strticker in ('PFF',	'IDV',	'HDV',	'HYG','AGG')
and FN.dt > '12-31-2006'

) as Src
PIVOT
(	sum(Src.price)
	FOR Src.db_strTicker in ([PFF],	[IDV],	[HDV],	[HYG],[AGG])
) as Pvt
end
