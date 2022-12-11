/*
Entity: user posting questions and anawers
Activity: posting questions, editing them, posting answers, getting answers etc.
 
Acivity Schema:
---------------  
activity_id
ts
customer
activity
source
source_id
feature_1
feature_2
feature_3
revenue_impact
link
activity_occurrence
activity_repeated_at
_activity_source

Leessons:
--------
- You need to ensure that customer+activity+timestamp is unique in the entire table
- If cocnurrent activities have the same timestamp you need to add a second artifically to next one
- Unless you use Narrator, you'll need a separate dimensional table mapping activity to the name of the dimensions in feature_1, 2 and 3

 */

create or replace table `mythic-emissary-272811.my_data.stackoverflow_activity` as (

with post_history as (
	select
		ph.revision_guid,
        ph.user_id,
		u.display_name as user_name,
		case 
			when max(ph.post_history_type_id) in (1,2,3) then 'posted'
			when max(ph.post_history_type_id) in (4,5,6) then 'edited'
			when max(ph.post_history_type_id) in (7,8,9) then 'rolledback'
		end as activity,
		cast(null as string) as close_reason,
		max(ph.id) as activity_id,
        max(ph.post_id) as post_id,
        max(ph.creation_date) as creation_date
	from
		`bigquery-public-data.stackoverflow.post_history` ph
		join `bigquery-public-data.stackoverflow.users` u
     		on u.id = ph.user_id
	where
		ph.post_history_type_id between 1 and 9
	group by 1,2,3
	
	union all 
	
	select
		ph.revision_guid,
        ph.user_id,
		u.display_name as user_name,
		case
			when max(ph.post_history_type_id) in (10) then 'closed'
			when max(ph.post_history_type_id) in (11) then 'reopened'
			when max(ph.post_history_type_id) in (12) then 'deleted'
			when max(ph.post_history_type_id) in (13) then 'undeleted'
			when max(ph.post_history_type_id) in (14) then 'locked'
			when max(ph.post_history_type_id) in (15) then 'unlocked'
			when max(ph.post_history_type_id) in (16) then 'made_community_wiki'
			when max(ph.post_history_type_id) in (17) then 'migrated'
			when max(ph.post_history_type_id) in (18) then 'merged'
			when max(ph.post_history_type_id) in (19) then 'protected'
			when max(ph.post_history_type_id) in (20) then 'unprotected'
			when max(ph.post_history_type_id) in (22) then 'unmerged'
			when max(ph.post_history_type_id) in (24) then 'applied_edit_to'
			when max(ph.post_history_type_id) in (25) then 'tweeted'
			when max(ph.post_history_type_id) in (31) then 'moved_to_chat'
			when max(ph.post_history_type_id) in (33) then 'added_notice'
			when max(ph.post_history_type_id) in (34) then 'removed_notice'
			when max(ph.post_history_type_id) in (35) then 'migrated_away'
			when max(ph.post_history_type_id) in (36) then 'migrated_here'
			when max(ph.post_history_type_id) in (37) then 'merge_source'
			when max(ph.post_history_type_id) in (38) then 'merge_destination'
			when max(ph.post_history_type_id) in (50) then 'community_bump'
			when max(ph.post_history_type_id) in (52) then 'selected_hot'
			when max(ph.post_history_type_id) in (53) then 'removed_hot'
		end as activity,
		case 
			when max(ph.post_history_type_id) in (10) and max(comment) = '101' then 'duplicate'
			when max(ph.post_history_type_id) in (10) and max(comment) = '102' then 'off-topic'
			when max(ph.post_history_type_id) in (10) and max(comment) = '103' then 'unclear'
			when max(ph.post_history_type_id) in (10) and max(comment) = '104' then 'too_broad'
			when max(ph.post_history_type_id) in (10) and max(comment) = '105' then 'opinion_based'
		end as close_reason,
		max(ph.id) as activity_id,
        max(ph.post_id) as post_id,
		max(ph.creation_date) as creation_date
	from
		`bigquery-public-data.stackoverflow.post_history` ph
		join `bigquery-public-data.stackoverflow.users` u
     		on u.id = ph.user_id
	where
		ph.post_history_type_id > 9
	group by 1,2,3
)
select
	ph.activity_id  		as activity_id,
	ph.creation_date 		as ts,
	ph.user_name 			as customer,
	ph.activity 			as activity,
	'internal_db'			as source,
	ph.user_id				as source_id,
	'question'				as feature_1, --post_type
	ph.close_reason			as feature_2, --close_reason
	cast(null as string) 	as feature_3,
	0.0 					as revenue_impact,
	cast(null as string)    as link,
	cast(null as int64)	    as activity_occurrence,
	cast(null as timestamp) as activity_repeated_at,
	cast(null as string) 	as _activity_source
from
	`bigquery-public-data.stackoverflow.posts_questions` q
     join post_history ph on q.id = ph.post_id

union all

select
	ph.activity_id  		as activity_id,
	ph.creation_date 		as ts,
	ph.user_name 			as customer,
	ph.activity 			as activity,
	'internal_db'			as source,
	ph.user_id				as source_id,
	'answer'				as feature_1, --post_type
	ph.close_reason			as feature_2, --close_reason
	cast(null as string) 	as feature_3,
	0.0 					as revenue_impact,
	cast(null as string)    as link,
	cast(null as int64)	    as activity_occurrence,
	cast(null as timestamp) as activity_repeated_at,
	cast(null as string) 	as _activity_source
from
	`bigquery-public-data.stackoverflow.posts_answers` q
     join post_history ph on q.id = ph.post_id;


update `mythic-emissary-272811.my_data.stackoverflow_activity` a
set activity_occurrence = dt.activity_occurrence,
    activity_repeated_at = dt.activity_repeated_at
from (
    select
        activity_id,
        customer,
        activity,
        ts,
        row_number() over(partition by customer, activity order by ts asc) as activity_occurrence,
        lead(ts,1)   over(partition by customer, activity order by ts asc) as activity_repeated_at
    from 
        `mythic-emissary-272811.my_data.stackoverflow_activity`
)dt
where 
    dt.activity_id = a.activity_id
    and dt.customer = a.customer
    and dt.activity = a.activity
    and a.ts = dt.ts;
   
-- usage
   select
	activity,
	feature_1,
 	count(*) as total
from
  `mythic-emissary-272811.my_data.stackoverflow_activity`
group by 1,2
order by total desc;

 select
	*
 from
   `mythic-emissary-272811.my_data.stackoverflow_activity`
 where
 	customer = 'Machavity'
 	and activity in ('post', 'edited')
 order by
	1,2;


SELECT trim('string') = trim(' string') AS test;

--First ever edit after posting
select
	q.customer,
	q.ts 		as post_timestamp,
	q.activity 	as post,
	q.feature_1 as post_type,
	e.activity	as edit,
	e.feature_1	as edit_type,
	e.ts 		as edit_timestamp
from
	`mythic-emissary-272811.my_data.stackoverflow_activity` q
	join `mythic-emissary-272811.my_data.stackoverflow_activity` e
	on q.customer = e.customer
	and q.ts < e.ts
where
 	true
 	and q.activity = 'posted'
 	and e.activity = 'edited'
 	and e.activity_occurrence = 1;
			
WITH post_activity AS (
	SELECT
		ph.post_id,
        ph.user_id,
        u.display_name AS user_name,
        ph.creation_date AS activity_date,
  		CASE ph.post_history_type_id
			WHEN 1  THEN 'post_created'
			WHEN 2  THEN 'post_created'
			WHEN 3  THEN 'post_created'
			WHEN 4  THEN 'post_edited'
			WHEN 5  THEN 'post_edited'
			WHEN 6  THEN 'post_edited'
			WHEN 7  THEN 'post_rolledback'
			WHEN 8  THEN 'post_rolledback'
			WHEN 9  THEN 'post_rolledback'
			WHEN 10 THEN 'post_closed'
			WHEN 11 THEN 'post_reopened'
			WHEN 12 THEN 'post_deleted'
			WHEN 13 THEN 'post_undeleted'
			WHEN 14 THEN 'post_locked'
			WHEN 15 THEN 'post_unlocked'
			WHEN 16 THEN 'made_community_wiki'
			WHEN 17 THEN 'post_migrated'
			WHEN 18 THEN 'question_merged'
			WHEN 19 THEN 'question_protected'
			WHEN 20 THEN 'question_unprotected'
			WHEN 22 THEN 'question_unmerged'
			WHEN 24 THEN 'suggested_edit_applied'
			WHEN 25 THEN 'post_tweeted'
			WHEN 31 THEN 'discussion_moved_to_chat'
			WHEN 33 THEN 'post_notice_added'
			WHEN 34 THEN 'post_notice_removed'
			WHEN 35 THEN 'post_migrated_away'
			WHEN 36 THEN 'post_migrated_here'
			WHEN 37 THEN 'post_merge_source'
			WHEN 38 THEN 'post_merge_destination'
			WHEN 50 THEN 'community_bump'
			WHEN 52 THEN 'selected_hot'
			WHEN 53 THEN 'removed_hot'
        END AS activity_type
    FROM
        `bigquery-public-data.stackoverflow.post_history` ph
        INNER JOIN `bigquery-public-data.stackoverflow.users` u on u.id = ph.user_id
    WHERE
    	TRUE 
    	AND user_id > 0 --exclude automated processes
    	AND user_id IS NOT NULL
    	AND ph.creation_date >= CAST('2021-06-01' as TIMESTAMP) 
    	AND ph.creation_date <= CAST('2021-09-30' as TIMESTAMP)
    GROUP BY
    	1,2,3,4,5
)
,post_types AS (
    SELECT
		id AS post_id,
        'question' AS post_type,
    FROM
        `bigquery-public-data.stackoverflow.posts_questions`
    WHERE
        TRUE
    	AND creation_date >= CAST('2021-06-01' as TIMESTAMP) 
    	AND creation_date <= CAST('2021-09-30' as TIMESTAMP)
    UNION ALL
    SELECT
        id AS post_id,
        'answer' AS post_type,
    FROM
        `bigquery-public-data.stackoverflow.posts_answers`
    WHERE
        TRUE
    	AND creation_date >= CAST('2021-06-01' as TIMESTAMP) 
    	AND creation_date <= CAST('2021-09-30' as TIMESTAMP)
 )
SELECT
	user_id,
	user_name,
	activity_date,
	activity_type,
	post_type
FROM post_types pt
	 JOIN post_activity pa ON pt.post_id = pa.post_id
WHERE user_id = 16366214;

