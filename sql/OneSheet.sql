declare @tbl TABLE (idx int identity, dates datetime
	,SPY dec(5,2), QQQ dec(5,2), IJR dec(5,2), TLT dec(5,2)
	,SPY_Raw_Allocn dec(5,2),QQQ_Raw_Allocn dec(5,2), IJR_Raw_Allocn dec(5,2)

	,TotEq_Allocn dec(5,2)

	,SPY_Norm_Allocn dec(9,2),QQQ_Norm_Allocn dec(5,2), IJR_Norm_Allocn dec(5,2), TLT_Norm_Allocn dec(5,2) 

	,SPY_Return dec(9,2), QQQ_Return dec(9,2), IJR_Return dec(9,2), TLT_Return dec(9,2), Portfolio_Return dec(9,2)

	,Portfolio_Growth int, SPY_Growth int, Bond_Growth int

	,SPY_Signal int
					)
insert @tbl
select '12-29-2006',  0,0,0,0,  0,0,0,  0,  0,0,0,0, 0,0,0,0,0,  100000,100000,100000,  0 

insert @tbl
SELECT *, 0,0,0,0,  0,0,0,  0,  0,0,0,0, 0,0,0,0,0,  0,0,0,  0 FROM [dbo].[fn_GetWeeklyDates] ('12-31-2006','SPY')



declare @SPYID int
select @SPYID=db_ticker_id from tbl_Ticker where db_strTicker = 'SPY'

declare @QQQID int
select @QQQID=db_ticker_id from tbl_Ticker where db_strTicker = 'QQQ'

declare @IJRID int
select @IJRID=db_ticker_id from tbl_Ticker where db_strTicker = 'IJR'

declare @TLTID int
select @TLTID=db_ticker_id from tbl_Ticker where db_strTicker = 'TLT'



declare @idx int
set @idx = 2

declare @dt datetime
while exists (select * from @tbl where idx = @idx)
  begin
	select @dt=dates from @tbl where idx = @idx
	update @tbl
	set TLT = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt > @dt and db_ticker_id = @TLTID) as A
	where dates = @dt

	if @@ROWCOUNT=0
	update @tbl
	set TLT = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt >= @dt and db_ticker_id = @TLTID) as A
	where dates = @dt

	-- set Prices
	update @tbl
	set SPY = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt > @dt and db_ticker_id = @SPYID) as A
	where dates = @dt


	if @@ROWCOUNT=0
	update @tbl
	set SPY = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt >= @dt and db_ticker_id = @SPYID) as A
	where dates = @dt

	update @tbl
	set QQQ = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt > @dt and db_ticker_id = @QQQID) as A
	where dates = @dt

	if @@ROWCOUNT=0
	update @tbl
	set QQQ = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt >= @dt and db_ticker_id = @QQQID) as A
	where dates = @dt

	update @tbl
	set IJR = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt > @dt and db_ticker_id = @IJRID) as A
	where dates = @dt

	if @@ROWCOUNT=0
	update @tbl
	set IJR = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt >= @dt and db_ticker_id = @IJRID) as A
	where dates = @dt

	-- Set Raw Allocation
	update @tbl
	set SPY_Raw_Allocn = round(TLT/(SPY+TLT) * 100.0,0)
	where dates = @dt

	update @tbl
	set QQQ_Raw_Allocn = round(TLT/(QQQ+TLT) * 100.0,0)
	where dates = @dt

	update @tbl
	set IJR_Raw_Allocn = round(TLT/(IJR+TLT) * 100.0,0)
	where dates = @dt

	-- Update SPY Signal EMA25 > MA50
	update @tbl
	set SPY_Signal = A.Signal
	from (select case when db_EMA25<>0 and db_MA50<>0 and db_EMA25>=db_MA50 then 1 else 0 end as Signal from tbl_Prices where db_dt = @dt and db_ticker_id = @SPYID) as A
	where dates = @dt


	-- Set TotEquity Allocation
	update @tbl
	set TotEq_Allocn = case when SPY_Signal=1 then round((SPY_Raw_Allocn*.33 + QQQ_Raw_Allocn*.33 + IJR_Raw_Allocn*.34)*2,0) else 100 end
	where dates = @dt


	-- Normalize Raw Allocation
	update @tbl
	set SPY_Norm_Allocn = round( 
		case when (TotEq_Allocn>100 and SPY_Signal=1) then SPY_Raw_Allocn*.33*2*(100.0-(TotEq_Allocn-100.0))/100
		else
			 case when TotEq_Allocn<100 then SPY_Raw_Allocn*.33/2 else SPY_Raw_Allocn*.33 end
		end,0)
	where dates = @dt

	update @tbl
	set QQQ_Norm_Allocn = round( 
		case when (TotEq_Allocn>100 and SPY_Signal=1) then QQQ_Raw_Allocn*.33*2*(100.0-(TotEq_Allocn-100.0))/100
		else
			 case when TotEq_Allocn<100 then QQQ_Raw_Allocn*.33/2 else QQQ_Raw_Allocn*.33 end
		end,0)
	where dates = @dt

	update @tbl
	set IJR_Norm_Allocn = round( 
		case when (TotEq_Allocn>100 and SPY_Signal=1) then IJR_Raw_Allocn*.34*2*(100.0-(TotEq_Allocn-100.0))/100
		else
			 case when TotEq_Allocn<100 then IJR_Raw_Allocn*.33/2 else IJR_Raw_Allocn*.33 end
		end,0)
	where dates = @dt

	update @tbl
	set TLT_Norm_Allocn = case when 100-(SPY_Norm_Allocn+QQQ_Norm_Allocn+IJR_Norm_Allocn) < 0 then 0 else 100-(SPY_Norm_Allocn+QQQ_Norm_Allocn+IJR_Norm_Allocn) end
	where dates = @dt

	set @idx = @idx + 1
  end

  -- Update return
  update @tbl
  set SPY_Return = A.Ret
  from ( select dates as DTE, round(100 * (lead(SPY, 1,0) over (order by idx)/SPY - 1),2)  as Ret from @tbl where idx>1) as A
  where dates = DTE

  update @tbl
  set QQQ_Return = A.Ret
  from ( select dates as DTE, round(100 * (lead(QQQ, 1,0) over (order by idx)/QQQ - 1),2)  as Ret from @tbl where idx>1) as A
  where dates = DTE

  update @tbl
  set IJR_Return = A.Ret
  from ( select dates as DTE, round(100 * (lead(IJR, 1,0) over (order by idx)/IJR - 1),2)  as Ret from @tbl where idx>1) as A
  where dates = DTE

  update @tbl
  set TLT_Return = A.Ret
  from ( select dates as DTE, round(100 * (lead(TLT, 1,0) over (order by idx)/TLT - 1),2)  as Ret from @tbl where idx>1) as A
  where dates = DTE

  update @tbl
  set Portfolio_Return = SPY_Norm_Allocn*SPY_Return/100 + QQQ_Norm_Allocn*QQQ_Return/100 + IJR_Norm_Allocn*IJR_Return/100 + TLT_Norm_Allocn*TLT_Return/100
  where idx>1


  -- update Growth
set @idx =2
declare @pamt int, @samt int, @bamt int
set @pamt=100000
set @samt=100000
set @bamt=100000
while exists (select * from @tbl where idx = @idx)
  begin
	update @tbl
	set Portfolio_Growth = @pamt * (1 + Portfolio_Return/100)
	where idx = @idx

	select @pamt = Portfolio_Growth
	from @tbl where idx = @idx

	update @tbl
	set SPY_Growth = @samt * (1 + SPY_Return/100)
	where idx = @idx

	select @samt = SPY_Growth
	from @tbl where idx = @idx

	update @tbl
	set Bond_Growth = @bamt * (1 + TLT_Return/100)
	where idx = @idx

	select @bamt = Bond_Growth
	from @tbl where idx = @idx

	set @idx = @idx + 1
  end

select * from @tbl

