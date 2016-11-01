-- ================================================
-- Collect records from tbl_Prices after running csp_Calc_Averages
-- Specify monthly dates so that we can use stockmon to create
-- monthly ISM files.
-- Copy the tick and idx columns, paste it in x.txt and highlight & replace tabs with spaces.
-- This will put idx in the Date picked column of Stockmon and allow sorting on
-- them. Smaller the idx value, greater the chance 10-15-65 MA forming a fan
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dikesh Chokshi
-- Create date: 1/15/2014
-- Description:	
-- Collect records from tbl_Prices after running csp_Calc_Averages
-- Specify monthly dates so that we can use stockmon to create
-- monthly ISM files.
-- Copy the tick and idx columns, paste it in x.txt and highlight & replace tabs with spaces.
-- This will put idx in the Date picked column of Stockmon and allow sorting on
-- them. Smaller the idx value, greater the chance 10-15-65 MA forming a fan
-- =============================================
ALTER PROCEDURE csp_CollectFans (
	-- Add the parameters for the stored procedure here
	@sdt datetime = null,
	@edt datetime = null
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


-- Collect records from tbl_Prices after running csp_Calc_Averages
-- Specify monthly dates so that we can use stockmon to create
-- monthly ISM files.
-- Copy the tick and idx columns, paste it in x.txt and highlight & replace tabs with spaces.
-- This will put idx in the Date picked column of Stockmon and allow sorting on
-- them. Smaller the idx value, greater the chance 10-15-65 MA forming a fan

if @sdt=null set @sdt = '12-31-2013'
if @edt=null set @edt = GETDATE()

declare @dt datetime
set @dt = @sdt

declare @tbl table (id int identity, tid int, dt datetime, tick varchar(10), idx dec(9,2), LT int, Vol int default(0))

while @dt < @edt
 begin
	select top 1 @dt = db_dt 
	from tbl_Prices
	where db_ticker_id = 538
	and db_dt > @dt
	order by db_dt asc
	
	insert @tbl
	select P.db_ticker_id, P.db_dt, T.db_strTicker, convert(dec(9,2),(P.db_mult-P.db_avg+P.db_avg-P.db_index)/P.db_close * 100) as IDX,
	case when P.db_index > P.db_mult_avg_ratio then 1 
		else 0 
	end
	as 'LT', 0
	  FROM [IDToDSN_DKC].[dbo].[tbl_Prices] P, tbl_Ticker T
	  where P.db_ticker_id = T.db_ticker_id
	  and db_dt = @dt
	  and P.db_mult > P.db_avg
	  and P.db_avg > db_index
	  and P.db_close >= 10.0
	  and P.db_index > P.db_mult_avg_ratio
	  order by LT desc, IDX
  
 end
 declare @cnt int
 select @cnt=count(*) from @tbl
 
 declare @id int
 set @id=1
 declare @tick varchar(10)
 
 while @id < @cnt
  begin
	select @tick = tick, @id=id from @tbl where id = @id
	delete @tbl
	where tick = @tick and id > @id	
	set @id=@id+1
  end


 update @tbl
 set VOL = A.AVGVOL
 from ( select db_ticker_id ITID, avg(db_volume) as AVGVOL 
		from tbl_Prices 
		where db_ticker_id in (select distinct(tid) from @tbl)
		and db_dt between @sdt and @edt
		group by db_ticker_id) as A
 where tid = ITID
 
 select * from @tbl 
 where vol > 300000
 order by idx asc, dt asc
 END
GO
