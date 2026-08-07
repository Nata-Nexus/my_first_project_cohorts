--2
select *
from project.cohort_users_raw
limit 10;

--3
select *
from project.cohort_events_raw
limit 10;
       
--4 очищення дати в users
with cohort_users as (
select  user_id,
         promo_signup_flag,
      case 
           when signup_datetime like '%-%-%' then
      case 
           when signup_datetime ~ '-\d{2}$' or signup_datetime ~ '-\d{2}\s' 
                then to_date(left(replace(trim(signup_datetime), '-', '/'), 8), 'DD/MM/YY')
                else to_date(replace(trim(signup_datetime), '-', '/'), 'DD/MM/YYYY') 
                end
           when signup_datetime like '%.%.%' then
      case 
           when signup_datetime ~ '\.\d{2}$' or signup_datetime ~ '\.\d{2}\s' 
                then to_date(left(replace(trim(signup_datetime), '.', '/'), 8), 'DD/MM/YY')
                else to_date(replace(trim(signup_datetime), '.', '/'), 'DD/MM/YYYY')
                end
           when signup_datetime like '%/%/%' then
      case 
           when signup_datetime ~ '/\d{2}$' or signup_datetime ~ '/\d{2}\s' 
                then to_date(left(trim(signup_datetime), 8), 'DD/MM/YY')
                else to_date(trim(signup_datetime), 'DD/MM/YYYY')
                end
           when signup_datetime ~ '^\d{4}' then 
                to_date(left(trim(signup_datetime), 10), 'YYYY-MM-DD')
                else null 
                end as signup_date
from project.cohort_users_raw
),
cohort_events as (
  select  user_id,
          event_type,
      case 
           when event_datetime like '%-%-%' then
      case 
           when event_datetime ~ '-\d{2}$' or event_datetime ~ '-\d{2}\s' 
                 then to_date(left(replace(trim(event_datetime), '-', '/'), 8), 'DD/MM/YY')
                 else to_date(replace(trim(event_datetime), '-', '/'), 'DD/MM/YYYY') 
                 end
           when event_datetime like '%.%.%' then
      case 
           when event_datetime ~ '\.\d{2}$' or event_datetime ~ '\.\d{2}\s' 
                 then to_date(left(replace(trim(event_datetime), '.', '/'), 8), 'DD/MM/YY')
                 else to_date(replace(trim(event_datetime), '.', '/'), 'DD/MM/YYYY')
                 end
           when event_datetime like '%/%/%' then
      case 
           when event_datetime ~ '/\d{2}$' or event_datetime ~ '/\d{2}\s' 
                 then to_date(left(trim(event_datetime), 8), 'DD/MM/YY')
                 else to_date(trim(event_datetime), 'DD/MM/YYYY')
                 end
           when event_datetime ~ '^\d{4}' then 
                 to_date(left(trim(event_datetime), 10), 'YYYY-MM-DD')
                 else null 
                 end as event_date
from project.cohort_events_raw
--У таблицях cohort_users_row та cohort_events_row проаналізовано які є типи дат із деліметрами у відповідних стовпцях
--Дати очищено від зайвих пробілів, застосовано функцію регулярного виразу, де всі дати зведені до одного стандарту і переведені їх у тип поля date
),
joined_data as (
    select 
        u.user_id,
        u.promo_signup_flag,
        u.signup_date,
        e.event_date,
        e.event_type
    from cohort_users u
    join cohort_events e on u.user_id = e.user_id
)
--з'єднуємо таблицю користувачів із таблицею подій по спільному полю ser_id, щоб пожну подію прив'язати до користувача.
select 
    promo_signup_flag,
    date_trunc('month', signup_date)::date AS cohort_month,
    extract(month from age(
        date_trunc('month', event_date),
        date_trunc('month', signup_date)
   ))::int as month_offset,
    count(distinct user_id) as users_total
from joined_data
where date_trunc('month', event_date)::date BETWEEN '2025-01-01' AND '2025-06-01'
  and event_type <> 'test_event'
group by 1, 2, 3
order by 1, 2, 3;
--групуємо користувачів у кагорти cohort_month за місяцем реєстрації.
--month_offset - обчислюємо тривалівсть активності користувачів (на який місяць після реєстрації сталася подія).
--рахуємо кількість унікальних користувачів для кожної кагорти реєстрації місяця.
--відсікаємо test_event (технічні події)
--сортуємо результати.
       

      





