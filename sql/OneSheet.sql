set nocount on;

declare @tbl TABLE (idx int identity, dates datetime
	,SPY_MON dec(5,2), QQQ_MON dec(5,2), RSP_MON dec(5,2),  VTIXXX_MON dec(5,2), TLT_MON dec(5,2)

	,SPY_FRI dec(5,2), QQQ_FRI dec(5,2), RSP_FRI dec(5,2),  VTIXXX_FRI dec(5,2), TLT_FRI dec(5,2)

	,SPY_Raw_Allocn dec(5,2),QQQ_Raw_Allocn dec(5,2), RSP_Raw_Allocn dec(5,2), VTIXXX_Raw_Allocn dec(5,2)

	,TotEq_Allocn dec(5,2)

	,SPY_Norm_Allocn dec(9,2),QQQ_Norm_Allocn dec(5,2), RSP_Norm_Allocn dec(5,2), VTIXXX_Norm_Allocn dec(5,2), TLT_Norm_Allocn dec(5,2) 

	,SPY_Return dec(9,2), QQQ_Return dec(9,2), RSP_Return dec(9,2), VTIXXX_Return dec(9,2), TLT_Return dec(9,2), Portfolio_Return dec(9,2)

	,Portfolio_Growth int, SPY_Growth int, Bond_Growth int

	,SPY_Signal int
					)
declare @nRows int

insert @tbl
select '12-29-2006',  0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,  0,  0,0,0,0,0,  0,0,0,0,0,0,  100000,100000,100000,  0 

insert @tbl
SELECT *, 0,0,0,0,0,  0,0,0,0,0,  0,0,0,0,  0,  0,0,0,0,0,  0,0,0,0,0,0,  0,0,0,  0 FROM [dbo].[fn_GetWeeklyDates] ('12-31-2006','SPY')

select @nRows = @@ROWCOUNT

declare @lastDate datetime
select @lastDate = dates from @tbl where idx = @nRows
print @lastDate


declare @SPYID int
select @SPYID=db_ticker_id from tbl_Ticker where db_strTicker = 'SPY'

declare @QQQID int
select @QQQID=db_ticker_id from tbl_Ticker where db_strTicker = 'QQQ'

declare @RSPID int
select @RSPID=db_ticker_id from tbl_Ticker where db_strTicker = 'RSP'

declare @VTIXXXID int
select @VTIXXXID=db_ticker_id from tbl_Ticker where db_strTicker = 'VTIXXX'

declare @TLTID int
select @TLTID=db_ticker_id from tbl_Ticker where db_strTicker = 'TLT'

update @tbl
set SPY_MON = A.CLS
from (select db_dt as DTE, db_close as CLS from tbl_Prices where db_dt = @lastDate and db_ticker_id = @SPYID) as A
where dates = A.DTE

update @tbl
set QQQ_MON = A.CLS
from (select db_dt as DTE, db_close as CLS from tbl_Prices where db_dt = @lastDate and db_ticker_id = @QQQID) as A
where dates = A.DTE

update @tbl
set RSP_MON = A.CLS
from (select db_dt as DTE, db_close as CLS from tbl_Prices where db_dt = @lastDate and db_ticker_id = @RSPID) as A
where dates = A.DTE

update @tbl
set VTIXXX_MON = A.CLS
from (select db_dt as DTE, db_close as CLS from tbl_Prices where db_dt = @lastDate and db_ticker_id = @VTIXXXID) as A
where dates = A.DTE


update @tbl
set TLT_MON = A.CLS
from (select db_dt as DTE, db_close as CLS from tbl_Prices where db_dt = @lastDate and db_ticker_id = @TLTID) as A
where dates = A.DTE


declare @idx int
set @idx = 2

declare @sdt datetime
while exists (select * from @tbl where idx = @idx)
  begin
	select @sdt=dates from @tbl where idx = @idx


	--if @@ROWCOUNT=0
	update @tbl
	set TLT_FRI = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt = @sdt and db_ticker_id = @TLTID) as A
	where dates = @sdt

	
	update @tbl
	set TLT_MON =  case when A.CLS<=0 or A.CLS is null then B.CLS else A.CLS end
	from (select top 1 db_close as CLS from tbl_Prices where db_dt > @sdt and db_ticker_id = @TLTID) as A,
	(select TLT_FRI as CLS from @tbl where idx = @idx) as B
	where idx = @idx

	-- set Prices
	update @tbl
	set SPY_MON = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt > @sdt and db_ticker_id = @SPYID) as A
	where dates = @sdt


	--if @@ROWCOUNT=0
	update @tbl
	set SPY_FRI = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt = @sdt and db_ticker_id = @SPYID) as A
	where dates = @sdt

	update @tbl
	set QQQ_MON = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt > @sdt and db_ticker_id = @QQQID) as A
	where dates = @sdt

	--if @@ROWCOUNT=0
	update @tbl
	set QQQ_FRI = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt = @sdt and db_ticker_id = @QQQID) as A
	where dates = @sdt

	update @tbl
	set RSP_MON = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt > @sdt and db_ticker_id = @RSPID) as A
	where dates = @sdt

	--if @@ROWCOUNT=0
	update @tbl
	set RSP_FRI = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt = @sdt and db_ticker_id = @RSPID) as A
	where dates = @sdt


	update @tbl
	set VTIXXX_MON = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt > @sdt and db_ticker_id = @VTIXXXID) as A
	where dates = @sdt

	--if @@ROWCOUNT=0
	update @tbl
	set VTIXXX_FRI = A.CLS
	from (select top 1 db_close as CLS from tbl_Prices where db_dt = @sdt and db_ticker_id = @VTIXXXID) as A
	where dates = @sdt


	-- Set Raw Allocation
	update @tbl
	set SPY_Raw_Allocn = round(TLT_FRI/(SPY_FRI+TLT_FRI) * 100.0,0)
	where dates = @sdt

	update @tbl
	set QQQ_Raw_Allocn = round(TLT_FRI/(QQQ_FRI+TLT_FRI) * 100.0,0)
	where dates = @sdt

	update @tbl
	set RSP_Raw_Allocn = round(TLT_FRI/(RSP_FRI+TLT_FRI) * 100.0,0)
	where dates = @sdt

	update @tbl
	set VTIXXX_Raw_Allocn = case when VTIXXX_FRI=0 then 0 else round(TLT_FRI/(VTIXXX_FRI+TLT_FRI) * 100.0,0) end
	where dates = @sdt

	-- Update SPY Signal EMA25 > MA50
	update @tbl
	set SPY_Signal = A.Signal
	from (select case when db_MA15<> 0 and db_EMA10<> 0 and db_MA50 <> 0 and db_MA50 <> 0 and db_EMA10 >= db_MA15 and db_EMA10 >= db_MA50  then 1 else 0 end as Signal  from tbl_Prices where db_dt = @sdt and db_ticker_id = @SPYID) as A
	where dates = @sdt


	-- Set TotEquity Allocation
	update @tbl
	set TotEq_Allocn = case when SPY_Signal=1 then round((SPY_Raw_Allocn*.33 + QQQ_Raw_Allocn*.33 + RSP_Raw_Allocn*.33 + VTIXXX_Raw_Allocn*.33)*2,2) else 100 end
	where dates = @sdt


	-- Normalize Raw Allocation
	update @tbl
	set SPY_Norm_Allocn = round( 
		case when (TotEq_Allocn>100 and SPY_Signal=1) then SPY_Raw_Allocn*.33*2*(100.0-(TotEq_Allocn-100.0))/100
		else
			 case when TotEq_Allocn<100 then SPY_Raw_Allocn*.33/2 else SPY_Raw_Allocn*.33 end
		end,0)
	where dates = @sdt

	update @tbl
	set QQQ_Norm_Allocn = round( 
		case when (TotEq_Allocn>100 and SPY_Signal=1) then QQQ_Raw_Allocn*.33*2*(100.0-(TotEq_Allocn-100.0))/100
		else
			 case when TotEq_Allocn<100 then QQQ_Raw_Allocn*.33/2 else QQQ_Raw_Allocn*.33 end
		end,0)
	where dates = @sdt

	update @tbl
	set RSP_Norm_Allocn = round( 
		case when (TotEq_Allocn>100 and SPY_Signal=1) then RSP_Raw_Allocn*.33*2*(100.0-(TotEq_Allocn-100.0))/100
		else
			 case when TotEq_Allocn<100 then RSP_Raw_Allocn*.33/2 else RSP_Raw_Allocn*.33 end
		end,0)
	where dates = @sdt

	update @tbl
	set VTIXXX_Norm_Allocn = case when VTIXXX_FRI<=0 then 0 else
		round( 
			case when (TotEq_Allocn>100 and SPY_Signal=1) then VTIXXX_Raw_Allocn*.33*2*(100.0-(TotEq_Allocn-100.0))/100
			else
				 case when TotEq_Allocn<100 then VTIXXX_Raw_Allocn*.33/2 else VTIXXX_Raw_Allocn*.33 end
			end,0)
		end
	where dates = @sdt

	update @tbl
	set TLT_Norm_Allocn = case when 100-(SPY_Norm_Allocn+QQQ_Norm_Allocn+RSP_Norm_Allocn) < 0 then 0 
							else 
								case when 100-(SPY_Norm_Allocn+QQQ_Norm_Allocn+RSP_Norm_Allocn+VTIXXX_Norm_Allocn) < 0 then 0
								else 100-(SPY_Norm_Allocn+QQQ_Norm_Allocn+RSP_Norm_Allocn+VTIXXX_Norm_Allocn)
							 end
						  end
	where dates = @sdt

	set @idx = @idx + 1
  end


  -- Update return
  update @tbl
  set SPY_Return = A.Ret
  from ( select dates as DTE, round(100 * (lead(SPY_MON, 1,0) over (order by idx)/SPY_MON - 1),2)  as Ret from @tbl where idx>1 and idx <= @nRows) as A
  where dates = A.DTE
  and idx < @nRows

  update @tbl
  set QQQ_Return = A.Ret
  from ( select dates as DTE, round(100 * (lead(QQQ_MON, 1,0) over (order by idx)/QQQ_MON - 1),2)  as Ret from @tbl where idx>1 and idx <= @nRows) as A
  where dates = A.DTE
  and idx < @nRows

  update @tbl
  set RSP_Return = A.Ret
  from ( select dates as DTE, round(100 * (lead(RSP_MON, 1,0) over (order by idx)/RSP_MON - 1),2)  as Ret from @tbl where idx>1 and idx <= @nRows) as A
  where dates = A.DTE
  and idx < @nRows

  --update @tbl
  --set VTIXXX_Return = A.Ret
  --from ( select dates as DTE, round(100 * (lead(VTIXXX_MON, 1,0) over (order by idx)/VTIXXX_MON - 1),2)  as Ret from @tbl where idx>1 and idx <= @nRows) as A
  --where dates = A.DTE
  --and idx < @nRows


  update @tbl
  set TLT_Return = A.Ret
  from ( select dates as DTE, round(100 * (lead(TLT_MON, 1,0) over (order by idx)/TLT_MON - 1),2)  as Ret from @tbl where idx>1 and idx <= @nRows) as A
  where dates = A.DTE
  and idx < @nRows
  
  update @tbl
  set Portfolio_Return = SPY_Norm_Allocn*SPY_Return/100 + QQQ_Norm_Allocn*QQQ_Return/100 + RSP_Norm_Allocn*RSP_Return/100 + VTIXXX_Norm_Allocn*VTIXXX_Return/100 + TLT_Norm_Allocn*TLT_Return/100
  where idx>1
  and idx <= @nRows-1

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
