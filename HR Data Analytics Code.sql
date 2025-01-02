select * from hr;

-- Data Cleaning if the first step for any analaysis
-- Create the duplicate before 

create table rawhr like hr;
insert into rawhr select * from hr;

select * from rawhr;

-- backup of original data has created as table rawhr

rename table hr to hrt;
select * from hrt;

-- Backup has created now initial step check for duplicate values as there is no primary key use cte for checking duplicates

WITH duplicate_hr AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY emp_id, first_name, last_name, birthdate, gender, race, department, 
                            jobtitle, location, hire_date, termdate, location_city, location_state
               ORDER BY emp_id  ) AS row_num FROM hrt )
SELECT * 
FROM duplicate_hr
WHERE row_num > 1;

-- No duplicates found carry on with data cleaning 

-- first step change the column names accordingly 

alter table hrt
change ï»¿id emp_id varchar(20);

describe hrt;

UPDATE hrt
SET birthdate = CASE
    WHEN birthdate LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;

select * from hrt;
describe hrt;

alter table hrt
modify birthdate date;

-- in the same way update the hire_date and termdate

UPDATE hrt
SET hire_date = CASE
    WHEN hire_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;

alter table hrt
modify hire_date date;

describe hrt;

-- termdate updating column and modifying datatype 

UPDATE hrt
SET termdate = date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate !='';

update hrt
set termdate = NULL
where termdate = 'Null' ;

-- Add age column 

ALter table hrt
add column age int;

update hrt
set age = timestampdiff(YEAR,birthdate, curdate());

select * from hrt;

-- data cleaning part is done 
-- now jumping into data exploration part

-- 1. Age breakdown

select gender, count(gender) as totalcount, ( count(gender) * 100 / (select count(*) from hrt) )  as percentage_gender 
from hrt where termdate is NULL group by gender;



-- 2. Race breakdown

select race, count(race) as total_count,
count(race) * 100 / (select count(*) from hrt) as race_percentage
from hrt group by race
order by race_percentage desc;

-- 3. Age distribution

SELECT 
    CASE 
        WHEN age > 50 THEN 'Old'
        WHEN age BETWEEN 35 AND 50 THEN 'Middle'
        WHEN age < 35 THEN 'Young'
        ELSE NULL 
    END AS age_distribution, 
    COUNT(*) AS Totalcount
FROM hrt 
WHERE termdate IS NULL 
GROUP BY age_distribution 
ORDER BY age_distribution DESC ;

-- 4. Employees count working Head Quarters vs remote

select location, Count(*) as total_count from hrt
where termdate is null group by location;

-- 5. Average length of employment who have been terminated

select round(avg(year(termdate) - year(hire_date)),0) as length_of_emp
from hrt
where termdate is not null and termdate <= curdate();

-- 6. How does the gender distribution vary acorss dept. and job titles

select * from hrt;

select gender, department, count(*) as total_count 
from hrt 
where termdate is not null
group by gender, department
order by gender, department;
       
       
-- 7. What is the distribution of jobtitles acorss the company

select jobtitle, count(*) as job_titles_count
from hrt
where termdate is not null
group by jobtitle
order by job_titles_count desc;

-- 8. Which dept has the higher turnover/termination rate

select department, count(*) as total_count , 
count(case when termdate is not null and termdate <= curdate() then 1 end) as terminated_count,
round(count(case when termdate is not null and termdate <= curdate() then 1 end) *100 / count(*),1) as percentage_of_termdate
from hrt
group by department
order by total_count desc;

-- 9 What is the distribution of employees across location_state 

select location_state, count(*) as location_count,
count(*) * 100/ (select Count(*) from hrt) as percentage_location
from hrt
where termdate is null
group by location_state;

select location_city, count(*) as location_count,
count(*) * 100/ (select Count(*) from hrt) as percentage_location
from hrt
where termdate is null
group by location_city;

-- 10. How has the companys employee count changed over time based on hire and termination date.

select * from hrt;

SELECT year, hires, terminations, hires-terminations AS net_change,
        (terminations/hires)*100 AS change_percent
	FROM(
			SELECT YEAR(hire_date) AS year,
            COUNT(*) AS hires,
            SUM(CASE 
					WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1 
				END) AS terminations
			FROM hrt
            GROUP BY YEAR(hire_date)) AS subquery
GROUP BY year
ORDER BY year;


-- 11. What is the tenure distribution for each dept.

SELECT department, round(avg(datediff(termdate,hire_date)/365),0) AS avg_tenure
FROM hrt
WHERE termdate IS NOT NULL AND termdate<= curdate()
GROUP BY department
