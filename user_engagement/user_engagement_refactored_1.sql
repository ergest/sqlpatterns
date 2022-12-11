with post_activity as (
   select
        ph.post_id,
        ph.user_id,
        u.display_name as user_name,
        ph.creation_date as activity_date,
        case when ph.post_history_type_id in (1,2,3) then 'created'
             when ph.post_history_type_id in (4,5,6) then 'edited' 
        end as activity_type
    from
        post_history ph
        inner join users u on u.id = ph.user_id
    where
        true 
        and ph.post_history_type_id between 1 and 6
        and user_id > 0 --exclude automated processes
        and user_id is not null --exclude deleted accounts
    group by
        1,2,3,4,5
    order by
        activity_date
)
select
    user_id,
    user_name,
    cast(activity_date as date) as activity_date,
    sum(case when activity_type = 'created' and post_type = 'question' then 1 else 0 end) as question_created,
    sum(case when activity_type = 'created' and post_type = 'answer'   then 1 else 0 end) as answer_created,
    sum(case when activity_type = 'edited'  and post_type = 'question' then 1 else 0 end) as question_edited,
    sum(case when activity_type = 'edited'  and post_type = 'answer'   then 1 else 0 end) as answer_edited,
    sum(case when activity_type = 'created' then 1 else 0 end) as posts_created,
    sum(case when post_type = 'question' then 1 else 0 end) as total_questions,
    sum(case when post_type = 'answer' then 1 else 0 end) as total_answers,
    sum(case when activity_type = 'created' and post_type = 'answer' then 1 else 0 end) / 
    sum(case when activity_type = 'created' and post_type = 'question' then 1 else 0 end) *1.0 as answer_to_question_ratio
from
    (
    select
        id as post_id,
        'question' as post_type,
        pa.user_id,
        pa.user_name,
        pa.activity_date,
        pa.activity_type
    from
        posts_questions q
        inner join post_activity pa
            on q.id = pa.post_id
    
     union all

     select
        id as post_id,
        'answer' as post_type,
        pa.user_id,
        pa.user_name,
        pa.activity_date,
        pa.activity_type
    from
        posts_answers q
        inner join post_activity pa 
            on q.id = pa.post_id
    ) as p
group by
    1,2,3
order by
    posts_created desc;