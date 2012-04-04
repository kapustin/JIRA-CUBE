IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PopulateDates]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PopulateDates]
GO
CREATE PROCEDURE [dbo].[PopulateDates]
AS
BEGIN
SET NOCOUNT ON -- turn off all the 1 row inserted messages

-- Hold our dates
DECLARE @BeginDate DATETIME
DECLARE @EndDate DATETIME

-- Holds a flag so we can determine if the date is the last day of month
DECLARE @LastDayOfMon CHAR(1)

-- Number of months to add to the date to get the current Fiscal date
DECLARE @FiscalYearMonthsOffset INT   

-- These two counters are used in our loop.
DECLARE @DateCounter DATETIME    --Current date in loop
DECLARE @FiscalCounter DATETIME  --Fiscal Year Date in loop

-- Set the date to start populating and end populating
SET @BeginDate = '2006-01-01'
SET @EndDate = '2012-12-31' 

-- Start the counter at the begin date
SET @DateCounter = @BeginDate


IF not exists(select * from [dbo].[dimDate] where [DateKey]=-1)
            INSERT  INTO [dbo].[dimDate]
                    (
                      [DateKey]
                    , [DateName]
                    , [DayNameOfWeek]
                    , [WeekdayWeekend]
                    , [MonthName]
                    , [CalendarYearMonth]
                    , [CalendarYearQtr]
                    )
            VALUES  (-1,'N/A','N/A','N/A','N/A','N/A','N/A')


WHILE @DateCounter <= @EndDate
      BEGIN

            -- Set value for IsLastDayOfMonth
            IF MONTH(@DateCounter) = MONTH(DATEADD(d, 1, @DateCounter))
               SET @LastDayOfMon = 'N'
            ELSE
               SET @LastDayOfMon = 'Y'  

            -- add a record into the date dimension table for this date
            INSERT  INTO [dbo].[dimDate]
                    (
                      [DateKey]
                    , [FullDate]
                    , [DateName]
                    , [DayOfWeek]
                    , [DayNameOfWeek]
                    , [DayOfMonth]
                    , [DayOfYear]
                    , [WeekdayWeekend]
                    , [WeekOfYear]
                    , [MonthName]
                    , [MonthOfYear]
                    , [IsLastDayOfMonth]
                    , [CalendarQuarter]
                    , [CalendarYear]
                    , [CalendarYearMonth]
                    , [CalendarYearQtr]
                    )
            VALUES  (
                      ( YEAR(@DateCounter) * 10000 ) + ( MONTH(@DateCounter)
                                                         * 100 )
                      + DAY(@DateCounter)  --DateKey
                    , @DateCounter -- FullDate
                    , RIGHT('00' + RTRIM(CAST(DATEPART(dd, @DateCounter) AS CHAR(2))), 2) + '/' 
                      + RIGHT('00' + RTRIM(CAST(DATEPART(mm, @DateCounter) AS CHAR(2))), 2) + '/'
                      + CAST(YEAR(@DateCounter) AS CHAR(4)) --DateName
                    , DATEPART(dw, @DateCounter) --DayOfWeek
                    , DATENAME(dw, @DateCounter) --DayNameOfWeek
                    , DATENAME(dd, @DateCounter) --DayOfMonth
                    , DATENAME(dy, @DateCounter) --DayOfYear
                    , CASE DATENAME(dw, @DateCounter)
                        WHEN 'Saturday' THEN 'Weekend'
                        WHEN 'Sunday' THEN 'Weekend'
                        ELSE 'Weekday'
                      END --WeekdayWeekend
                    , DATENAME(ww, @DateCounter) --WeekOfYear
                    , DATENAME(mm, @DateCounter) --MonthName
                    , MONTH(@DateCounter) --MonthOfYear
                    , @LastDayOfMon --IsLastDayOfMonth
                    , DATENAME(qq, @DateCounter) --CalendarQuarter
                    , YEAR(@DateCounter) --CalendarYear
                    , CAST(YEAR(@DateCounter) AS CHAR(4)) + '-'
                      + RIGHT('00' + RTRIM(CAST(DATEPART(mm, @DateCounter) AS CHAR(2))), 2) --CalendarYearMonth
                    , CAST(YEAR(@DateCounter) AS CHAR(4)) + 'Q' + DATENAME(qq, @DateCounter) --CalendarYearQtr
                    )

            -- Increment the date counter for next pass thru the loop
            SET @DateCounter = DATEADD(d, 1, @DateCounter)
      END

SET NOCOUNT ON -- turn the annoying messages back on
END
GO

