-- Faasos is an Indian "food on demand" service.It is one of the brands owned by the online restaurant company,
-- We have to analyse the food delivery trends and patterns gain the useful insights from the given data

-- Created driver table
use fasoos_project;

-- table contains the information when the driver were registered

CREATE TABLE driver(driver_id integer,reg_date date); 
INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'2021-01-01'),
 (1, '2021-01-01'),
(2, '2021-03-01'),
(3, '2021-08-01'),
(4, '2021-01-15');
select * from driver;

-- Created ingredients table
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');
select * from ingredients;

-- create rolls table
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

-- create rolls_recipes table

CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

-- create driver_order table

CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2021-01-08 21:30:45','25km','25mins',null),
(8,2,'2021-01-10 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2021-01-11 18:50:20','10km','10minutes',null);

-- creating customer orders table

CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','2021-01-01  18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-01-02 23:51:23'),
(3,102,2,'','NaN','2021-01-02 23:51:23'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,2,'4','','2021-01-04 13:23:46'),
(5,104,1,null,'1','2021-01-08 21:00:29'),
(6,101,2,null,null,'2021-01-08 21:03:13'),
(7,105,2,null,'1','2021-01-08 21:20:29'),
(8,102,1,null,null,'2021-01-09 23:54:33'),
(9,103,1,'4','1,5','2021-01-10 11:22:59'),
(10,104,1,null,null,'2021-01-11 18:34:49'),
(10,104,1,'2,6','1,4','2021-01-11 18:34:49');
-- checking the tables

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

-- A. Metrics
-- 1. How many rolls were ordered
select count(roll_id) from customer_orders;
-- 14

2. How may successful orders were delivered by the drivers ?
select * from driver_order; -- we have to check the data.

select driver_id, count(distinct order_id) as total_successful_orders from driver_order where cancellation not in ('Cancellation','Customer Cancellation')
group by driver_id;

3. How many each type of rolls were delivered?

select * from driver_order; -- we have to check the data.
select * from rolls;
select * from customer_orders;
-- joining customer_orders(roll_id) and rolls( roll_name )table 
with roll_type as (select c.*,r.roll_name from customer_orders c join rolls r on c.roll_id=r.roll_id) ,

successful_delivered as (
-- data cleaning for cancellation
select * from (
select *,case 
		when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as order_cancel_details
from driver_order )a 
where order_cancel_details='nc')

select r.roll_name, count(*) from roll_type r 
join successful_delivered s on r.order_id=s.order_id
group by r.roll_name;

4. How many veg and non veg rolls were ordered by the each customer?
-- checking the data 
select * from rolls;
select * from customer_orders;

select a.*, r.roll_name from
(select c.customer_id,r.roll_id,count(r.roll_id) as order_cnt from customer_orders c
join rolls r on c.roll_id=r.roll_id
group by c.customer_id, r.roll_id)a inner join rolls r on a.roll_id=r.roll_id

5. what was the maximum number of rolls delivered in a single order?
with max_roll_orders as (
select order_id,count(roll_id) as cnt ,rank() over (order by count(roll_id) desc) as rnk from customer_orders 
where 
order_id in (
			select order_id from (
-- data cleaning for cancellation and make for successful delivered
									select *,case 
									when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as order_cancel_details
									from driver_order )a 
									where order_cancel_details='nc')
                                    group by order_id)
select * from max_roll_orders where rnk=1;
6. For each customer, how many delivered rolls at least 1 change and how many had no changes?
select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from rolls_recipes;

-- Lets move to the data cleaning part
with cleaned_customer_orders (order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(select order_id,
		customer_id,roll_id,
		case 
			when not_include_items is null or not_include_items='' then '0' else not_include_items end as new_not_include_items,
		 case when extra_items_included is null or extra_items_included='' or extra_items_included='NaN' then '0' else extra_items_included end as new_extra_items_included,
			order_date
from customer_orders),
-- select * from cleaned_customer_orders

-- data cleaning of driver_order table
 cleaned_driver_order (order_id,driver_id,pickup_time,distance,duration,cancellation) as
(select order_id,
		driver_id,
        pickup_time,
        distance,duration,
        case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation
from driver_order)
-- select * from cleaned_driver_order
select customer_id,chan_no_chang,count(order_id) as cnt_least from
(select *, case when not_include_items='0' and extra_items_included='0' then 'no change' else 'change' end as chan_no_chang
 from cleaned_customer_orders where order_id in (
select order_id from cleaned_driver_order where cancellation!=0)) c
group by customer_id,chan_no_chang;
-- Data cleaning completed
7. What was the total number of rolls were ordered for each order of the day?

select * from customer_orders;
select hour_bucket,count(roll_id) from
(select *, concat(hour(order_date),'-',hour(order_date)+1) as hour_bucket
from customer_orders)a
group by hour_bucket
order by 1;
              
8. What was the number of orders for each day of the week?
select * from customer_orders;
select date_name,count(roll_id) as roll_orders from
(select * ,dayname(order_date) as date_name from customer_orders)a 
group by date_name;

9. What was the average time in minute it took for each driver to pickup the orders at the fasoos HQ?

select * from customer_orders;
select * from driver_order;
-- we have to join both the table
 
select driver_id, avg(time_in_minute) as avg_time,count(order_id) as order_cnt from
(select c.order_id,d.driver_id,timestampdiff(minute,c.order_date,d.pickup_time) as time_in_minute,
		row_number() over (partition by order_id order by timestampdiff(minute,c.order_date,d.pickup_time)) as rnk
from customer_orders c 
join driver_order d on c.order_id=d.order_id where d.pickup_time is not null)a
where rnk=1
group by driver_id;

-- checking one by one
select * ,timestampdiff(minute,c.order_date,d.pickup_time) as time_in_minute,timediff(c.order_date,d.pickup_time) as time from  customer_orders c 
join driver_order d on c.order_id=d.order_id where d.pickup_time is not null



10.Is there any relationaship between the number of rolls and how long the orders it get to prepare?

select order_id, count(roll_id),round(avg(time_in_minute)) as roll_cnt from
(select c.* ,timestampdiff(minute,c.order_date,d.pickup_time) as time_in_minute,timediff(c.order_date,d.pickup_time) as time from  customer_orders c 
join driver_order d on c.order_id=d.order_id where d.pickup_time is not null)a
group by order_id

11. what was the average distance travelled for each of the customer?

select customer_id,round(avg(new_distance)) as avg_distance
from
(select d.*,c.customer_id,
	cast(trim(REPLACE(d.distance, 'km', '')) as decimal(4,2)) as new_distance ,timestampdiff(minute,c.order_date,d.pickup_time) as time_in_minute,timediff(c.order_date,d.pickup_time) as time 
from  customer_orders c 
join driver_order d on c.order_id=d.order_id where d.pickup_time is not null)a
group by customer_id;

11. What was the average speed for each driver for each deliverey and do you notice any trend for these values?
select * from driver_order;
-- first we have to clean the data
select *,cast(trim(replace(distance,'km',' '))as decimal (4,2)) as new_distance,
		replace(duration,'minutes',' ') new_duraiton
from driver_order where distance is not null;


12. what is the total successful dilivery percentage for each driver?

select driver_id,concat(round(sum(order_cancel)/count(*)*100),'%') as per_order from
(select driver_id,case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as order_cancel
from driver_order )a
group by driver_id

