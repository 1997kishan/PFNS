use  sql_project;
-- Create 'movie' table
CREATE TABLE movie (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255),
    year INT,
    date_published DATE,
    duration INT,
    country VARCHAR(255),
    worlwide_gross_income INT,
    languages VARCHAR(255),
    production_company VARCHAR(255)
    
);

-- Create 'genre' table
CREATE TABLE genre (
    movie_id VARCHAR(50),
    genre VARCHAR(255)
);

-- Create 'director_mapping' table
CREATE TABLE director_mapping (
    movie_id VARCHAR(50),
    name_id VARCHAR(50)
);

-- Create 'role_mapping' table
CREATE TABLE role_mapping (
    movie_id VARCHAR(50),
    name_id VARCHAR(50),
    category VARCHAR(255)
);

-- Create 'names' table
CREATE TABLE names (
    id  VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255),
    height INT,
    date_of_birth DATE,
    known_for_movies VARCHAR(255)
);

-- Create 'ratings' table
CREATE TABLE ratings (
    movie_id VARCHAR(50) PRIMARY KEY,
    avg_rating DECIMAL(3,1),
    total_votes INT,
    median_rating DECIMAL(3,1)
);
select* from movie;
select * from genre;
select * from names;
select * from director_mapping;
select * from role_mapping;
select * from ratings;
-- Segment 1: Database - Tables, Columns, Relationships
select count(*) from movie;
select count(*) from genre;
select count(*) from names;
select count(*) from ratings;
select count(*) from role_mapping;
select count(*) from director_mapping;

-- Segment 2: Movie Release Trends
select count(*) as movie_cnt,
		month(date_published) as month_trend,
        year
from movie
group by 2,3
order by 3 ;
select count(*) as movie_cnt from movie
where country in ('USA','India') and year='2019';

-- Segment 3: Production Statistics and Genre Analysis
SELECT DISTINCT genre
FROM genre;
SELECT genre,
		COUNT(*) AS movie_count
FROM genre
GROUP BY genre
ORDER BY movie_count DESC
LIMIT 1;
SELECT COUNT(*) AS single_genre_movies_count
FROM (
    SELECT movie_id
    FROM genre
    GROUP BY movie_id
    HAVING COUNT(DISTINCT genre) = 1
) single_genre_movies;
select g.genre,
	   avg(m.duration) as avg_duration
from movie m
join genre g 
on m.id=g.movie_id
group by 1;

SELECT genre, dense_rank() OVER (ORDER BY movie_count DESC) AS genre_rnk
FROM (
    SELECT genre, COUNT(*) AS movie_count
    FROM genre
    GROUP BY genre
) genre_counts;

-- Segment 4: Ratings Analysis and Crew Members


select min(avg_rating), max(avg_rating),min(total_votes), max(total_votes),min(median_rating)
from  ratings;
select movie_id 
from ratings
order by avg_rating desc
limit 10;


SELECT
    median_rating,
    COUNT(*) AS movie_count
FROM
    ratings
GROUP BY
    median_rating;
    
    
select 
	m.production_company
from movie m
	join ratings r 
	on m.id=r.movie_id
where r.avg_rating>8
order by r.avg_rating desc;

select
	g.genre,
    count(g.movie_id) as movie_count
from genre g
join ( select 
			m.id,
			MONTH(m.date_published) as month,
			m.year,
            m.country
		from movie m
		join ratings r 
        on m.id=r.movie_id
        where m.country='USA' and r.total_votes>1000 and m.year='2017') mr
	on g.movie_id=mr.id
    where mr.month='3'
    group by 1;
    
select 
	g.movie_id
from genre g 
join ratings r 
on g.movie_id=r.movie_id
where g.genre LIKE 'The%' and r.avg_rating>8;

-- Segment 5: Crew Analysis

select  n.name,
	   dr.genre
from names n 
join 
	(select d.name_id,
				d.movie_id ,
                g.genre,
			   r.avg_rating
		from director_mapping d
		join ratings r on
		d.movie_id=r.movie_id
        join genre g 
        on r.movie_id=g.movie_id
		where r.avg_rating>8 ) dr
	on n.id=dr.name_id
    order by avg_rating desc
    limit 3;

select
	a.name_id
from role_mapping a
join ratings r
on a.movie_id =r.movie_id
where r.median_rating>=8 and a.category='actor'
order by r.median_rating desc
limit 2;

select
	m.production_company
from movie m
join ratings r on
m.id=r.movie_id
order by r.total_votes desc 
limit 3;

select
	i.name_id,
    dense_rank() over (partition by i.name_id order by r.avg_rating ) as rnk
from ratings r
join 
(select
	a.movie_id,
    m.languages,
    a.name_id
from role_mapping a
join movie m on
a.movie_id=m.id
where m.country='India' and a.category='actor' )  i
on i.movie_id=r.movie_id;


select
	i.name_id
from ratings r 
join 
(select
	a.movie_id,
    m.languages,
    a.name_id
from role_mapping a
join movie m on
a.movie_id=m.id
where m.country='India' and a.category='actress' )  i
on i.movie_id=r.movie_id
order by r.avg_rating desc
limit 5;

-- Segment 6: Broader Understanding of Data
select 
	g.movie_id,
     i.category,
    dense_rank() over (partition by g.movie_id order by r.avg_rating ) as movie_rnk
from genre g
join ratings r on 
g.movie_id=r.movie_id
join role_mapping i 
on r.movie_id=i.movie_id
where g.genre='Thriller';


WITH RankedMovies AS (
select
	m.id,
    title,
    m.year ,
    row_number() over (partition by m.year order by worlwide_gross_income desc) as ranking
from movie m
join genre g 
on m.id=g.movie_id
where g.genre in(select 
					genre
	from
		(select 
			g.genre,
            row_number() over (partition by g.genre order by r.avg_rating desc) as gn_rnk
		from genre g
		join ratings r 
		on g.movie_id=r.movie_id
		order by r.avg_rating desc
		) g
        where gn_rnk<=3) 
)
SELECT
    title,
    year
FROM
    RankedMovies
WHERE
    ranking <= 5
ORDER BY
    year, ranking;
    
select 
	production_company
from ( select
			production_company,
			count(languages) as cnt
	from movie
    where worlwide_gross_income in (select worlwide_gross_income from movie order by 1 desc  )
    group by 1				
    order by 2 desc)a 
    limit 2;
    
    select a.name,
			c.avg_rating
    from names a 
    join role_mapping b
    on a.id=b.name_id
    join ratings c 
    on b.movie_id=c.movie_id
    join genre g 
    on c.movie_id=g.movie_id
    where g.genre='Drama' and c.avg_rating>8 and b.category='actress'
    order by c.avg_rating desc
    limit 2;
    
with director_movie_cnt as  (select 
	d.name_id,
    n.name,
    count(n.id) as movie_cnt
from names n
	join director_mapping d
    on n.id=d.name_id
    group by 1,2
    order by 3 desc) 
    
    ,avg_duration as  ( select d.name_id,
			avg(m.duration) as avg_duration
		from director_mapping d
        join movie m on
        d.movie_id=m.id
        group by 1)  ,
        
director_ratings as	(select d.name_id,
							avg(r.avg_rating) as avg_rating
					from director_mapping d
                    join ratings r 
                    on d.movie_id=r.movie_id
                    group by 1
                    )
                    
	select distinct dmc.name,dmc.movie_cnt,ad.avg_duration,dr.avg_rating
			
    from director_movie_cnt dmc
    join avg_duration ad 
    on dmc.name_id=ad.name_id
    join director_ratings dr
    on ad.name_id=dr.name_id
	order by 2 desc, 3 desc, 4 desc
   limit 9;
    -- Segment 7: Recommendations
    
select g.genre,
	   r.avg_rating,
       r.total_votes
from genre g 
join ratings r 
on g.movie_id=r.movie_id
order by 2 desc; 

-- Based on the above analysis Bolly should focus on the Comedy , Drama, Romance and Thriller like content movies. 

        
            
