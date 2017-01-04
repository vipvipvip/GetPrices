declare @tbl table (s varchar(50))

insert @tbl
EXEC	[dbo].[csp_ReadCSV]
		@filename = N'DIA.csv',
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

insert @tbl
select 'TLT'

	select convert(char(2),month(dt)) + '-' + convert(char(2),day(dt)) + '-' + convert(char(4),year(dt)) as dte, *
,convert(dec(9,2),TLT/(TLT+AAPL)) as AAPL_pct
,convert(dec(9,2),TLT/(TLT+AXP)) as AXP_pct
,convert(dec(9,2),TLT/(TLT+BA)) as BA_pct
,convert(dec(9,2),TLT/(TLT+CAT)) as CAT_pct
,convert(dec(9,2),TLT/(TLT+CSCO)) as CSCO_pct
,convert(dec(9,2),TLT/(TLT+CVX)) as CVX_pct
,convert(dec(9,2),TLT/(TLT+DD)) as DD_pct
,convert(dec(9,2),TLT/(TLT+DIS)) as DIS_pct
,convert(dec(9,2),TLT/(TLT+GE)) as GE_pct
,convert(dec(9,2),TLT/(TLT+GS)) as GS_pct
,convert(dec(9,2),TLT/(TLT+HD)) as HD_pct
,convert(dec(9,2),TLT/(TLT+IBM)) as IBM_pct
,convert(dec(9,2),TLT/(TLT+INTC)) as INTC_pct
,convert(dec(9,2),TLT/(TLT+JNJ)) as JNJ_pct
,convert(dec(9,2),TLT/(TLT+JPM)) as JPM_pct
,convert(dec(9,2),TLT/(TLT+KO)) as KO_pct
,convert(dec(9,2),TLT/(TLT+MCD)) as MCD_pct
,convert(dec(9,2),TLT/(TLT+MMM)) as MMM_pct
,convert(dec(9,2),TLT/(TLT+MRK)) as MRK_pct
,convert(dec(9,2),TLT/(TLT+MSFT)) as MSFT_pct
,convert(dec(9,2),TLT/(TLT+NKE)) as NKE_pct
,convert(dec(9,2),TLT/(TLT+PFE)) as PFE_pct
,convert(dec(9,2),TLT/(TLT+PG)) as PG_pct
,convert(dec(9,2),TLT/(TLT+TRV)) as TRV_pct
,convert(dec(9,2),TLT/(TLT+UNH)) as UNH_pct
,convert(dec(9,2),TLT/(TLT+UTX)) as UTX_pct
,convert(dec(9,2),TLT/(TLT+V)) as V_pct
,convert(dec(9,2),TLT/(TLT+VZ)) as VZ_pct
,convert(dec(9,2),TLT/(TLT+WMT)) as WMT_pct
,convert(dec(9,2),TLT/(TLT+XOM)) as XOM_pct

	,'Weekly' as DataSet
	from (
	select T.db_strTicker, P.db_dt as dt, convert(dec(9,2),P.db_close) as db_close
	from tbl_Prices P
	inner join tbl_Ticker T on P.db_ticker_id  = T.db_ticker_id    
	where T.db_strticker in (select * from @tbl)
	and P.db_dt > '1-1-2006'
	) as Src
	PIVOT
	( sum(Src.db_close)
	  FOR Src.db_strTicker in (
AAPL
,AXP
,BA
,CAT
,CSCO
,CVX
,DD
,DIS
,GE
,GS
,HD
,IBM
,INTC
,JNJ
,JPM
,KO
,MCD
,MMM
,MRK
,MSFT
,NKE
,PFE
,PG
,TRV
,UNH
,UTX
,V
,VZ
,WMT
,XOM
,TLT

)
	) as Pvt
	order by dt asc
