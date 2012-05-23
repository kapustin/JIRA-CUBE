select	sch.min_worktime/60.0 * CASE WHEN (day_type='Ð' and schedule_type_id=1) or (schedule_type_id=2 and datediff(day,sch.ddateb,sch.ddate)%4<=1) THEN 1 
									ELSE 0 
									END timetabled_wh
		,CASE WHEN datediff(minute,t2.ddate,t2.ddatetime)>=time_start then t2.ddatetime else dateadd(minute,time_start,convert(datetime,t2.ddate)) END
		,CASE WHEN datediff(minute,t1.ddate,t1.ddatetime)<=time_end then t1.ddatetime else dateadd(minute,time_end,convert(datetime,t1.ddate)) END
		,
				DATEDIFF(minute
							,CASE WHEN datediff(minute,t2.ddate,t2.ddatetime)>=time_start then t2.ddatetime else dateadd(minute,time_start,convert(datetime,t2.ddate)) END
							,CASE WHEN datediff(minute,t1.ddate,t1.ddatetime)<=time_end then t1.ddatetime else dateadd(minute,time_end,convert(datetime,t1.ddate)) END
						)

			,*
from (select ROW_NUMBER() OVER(PARTITION BY d.ddate,s.person_id ORDER BY s.priority DESC) rn
			,d.ddate
			,ddateb
			,day_type
			,person_id as tabnum
			,schedule_type_id
			,time_start
			,time_end
			,min_worktime
		from ddate d 
		join emp_schedule s on d.ddate between s.ddateb and isnull(s.ddatee,'9999-12-31')) sch
	left outer JOIN
	(SELECT ROW_NUMBER() OVER(PARTITION BY code,ddate ORDER BY ddatetime DESC) AS num, code,ddate, ddatetime
		FROM entrance) t1 on t1.code-200000=sch.tabnum and t1.ddate=sch.ddate and t1.num%2<>0
	left outer JOIN 
	(SELECT ROW_NUMBER() OVER(PARTITION BY code,ddate ORDER BY ddatetime DESC) AS num, code,ddate, ddatetime
		FROM entrance) t2 ON t1.num=t2.num-1 AND t1.ddate=t2.ddate AND t1.code=t2.code
where rn=1 and tabnum=5719
order by sch.ddate,sch.tabnum,t1.ddatetime