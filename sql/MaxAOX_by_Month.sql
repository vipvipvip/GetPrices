declare @tbl_Dates table (idx int identity, dte datetime )

declare @tbl_Selections table (idx int identity, dte datetime, tid int, rR3 dec(9,3), price dec(9,3)
		,tick varchar(10), ePrice dec(9,3), rR int )

insert @tbl_Dates
select distinct(dt)
from tbl_Return_Rank
where dt > '12-29-2006'
order by dt asc

declare @t_dt datetime
declare @e_dt datetime
declare @id int
set @id=1
while exists (select * from @tbl_Dates where idx = @id)
  begin
	select @t_dt= dte from @tbl_Dates where idx = @id
		insert @tbl_Selections
		select top 1 @t_dt, tid, r3, price, strTicker,0, rRank
		from tbl_Return_Rank
		where dt = @t_dt
		--and price is not null
		--and r3 is not null and r3 > 0
		--and strTicker in ('VTI','VNQ','ONEQ','VEU','EEM','TIP','LQD','EMB','HYG','GLD','TLT','AGG')
		--and strTicker in ('VTI', 'VEU', 'VNQ')
		--and strTicker in ('IVV', 'VO', 'VB', 'VNQ')
		--and strTicker in ('RSP')
		and strTicker in ('AOA',	'AOR',	'AOM',	'AOK')
		--and strTicker in ('VCR', 'VDC', 'VDE', 'VFH', 'VHT', 'VIS', 'VAW', 'VGT', 'VPU', 'VNQ')
		order by r3 desc


		if @@ROWCOUNT < 1
		insert @tbl_Selections			
		select top 1 dt, tid, r3, price, strTicker,0, rRank
		from tbl_Return_Rank
		where dt = @t_dt
		--and (r3 is null or r3 < 0)
		--and strTicker in ('VTI','VNQ','ONEQ','VEU','EEM','TIP','LQD','EMB','HYG','GLD','TLT', 'AGG')
		--and strTicker in ('VTI', 'VEU', 'VNQ')
		--and strTicker in ('IVV', 'VO', 'VB', 'VNQ')
		--and strTicker in ('RSP')
		--and strTicker in ('VCR', 'VDC', 'VDE', 'VFH', 'VHT', 'VIS', 'VAW', 'VGT', 'VPU', 'VNQ')
		and strTicker in ('AOA',	'AOR',	'AOM',	'AOK')
		and strTicker not in (select tick from @tbl_Selections where dte = @t_dt)

	set @id= @id+1
	
	--get the month end price
	select @e_dt= dte from @tbl_Dates where idx = @id
	print '-----'
	print @t_dt
	print @e_dt
	print '-----'
	update @tbl_Selections
	set ePrice=A.PRICE
	from (select db_ticker_id, db_close as PRICE, db_dt as DT 
			from tbl_Prices
			where db_dt = @e_dt
			and db_close is not null
			and db_ticker_id in (
					select db_ticker_id 
					from tbl_Ticker 
					--where db_strTicker in ('VCR', 'VDC', 'VDE', 'VFH', 'VHT', 'VIS', 'VAW', 'VGT', 'VPU', 'VNQ') 
					where db_strTicker in ('AOA',	'AOR',	'AOM',	'AOK')
				)
		  ) as A
	where dte= @t_dt
	and tid = A.db_ticker_id
	
  end

update @tbl_Selections
set tick = A.TICK
from (select tid As iTID, strTicker as TICK from tbl_Return_Rank) as A
where tid = A.iTID


select convert(char(2),month(dte)) + '-' + convert(char(2),day(dte)) + '-' + convert(char(4),year(dte)) as dte, 
--coalesce([VTI],0) as [VTI],coalesce([VNQ],0) as [VNQ],coalesce([ONEQ],0) as [ONEQ],coalesce([VEU],0) as [VEU],coalesce([EEM],0) as [EEM],coalesce([TIP],0) as [TIP],coalesce([LQD],0) as [LQD],coalesce([EMB],0) as [EMB],coalesce([HYG],0) as [HYG],coalesce([GLD],0) as [GLD],coalesce([TLT],0) as [TLT],coalesce([AGG],0) as [AGG], 'ALL' as DataSet
--coalesce([VTI],0) as [VTI],	coalesce([VEU],0) as [VEU],	coalesce([VNQ],0) as [VNQ], 'TDA' as DataSet
--coalesce([IVV],0) as [IVV],	coalesce([VO],0) as [VO],	coalesce([VB],0) as [VB], coalesce([VNQ],0) as [VNQ], 'TDA_CAP' as DataSet
--coalesce([RSP],0) as [RSP], 'TIA' as DataSet
--coalesce([VCR],0) as [VCR], coalesce([VDC],0) as [VDC], coalesce([VDE],0) as [VDE], coalesce([VFH],0) as [VFH], coalesce([VHT],0) as [VHT], coalesce([VIS],0) as [VIS], coalesce([VAW],0) as [VAW], coalesce([VGT],0) as [VGT], coalesce([VPU],0) as [VPU], coalesce([VNQ],0) as [VNQ]
coalesce([AOA],0) as [AOA],	coalesce([AOR],0) as [AOR],	coalesce([AOM],0) as [AOM],	coalesce([AOK],0) as [AOK], 'AOX' as DataSet
,Price, ePrice, tid, 'AOX' as DataSet
from (
select dte, tick, coalesce(rR, 0) as rR, price, ePrice, tid
from @tbl_Selections
) as Src
PIVOT
(	sum(Src.rR)
	--FOR Src.tick in ([VTI],[VNQ],[ONEQ],[VEU],[EEM],[TIP],[LQD],[EMB],[HYG],[GLD],[TLT], [AGG])
	--FOR Src.tick in ([VTI], [VEU], [VNQ])
	--FOR Src.tick in ([IVV], [VO], [VB], [VNQ])
	--FOR Src.tick in ([RSP])
	--FOR Src.tick in ([VCR], [VDC], [VDE], [VFH], [VHT], [VIS], [VAW], [VGT], [VPU], [VNQ])
	FOR Src.tick in ([AOA],[AOR], [AOM], [AOK])
) as Pvt
