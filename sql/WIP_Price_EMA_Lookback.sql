select top 90 * from
(
select top 90 db_dt, db_close, db_EMA10, db_MA15  from tbl_Prices
where db_ticker_id = 3
and db_dt < '1-3-2017'
order by db_dt desc
) as A
order by db_dt

select * 
from 
(
select db_ticker_id, convert(date,db_dt) as db_dt, db_close,db_EMA10, db_MA15, db_MA50, db_MA200
from tbl_Prices
where db_ticker_id in (select db_ticker_id from tbl_Ticker where db_strTicker = 'aapl')
and db_dt >= '4-1-2016'
) as A
where db_dt >= '8-1-2016'
order by db_dt
GO

SELECT * FROM [dbo].[fn_GetLookBackSignalCount] ('12-1-2016', 3, 109.49)
go

alter function fn_GetLookBackSignalCount (@dt datetime, @tid int, @tgt_Price int)
returns @tblW TABLE(LessCnt int, GreaterEqualCnt int)
as
begin
/*
SELECT * FROM [dbo].[fn_GetLookBackSignalCount] ('12-05-2016', 991, 87)
*/

--declare @dt datetime
--set @dt = '2017-1-20'
--declare @tid int
--set @tid = 991
--declare @tgt_Price int
--set @tgt_Price = 94

declare @tbl_Prices table (idx int identity, dt datetime, cls int, ema10 int, ma15 int)
insert @tbl_Prices
select top 90 * from
(
select top 90 db_dt, db_close, db_EMA10, db_MA15  from tbl_Prices
where db_ticker_id = @tid
and db_dt < @dt
order by db_dt desc
) as A
order by db_dt

declare @cnt int
select @cnt= @@ROWCOUNT

declare @idx int
set @idx = 1
declare @CntA int, @CntB int
set @CntA=0
set @CntB=0

declare @xcls int, @xema10 int, @xma15 int

while exists (select * from @tbl_Prices where idx = @idx)
  begin
	select @xcls=cls,@xema10=ema10, @xma15=ma15 from @tbl_Prices where idx = @idx
	--print '===='
	--print @idx
	--print @tgt_Price
	--print @xcls
	--print '===='
	if ( @tgt_Price = @xcls ) 
	  begin
		if @xema10 < @xma15	set @CntA = @CntA+1
		if @xema10 >= @xma15	set @CntB = @CntB+1
	  end
	set @idx = @idx + 1
  end

insert @tblW
select @CntA, @CntB
return
end

