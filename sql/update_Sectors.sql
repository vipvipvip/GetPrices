/*
C:\data\Program Files\devstudio\GetPrices\GetPrices\bin\Release\upd_Sectors.cmd
getprices id=538 %1 Action=2
getprices id=471 %1 Action=2
getprices id=442 %1 Action=2


getprices ticker=VCR Action=2
getprices ticker=VDC Action=2
getprices ticker=VDE Action=2
getprices ticker=VFH Action=2
getprices ticker=VHT Action=2
getprices ticker=VIS Action=2
getprices ticker=VAW Action=2
getprices ticker=VGT Action=2
getprices ticker=VPU Action=2
getprices ticker=VNQ Action=2


del c:\temp\prices\*.* /Q
pause
*/

declare @tbl_csv table (idx int identity, s varchar(50))
declare @fn varchar(50)
set @fn = 'SectoSPDR.CSV'
insert @tbl_csv
EXEC	[dbo].[csp_ReadCSV]
		@filename = @fn,
		@dbDir = N'c:\stockmon',
		@whereclause = N'1=1'

EXECUTE [csp_Calc_Ret_Monthly] 
   @sdt=null
  ,@srcFN=@fn
  --,@tick='TLT'


update tbl_Return_Rank
set price = CLS
from ( select db_close CLS, db_dt DTE, db_ticker_id from tbl_Prices where db_ticker_id in (
	select db_ticker_id from tbl_Ticker where db_strTicker in (select s from @tbl_csv))) A 
	--select db_ticker_id from tbl_Ticker where db_strTicker in ('RSP','SPY','TLT'))) A 
where tid = db_ticker_id and dt = DTE

