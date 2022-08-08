-- Select 100 records from each table to understand the data/variables
select * from application limit 100;

-- Explore and process Application data:
select amt_credit, count(*)
from application
group by 1;

select target, count(*)
from application
group by 1;

select NAME_CONTRACT_TYPE, count(*)
from application
group by 1;

-- Create the following new columns and think about whether it makes sense:
SELECT 
AMT_CREDIT/AMT_GOODS_PRICE as NEW_CREDIT_TO_GOODS_RATIO,
OWN_CAR_AGE/DAYS_BIRTH as NEW_CAR_TO_BIRTH_RATIO,
AMT_CREDIT/AMT_INCOME_TOTAL as NEW_CREDIT_TO_INCOME_RATIO
from application;

-- Use describe table to understand each column’s format
select * from bureau limit 100;
describe bureau;

-- Use sk_id_curr=215354 as an example to collect the following columns:
select CREDIT_ACTIVE, CREDIT_TYPE
FROM bureau
where SK_ID_CURR = 215354;

-- DATA TOO HUGE
-- check out how many distinct SK_ID_CURR group by different credit status. (CREDIT_ACTIVE) and different CREDIT_TYPE
select count(SK_ID_CURR) AS lOAN_ID, CREDIT_ACTIVE, CREDIT_TYPE
FROM bureau
where SK_ID_CURR = 215354
group by 2, 3;

-- Do aggregation calculations for columns by SK_ID_CURR by different CREDIT_ACTIVE each as below:
-- DAYS_CREDIT : [ min , max , avg ] /* let’s pick one variable days_credit first*/
-- CREDIT_DAY_OVERDUE : [ max , avg ]
SELECT AVG(days_credit), AVG(CREDIT_DAY_OVERDUE), SK_ID_CURR, CREDIT_ACTIVE
from bureau
group by 3, 4;

-- Data Flatten
-- each SK_ID_CURR has multiple records based on different values of CREDIT_ACTIVE
select SK_ID_CURR, 
		MIN(case when CREDIT_ACTIVE = 'Closed' then DAYS_CREDIT else 0 END) as closed_min_days,
		MIN(case when CREDIT_ACTIVE = 'Active' then DAYS_CREDIT else 0 END) as active_min_days,
        MIN(case when CREDIT_ACTIVE = 'Sold' then DAYS_CREDIT else 0 END) as sold_min_days,
        MIN(case when CREDIT_ACTIVE = 'Bad Debt' then DAYS_CREDIT else 0 END) as baddebt_min_days,
        MAX(CREDIT_DAY_OVERDUE) as longest_overdue
from bureau
group by SK_ID_CURR;

-- create additional 2 columns – whether the customer has bad debt before (bd_flag = 1 or 0), how many previous bad debts the customer has (bd_num)
SELECT SK_ID_CURR,
		max((case when CREDIT_ACTIVE = 'Bad Debt' then 1 else 0 END)) as bd_flag,  
-- as long as there is a bad debt, it returns 1
		sum((case when CREDIT_ACTIVE = 'Bad Debt' then 1 else 0 END)) as bd_num
from bureau
group by SK_ID_CURR
order by bd_num desc;

-- Explore and process Bureau balance data:
-- Check distinct status
select *
from bureau_balance -- credit product level, by month
where SK_ID_BUREAU = 5715448;

select *
from bureau
where sk_bureau_id = 5715448;

select *
from bureau
where sk_id_curr = 380361; -- applicant level, by product

-- Create new columns
-- average chance (%) of delingquency of that product, for each delingquency level
SELECT SK_ID_BUREAU,
		AVG(CASE WHEN status = '0' THEN 1 ELSE 0 END) AS status_0_mean,
        AVG(CASE WHEN status = '1' THEN 1 ELSE 0 END) AS status_1_mean,
        AVG(CASE WHEN status = '2' THEN 1 ELSE 0 END) AS status_2_mean,
        AVG(CASE WHEN status = '3' THEN 1 ELSE 0 END) AS status_3_mean,
        AVG(CASE WHEN status = '4' THEN 1 ELSE 0 END) AS status_4_mean,
        AVG(CASE WHEN status = '5' THEN 1 ELSE 0 END) AS status_5_mean,
        AVG(CASE WHEN status = 'x' THEN 1 ELSE 0 END) AS status_x_mean
from bureau_balance
group by 1;  -- group by product level

-- Find the corresponding SK_ID_CURR in Application table for each SK_ID_BUREAU. I need Bureau table as an intermedium table to complete the job
-- Be careful! One SK_ID_CURR may have multiple SK_ID_BUREAU, but in the end, you may want to generate the result which has one record per SK_ID_CURR and the mean of each status for each SK_ID_CURR
-- making 16 into applicant level -- using bureau table as an intermedium table
select a.sk_id_curr as SK_ID,
		AVG(CASE WHEN temp.status = '0' THEN 1 ELSE 0 END) AS status_0_mean,
        AVG(CASE WHEN temp.status = '1' THEN 1 ELSE 0 END) AS status_1_mean,
        AVG(CASE WHEN temp.status = '2' THEN 1 ELSE 0 END) AS status_2_mean,
        AVG(CASE WHEN temp.status = '3' THEN 1 ELSE 0 END) AS status_3_mean,
        AVG(CASE WHEN temp.status = '4' THEN 1 ELSE 0 END) AS status_4_mean,
        AVG(CASE WHEN temp.status = '5' THEN 1 ELSE 0 END) AS status_5_mean,
        AVG(CASE WHEN temp.status = 'x' THEN 1 ELSE 0 END) AS status_x_mean
from application as a
left join bureau as b on a.SK_ID_CURR = b.SK_ID_CURR
left join bureau_balance as c on b.SK_BUREAU_ID = c.SK_ID_BUREAU
group by 1;

-- Explore and process Previous application data
-- Check whether one SK_ID_CURR may have multiple SK_ID_PREV => this will affect the join results
select *
from previous_application;

select sk_id_curr, count(distinct sk_id_prev)
from previous_application
group by 1;

-- Create a new column APP_CREDIT_PERC = AMT_APPLICATION / AMT_CREDIT for approved decisions: value ask / value received percentage
select *, (AMT_APPLICATION / AMT_CREDIT) *100 as APP_CREDIT_PERC
from previous_application;

-- Check distinct NAME_CONTRACT_STATUS
select distinct NAME_CONTRACT_STATUS
FROM previous_application;

-- and then add 2 new columns for each SK_ID_CURR: Num_of_app (the number of total approved previous applications; Think about how to deal with ‘Unused offer’ status
-- Num_of_ref
SELECT SK_ID_CURR,
		SUM(CASE WHEN NAME_CONTRACT_STATUS IN ('Approved', 'Unused offer') then 1 else 0 end) as num_of_app,
        SUM(CASE WHEN NAME_CONTRACT_STATUS IN ('Refused') then 1 else 0 end) as num_of_ref,
        AVG(CASE WHEN NAME_CONTRACT_STATUS IN ('Approved') THEN (AMT_APPLICATION/AMT_CREDIT)*100 ELSE NULL END) as AVG_APP_CREDIT_PERC
from previous_application
group by 1;

-- For approved and used accounts, calculate the average of APP_CREDIT_PERC (avg_APP_CREDIT_PERC) and aggerate to one record per SK_ID_CURR
select SK_ID_CURR, AVG((AMT_APPLICATION / AMT_CREDIT) *100) as AVG_APP_CREDIT_PERC 
FROM previous_application
WHERE NAME_CONTRACT_STATUS = 'Approved'
GROUP BY 1;

-- Join Application table with Bureau table, Bureau Balance, and Previous Application together with all new added columns
select
base.*,
base2.status_c_mean,
base2.status_x_mean,
base2.status_0_mean,
base2.status_1_mean,
base2.status_2_mean,
base2.status_3_mean,
base2.status_4_mean,
base2.status_5_mean,
base3.num_of_app,
base3.num_of_ref,
base3.avg_APP_CREDIT_PERC
from
(select a.*, 
AMT_CREDIT/AMT_ANNUITY as NEW_CREDIT_TO_ANNUITY_RATIO,
AMT_CREDIT/AMT_GOODS_PRICE as NEW_CREDIT_TO_GOODS_RATIO,
OWN_CAR_AGE/DAYS_BIRTH as NEW_CAR_TO_BIRTH_RATIO,
OWN_CAR_AGE/DAYS_EMPLOYED as NEW_CAR_TO_EMPLOY_RATIO,
AMT_CREDIT/AMT_INCOME_TOTAL as NEW_CREDIT_TO_INCOME_RATIO, -- one of the most important variable! DTI
AMT_ANNUITY/AMT_INCOME_TOTAL as NEW_ANNUITY_TO_INCOME_RATIO,
c.cl_max_DAYS_CREDIT,
c.cl_min_DAYS_CREDIT,
c.cl_avg_DAYS_CREDIT,
c.ac_max_DAYS_CREDIT,
c.ac_min_DAYS_CREDIT,
c.ac_avg_DAYS_CREDIT,
c.sd_max_DAYS_CREDIT,
c.sd_min_DAYS_CREDIT,
c.sd_avg_DAYS_CREDIT,
c.bd_max_DAYS_CREDIT,
c.bd_min_DAYS_CREDIT,
c.bd_avg_DAYS_CREDIT,
c.cl_max_CREDIT_DAY_OVERDUE,
c.ac_max_CREDIT_DAY_OVERDUE,
c.sd_max_CREDIT_DAY_OVERDUE,
c.bd_max_CREDIT_DAY_OVERDUE,
c.cl_avg_CREDIT_DAY_OVERDUE,
c.ac_avg_CREDIT_DAY_OVERDUE,
c.sd_avg_CREDIT_DAY_OVERDUE,
c.bd_avg_CREDIT_DAY_OVERDUE,
c.bd_flag,
c.bd_num
from
application as a
left join 
(
select SK_ID_CURR,
max(case when CREDIT_ACTIVE='Closed' then DAYS_CREDIT else null end) as cl_max_DAYS_CREDIT,
min(case when CREDIT_ACTIVE='Closed' then DAYS_CREDIT else null end) as cl_min_DAYS_CREDIT,
avg(case when CREDIT_ACTIVE='Closed' then DAYS_CREDIT else null end) as cl_avg_DAYS_CREDIT,
max(case when CREDIT_ACTIVE='Active' then DAYS_CREDIT else null end) as ac_max_DAYS_CREDIT,
min(case when CREDIT_ACTIVE='Active' then DAYS_CREDIT else null end) as ac_min_DAYS_CREDIT,
avg(case when CREDIT_ACTIVE='Active' then DAYS_CREDIT else null end) as ac_avg_DAYS_CREDIT,
max(case when CREDIT_ACTIVE='Sold' then DAYS_CREDIT else null end) as sd_max_DAYS_CREDIT,
min(case when CREDIT_ACTIVE='Sold' then DAYS_CREDIT else null end) as sd_min_DAYS_CREDIT,
avg(case when CREDIT_ACTIVE='Sold' then DAYS_CREDIT else null end) as sd_avg_DAYS_CREDIT,
max(case when CREDIT_ACTIVE ='Bad Debt' then DAYS_CREDIT else null end) as bd_max_DAYS_CREDIT,
min(case when CREDIT_ACTIVE='Bad Debt' then DAYS_CREDIT else null end) as bd_min_DAYS_CREDIT,
avg(case when CREDIT_ACTIVE='Bad Debt' then DAYS_CREDIT else null end) as bd_avg_DAYS_CREDIT,

max(case when CREDIT_ACTIVE='Closed' then DAYS_CREDIT_ENDDATE else null end) as cl_max_DAYS_CREDIT_ENDDATE,
min(case when CREDIT_ACTIVE='Closed' then DAYS_CREDIT_ENDDATE else null end) as cl_min_DAYS_CREDIT_ENDDATE,
avg(case when CREDIT_ACTIVE='Closed' then DAYS_CREDIT_ENDDATE else null end) as cl_avg_DAYS_CREDIT_ENDDATE,
max(case when CREDIT_ACTIVE='Active' then DAYS_CREDIT_ENDDATE else null end) as ac_max_DAYS_CREDIT_ENDDATE,
min(case when CREDIT_ACTIVE='Active' then DAYS_CREDIT_ENDDATE else null end) as ac_min_DAYS_CREDIT_ENDDATE,
avg(case when CREDIT_ACTIVE='Active' then DAYS_CREDIT_ENDDATE else null end) as ac_avg_DAYS_CREDIT_ENDDATE,
max(case when CREDIT_ACTIVE='Sold' then DAYS_CREDIT_ENDDATE else null end) as sd_max_DAYS_CREDIT_ENDDATE,
min(case when CREDIT_ACTIVE='Sold' then DAYS_CREDIT_ENDDATE else null end) as sd_min_DAYS_CREDIT_ENDDATE,
avg(case when CREDIT_ACTIVE='Sold' then DAYS_CREDIT_ENDDATE else null end) as sd_avg_DAYS_CREDIT_ENDDATE,
max(case when CREDIT_ACTIVE ='Bad Debt' then DAYS_CREDIT_ENDDATE else null end) as bd_max_DAYS_CREDIT_ENDDATE,
min(case when CREDIT_ACTIVE='Bad Debt' then DAYS_CREDIT_ENDDATE else null end) as bd_min_DAYS_CREDIT_ENDDATE,
avg(case when CREDIT_ACTIVE='Bad Debt' then DAYS_CREDIT_ENDDATE else null end) as bd_avg_DAYS_CREDIT_ENDDATE,

max(case when CREDIT_ACTIVE='Closed' then CREDIT_DAY_OVERDUE else null end) as cl_max_CREDIT_DAY_OVERDUE,
max(case when CREDIT_ACTIVE='Active' then CREDIT_DAY_OVERDUE else null end) as ac_max_CREDIT_DAY_OVERDUE,
max(case when CREDIT_ACTIVE='Sold' then CREDIT_DAY_OVERDUE else null end) as sd_max_CREDIT_DAY_OVERDUE,
max(case when CREDIT_ACTIVE ='Bad Debt' then CREDIT_DAY_OVERDUE else null end) as bd_max_CREDIT_DAY_OVERDUE,
avg(case when CREDIT_ACTIVE='Closed' then CREDIT_DAY_OVERDUE else null end) as cl_avg_CREDIT_DAY_OVERDUE,
avg(case when CREDIT_ACTIVE='Active' then CREDIT_DAY_OVERDUE else null end) as ac_avg_CREDIT_DAY_OVERDUE,
avg(case when CREDIT_ACTIVE='Sold' then CREDIT_DAY_OVERDUE else null end) as sd_avg_CREDIT_DAY_OVERDUE,
avg(case when CREDIT_ACTIVE='Bad Debt' then CREDIT_DAY_OVERDUE else null end) as bd_avg_CREDIT_DAY_OVERDUE,
max(case when  CREDIT_ACTIVE='Bad Debt'  then 1 else 0 end) as bd_flag, 
sum(case when  CREDIT_ACTIVE='Bad Debt'  then 1 else 0 end) as bd_num
from bureau
group by 1) as c
on a.SK_ID_CURR=c.SK_ID_CURR) as base
left join
(select a.SK_ID_CURR,
avg(case when status = 'C' then 1 else 0 end) as status_c_mean,
avg(case when status = 'X' then 1 else 0 end) as status_x_mean,
avg(case when status = '0' then 1 else 0 end) as status_0_mean,
avg(case when status = '1' then 1 else 0 end) as status_1_mean,
avg(case when status = '2' then 1 else 0 end) as status_2_mean,
avg(case when status = '3' then 1 else 0 end) as status_3_mean,
avg(case when status = '4' then 1 else 0 end) as status_4_mean,
avg(case when status = '5' then 1 else 0 end) as status_5_mean
from application as a
join bureau as b
on a.SK_ID_CURR=b.SK_ID_CURR
join bureau_balance as c
on b.SK_BUREAU_id=c.sk_id_bureau
group by 1) as base2 
on base.SK_ID_CURR=base2.SK_ID_CURR
left join
(select SK_ID_CURR,
sum(case when NAME_CONTRACT_STATUS in ('Approved','Unused offer') then 1 else 0 end) as num_of_app,
sum(case when NAME_CONTRACT_STATUS in ('Refused') then 1 else 0 end) as num_of_ref,
avg(case when NAME_CONTRACT_STATUS in ('Approved') then AMT_APPLICATION / AMT_CREDIT else null/*why use null?*/ end) as avg_APP_CREDIT_PERC
from previous_application group by 1) base3
on base.SK_ID_CURR=base3.SK_ID_CURR;

