USE [IDToDSN_DKC]
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_EOM_Return]    Script Date: 3/3/2015 9:51:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dikesh Chokshi
-- Create date: 2-27-2015
-- Description:	Unline r<1,3,6,12> in tbl_Return,
-- which are returns of previous 1,3,6 and 12
-- months, this SP calcs return by using price of 
-- month & month+1
-- So to calc return for Jan, it uses the closing
-- price of 1st Jan and 1st Feb
-- =============================================
ALTER PROCEDURE [dbo].[csp_Calc_EOM_Return] 
(
	-- Add the parameters for the function here
	@sdt datetime=null,
	@edt datetime=null,
	@tid int
)
AS
/*
DECLARE @tid int
select @tid=db_ticker_id from tbl_Ticker where db_strTicker='TLT'
EXECUTE [dbo].[csp_Calc_EOM_Return] 
   NULL
  ,NULL
  ,@tid
*/

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


declare @tbl table (idx int identity, tid int, tick varchar(50), dt datetime, sPrice money, ePrice money, EOM_Ret money)

--insert @tbl
--select db_ticker_id, db_dt, db_close as sPrice, LAG(db_close, 1, db_close) over (order by db_dt) as ePrice, 0
--from tbl_Prices
--where db_dt between @sdt and @edt
--and db_ticker_id = @tid

if @sdt is null set @sdt = '12-31-2006'
if @edt is null set @edt = getdate()

insert @tbl
select tid, T.db_strTicker, dt, price as sPrice, lead(price, 1, price) over (order by dt) as ePrice, 0
from tbl_Ticker T, tbl_Return_Rank
where T.db_ticker_id = tbl_Return_Rank.tid
and dt between @sdt and @edt
and tid = @tid
order by dt


update @tbl
set EOM_Ret = (eprice-sprice)/sprice

select * from @tbl
order by idx

END
