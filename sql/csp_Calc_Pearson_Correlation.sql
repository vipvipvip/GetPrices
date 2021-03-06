USE [IDToDSN_DKC]
GO
/****** Object:  StoredProcedure [dbo].[csp_Calc_Pearson_Correlation]    Script Date: 08/25/2013 13:42:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[csp_Calc_Pearson_Correlation]
(
      @tv TBL_CORRELATION READONLY
)
AS

/*
--Src = http://www.mathsisfun.com/data/correlation.html
--CREATE TYPE TBL_CORRELATION AS TABLE
-- (                     
--	Col_A dec(9,2),
--	Col_B dec(9,2)
-- )

declare @tbl dbo.TBL_CORRELATION
insert @tbl select 14.2, 215
insert @tbl select 16.4, 325
insert @tbl select 11.9, 185
insert @tbl select 15.2, 332
insert @tbl select 18.5, 406
insert @tbl select 22.1, 522
insert @tbl select 19.4, 412
insert @tbl select 25.1, 614
insert @tbl select 23.4, 544
insert @tbl select 18.1, 421
insert @tbl select 22.6, 445
insert @tbl select 17.2, 408


exec csp_Calc_Pearson_Correlation @tbl

*/
BEGIN
declare @tbl table (col_A dec(9,2), col_B dec(9,2), Diff_A dec(9,2), Diff_B dec(9,2), AB dec(9,2), Asq dec(9,2), Bsq dec(9,2) )
declare @colA_Mean dec(9,2)
declare @colB_Mean dec(9,2)

insert @tbl
select *, 0, 0, 0, 0, 0 from @tv

select @colA_Mean = AVG(col_A), @colB_Mean = AVG(Col_B) from @tv

update @tbl
set Diff_A = col_A - @colA_Mean,
	Diff_B = col_B - @colB_Mean
	
update @tbl
set AB		= Diff_A * Diff_B,
	Asq		= Diff_A * Diff_A,
	Bsq		= Diff_B * Diff_B

declare @sum_AB dec(19,2), @sum_Asq dec(19,2), @sum_Bsq dec(19,2)
select @sum_AB = sum(AB), @sum_Asq = sum(Asq), @sum_Bsq = sum(Bsq) from @tbl

select convert(dec(9,4), @sum_AB / (sqrt(@sum_Asq * @sum_Bsq))) as Correlation

END
