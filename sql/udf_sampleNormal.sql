USE [IDToDSN_DKC]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_sampleNormal]    Script Date: 08/08/2013 14:38:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[udf_sampleNormal](@u real, @v real)
returns @tbl table (x real, y real)
as
begin
    declare @r real
    
    --set @u = rand(DATEPART(ms,getdate()))
    --print 'u'
    --print @u
    --set @v = rand()
    --print 'v'
    --print @v
    
    declare @x real, @y real
    set @x = SQRT(-2 * log(@u)) * COS(2 * pi() * @v)
    set @y = SQRT(-2 * log(@u)) * sin(2 * pi() * @v)
    --print 'x'
    --print @x
    --print 'y'
    --print @y
    
    insert @tbl
    select @x, @y
	return
end