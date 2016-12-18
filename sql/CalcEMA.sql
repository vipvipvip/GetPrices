alter procedure [dbo].[csp_Calc_EMA]
(
	@s_date datetime,
	@tid int
)
as

	IF OBJECT_ID('tempdb..#TBL_EMA25_RT') IS NOT NULL BEGIN
		DROP TABLE #TBL_EMA25_RT
	END

	declare @tblA table (QuoteId int identity, StockID int, QuoteDay datetime, QuoteClose dec(9,3) )

	insert @tblA
	select db_ticker_id, db_dt, db_close
	from tbl_Prices
	where db_ticker_id = @tid
	and db_dt >= @s_date
	order by db_dt

	SELECT *, CAST(NULL AS FLOAT) AS EMA25 INTO #TBL_EMA25_RT FROM @tblA

	CREATE UNIQUE CLUSTERED INDEX EMA25_IDX_RT ON #TBL_EMA25_RT (StockId, QuoteId)

	IF OBJECT_ID('tempdb..#TBL_START_AVG') IS NOT NULL 
	BEGIN
		DROP TABLE #TBL_START_AVG
	END

	SELECT StockId, AVG(QuoteClose) AS Start_Avg INTO #TBL_START_AVG FROM @tblA WHERE QuoteId <= 25 GROUP BY StockId

	DECLARE @C FLOAT = 2.0 / (1 + 25), @EMA25 FLOAT

	UPDATE
		T1
	SET
		@EMA25 =
			CASE
				WHEN QuoteId = 25 then T2.Start_Avg
				WHEN QuoteId > 25 then T1.QuoteClose * @C + @EMA25 * (1 - @C)
			END
		,EMA25 = @EMA25 
	FROM
		#TBL_EMA25_RT T1
	JOIN
		#TBL_START_AVG T2
	ON
		T1.StockId = T2.StockId
	OPTION (MAXDOP 1)
	print 'updating prices'
	update tbl_Prices
	set db_EMA25 = A.EMA25
	from (
	SELECT StockId STKID, QuoteId, QuoteDay as DT, QuoteClose, CAST(EMA25 AS NUMERIC(10,2)) AS EMA25 FROM #TBL_EMA25_RT where StockID = @tid
	) as A
	where db_ticker_id = STKID
	and db_dt = A.DT

	print 'updated ' + convert(varchar, @@ROWCOUNT) + ' rows for ticker ' + convert(varchar, @tid)
