set nocount on;

declare @tbl table (id int identity, ticker varchar(10))
declare @dt datetime
declare @port varchar(10)
declare @bIndivRank int
--setting to zero uses the tbl_Return_Rank.rRank instead of the individual rankings 
-- of the ETF
set @bIndivRank = 1

--set @port = 'ALL'
--set @port = 'TDA'
--set @port = 'TDA_Cap'
--set @port = 'FID'
--set @port = 'SectorSPDR'
set @port = 'TIA'
--set @port = 'AOX'

if @port = 'AOX'
	begin
	insert @tbl select 'AOA'
	insert @tbl select 'AOR'
	insert @tbl select 'AOM'
	insert @tbl select 'AOK'
	insert @tbl select 'TLT'
	end
if @port = 'ALL'
	begin
	insert @tbl select 'VTI'
	insert @tbl select 'VNQ'
	insert @tbl select 'ONEQ'
	insert @tbl select 'VEU'
	insert @tbl select 'EEM'
	insert @tbl select 'TIP'
	insert @tbl select 'LQD'
	insert @tbl select 'EMB'
	insert @tbl select 'HYG'
	insert @tbl select 'GLD'
	insert @tbl select 'TLT'
	insert @tbl select 'AGG'
	end

if @port = 'TDA'
	begin
	insert @tbl select 'VTI'
	insert @tbl select 'VEU'
	insert @tbl select 'VNQ'
	insert @tbl select 'TLT'
	end

if @port = 'TDA_Cap'
	begin
	insert @tbl select 'IVV'
	insert @tbl select 'VO'
	insert @tbl select 'VB'
	insert @tbl select 'VNQ'
	insert @tbl select 'TLT'
	end

if @port = 'FID'
	begin
	insert @tbl select 'IWV'
	insert @tbl select 'EEM'
	insert @tbl select 'IYR'
	insert @tbl select 'TLT'
	end

if @port = 'SectorSPDR'
	begin
	insert @tbl select 'VCR'
	insert @tbl select 'VDC'
	insert @tbl select 'VDE'
	insert @tbl select 'VFH'
	insert @tbl select 'VHT'
	insert @tbl select 'VIS'
	insert @tbl select 'VAW'
	insert @tbl select 'VGT'
	insert @tbl select 'VPU'
	insert @tbl select 'VNQ'
	insert @tbl select 'TLT'
	end
if @port = 'TIA'
	begin
	insert @tbl select 'RSP'
	insert @tbl select 'TLT'
	end
declare @tbl_Final table (idx int identity, dte datetime, S1 int, S2 int, S3 int, S4 int, S5 int, S6 int, S7 int, S8 int, S9 int, S10 int, S11 int, S12 int, aPort varchar(10))


-- This SP adds the row to tbl_Return_Rank, so,
-- first delete it and
-- then delete at the end
--EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_Ret_For_Strategy_Tickers]


-- now pick up the dates from tbl_Return_Rank
insert @tbl_Final
select distinct(dt),0,0,0,0,0,0,0,0,0,0,0,0, @port as DataSet
from tbl_Return_Rank
where dt > '12-30-2006'
order by dt

declare @tbl_Current table (tid int, strTicker varchar(10), dt datetime, 
					price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2), rRank int)


declare @tbl_Selections table (idx int identity, dte datetime, tid int, price dec(9,3)
		,tick varchar(10), r1 int, r3 int, r6 int, r12 int, vix int, rRank int, r1R int, r3R int, r6R int, r12R int, rVIX int, rR int)


declare @i int
set @i = 1

declare @j int
set @j=1

declare @tick varchar(10)
declare @sql nvarchar(max)

-- iterate monthly dates from tbl_Return_Rank
while exists (select idx from @tbl_Final where idx=@i)
	begin
	select @dt = dte from @tbl_Final where idx = @i

	insert @tbl_Selections
	select dt, tid, P.db_close, RR.strTicker, r1, r3, r6, r12, vix,  RR.rRank,
	ROW_NUMBER() over(order by r1 ) ,0,0,0,0,0
	from tbl_Return_Rank RR, tbl_Prices P
	where RR.dt = @dt
	and P.db_dt = @dt
	and P.db_ticker_id = RR.tid
	and RR.strTicker in (select ticker from @tbl)
	and RR.dt = P.db_dt

	update @tbl_Selections
	set r3R = aRank
	from (select dt as aDT, tid as aTID, ROW_NUMBER() over(order by r3  ) as aRank
		from tbl_Return_Rank RR
		where RR.dt = @dt
		and RR.strTicker in (select ticker from @tbl) ) as A
	where dte = aDT
	and tid = aTID

	update @tbl_Selections
	set r6R = aRank
	from (select dt as aDT, tid as aTID, ROW_NUMBER() over(order by r6   ) as aRank
		from tbl_Return_Rank RR
		where RR.dt = @dt
		and RR.strTicker in (select ticker from @tbl) ) as A
	where dte = aDT
	and tid = aTID

	update @tbl_Selections
	set r12R = aRank
	from (select dt as aDT, tid as aTID, ROW_NUMBER() over(order by  r12  ) as aRank
		from tbl_Return_Rank RR
		where RR.dt = @dt
		and RR.strTicker in (select ticker from @tbl) ) as A
	where dte = aDT
	and tid = aTID

	update @tbl_Selections
	set rVIX = aRank
	from (select dt as aDT, tid as aTID, ROW_NUMBER() over(order by vix ) as aRank
		from tbl_Return_Rank RR
		where RR.dt = @dt
		and RR.strTicker in (select ticker from @tbl) ) as A
	where dte = aDT
	and tid = aTID

	-- set the Rank
	if @bIndivRank=1
		update @tbl_Selections
		set rR = r1R+r3R+r6R+r12R
		--set rR = ceiling(.5*r1R+.3*r3R+.15*r6R+.05*r12R)
	else
		update @tbl_Selections
		set rR = rRank

	-- set rank to zero if slope is negative
	update @tbl_Selections
	set rR = 0
	from (
		select db_ticker_id as aTID, db_dt as aDT, db_slope as aSLOPE from tbl_Return_Rank RR, tbl_Prices P where P.db_dt=@dt and RR.tid=P.db_ticker_id and RR.dt = P.db_dt and P.db_dt > '12-30-2006' and P.db_type=2) as A
	where dte = aDT
	and tid = aTID
	and dte = @dt
	and A.aSLOPE <= 0

	--select * from @tbl_Selections order by rR desc


	--iterate through pre-selected tickers
	set @j=1
	while exists ( select id from @tbl where id=@j)
	begin
		select @tick = ticker from @tbl where id=@j

		if @j = 1
			update @tbl_Final
			set S1= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		if @j = 2
			update @tbl_Final
			set S2= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		if @j = 3
			update @tbl_Final
			set S3= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		if @j = 4
			update @tbl_Final
			set S4 = Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		if @j =5
			update @tbl_Final
			set S5= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		if @j = 6
			update @tbl_Final
			set S6= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		if @j = 7
			update @tbl_Final
			set S7= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		if @j = 8
			update @tbl_Final
			set S8= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		if @j = 9
			update @tbl_Final
			set S9= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		if @j = 10
			update @tbl_Final
			set S10= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		if @j = 11
			update @tbl_Final
			set S11= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 
	
		if @j = 12
			update @tbl_Final
			set S12= Val
			from (
				select dte as adte, rR as VAL from @tbl_Selections where tick=@tick and dte = @dt
				) as A
			where dte = adte 

		set @j = @j+1
	end
	set @i=@i+1
end

select * from @tbl_Final

-- delete the row added to tbl_Return_Rank
--declare @Curr_dt datetime
--select @Curr_dt = max(db_dt)
--from IDToDSN_DKC.dbo.tbl_Prices
--where db_ticker_id = 538
--delete from tbl_Return_Rank where dt = @Curr_dt
