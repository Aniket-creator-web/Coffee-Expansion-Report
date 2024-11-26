-- START --

create schema monday_coffee_db;
use monday_coffee_db;

drop table if exists city;
drop table if exists products;
drop table if exists customers;
drop table if exists sales;

-- 1st import city table --
-- 2nd import products table --
-- 3rd import customers table --
-- 4rd import sales table --

select * from city;
select * from products;
select * from customers;
select * from sales;

-- Report & Data Analysis

-- Q1 --
-- COFFEE CONSUMER COUNT --
-- HOW MANY PEPOLE IN EACH CITY ARE ESTIMATED TO CONSUMER COFFEE, GIVEN THAT 25% POPULATION OF DOES --

select city_name,
round((population * 0.25)/1000000,2) as coffee_consumer_in_millions,
city_rank 
from city
order by 2 desc;

-- Q2 --
-- TOTAL REVENUE FROM COFFEE SALES --
-- WHAT IS THE TOTAL REVENUE GENERATED FROM COFFEE SALES ACROSS ALL CITIES IN THE LAST QUAERTER OF 2023 --

select * 
from sales;

select *,
extract(year from sale_date) as Year,
extract(quarter from sale_date) as Qtr
from sales
where extract(year from sale_date)=2023
and
extract(quarter from sale_date)=4;

select ct.city_name,sum(s.total) as total_revenue
from sales as s
join customers as c
on s.customer_id=c.customer_id
join city as ct
on c.city_id=ct.city_id
where extract(year from sale_date)=2023
and
extract(quarter from sale_date)=4
group by 1
order by 2 desc;

-- Q3 --
-- SALES COUNT FOR EACH PRODUCT --
-- HOW MANY UNITS OF EACH COFFEE PRODUCT HAS BEEN SOLD ? --

select * from products;
select * from sales;

select p.product_name,count(s.sale_id)
from sales as s
left join products as p
on s.product_id=p.product_id
group by 1
order by 2 desc;

-- Q4 --
-- AVERAGE SALE AMOUNT PER CITY --
-- WHAT IS THE AVERAGE SALES AMOUNT PER CUSTOMER IN EACH CITY ? --

select ct.city_name,
sum(s.total) as total_revenue,
count(distinct s.customer_id) as total_customer,
-- avg(s.total) as avg_purchase_per_customer, -- Changed Calculation --
round(sum(s.total) / count(distinct s.customer_id),2)  as avg_sale_pc
from sales as s
join customers as c
on s.customer_id=c.customer_id
join city as ct
on ct.city_id=c.city_id
group by 1
order by 2 desc;

-- Q5 --
-- CITY POPULATIONS AND COFFEE CONSUMERS --
-- PROVIDE A LIST OF CITIES ALONG WITH THEIR POPULATIONS AND EASTIMATED COFFEE CONSUMERS. --

WITH city_table AS (
    SELECT 
        city_name,
        ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers
    FROM city
),
customers_table AS (
    SELECT 
        ct.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_customers
    FROM sales AS s
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ct
        ON ct.city_id = c.city_id
   GROUP BY ct.city_name
)
SELECT 
    customers_table.city_name,
    city_table.coffee_consumers AS coffee_consumers_in_millions,
    customers_table.unique_customers
FROM city_table
JOIN customers_table 
    ON city_table.city_name = customers_table.city_name
	  ORDER BY coffee_consumers_in_millions DESC ; 
     
-- Q6 --
-- TOP SELLING PRODUCTS BY CITY --
-- WHAT ARE THE TOP 3 SELLING PRODUCTS IN EACH CITY BASED ON SALES VOLUME ? --

SELECT * 
FROM -- table 
(
SELECT
    ct.city_name,
    p.product_name,
    COUNT(s.sale_id) AS total_orders,
    DENSE_RANK() OVER (PARTITION BY ct.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank_
FROM sales AS s
JOIN products AS p ON s.product_id = p.product_id
JOIN customers AS c ON c.customer_id = s.customer_id
JOIN city AS ct ON ct.city_id = c.city_id
GROUP BY ct.city_name, p.product_name
-- ORDER BY ct.city_name, total_orders DESC; 
) AS t1
WHERE rank_ <=3;

-- Q7 --
-- CUSTOMER SEGMENTTATIONS BY CITY --
-- HOW MANY UNIQUE CUSTOMERS ARE THERE IN EACH CITY WHO HAVE PURCHASE COFFEE PRODUCTS ? --

select * from products;
SELECT 
	ct.city_name,
    count(distinct c.customer_id) as unique_customers
FROM city AS ct
LEFT JOIN customers AS c
	ON c.city_id=ct.city_id
    JOIN SALES AS S
    ON s.customer_id=c.customer_id
    WHERE 
		s.product_id IN(1,2,3,4,5,6,7,8,9,10,11,12,13,14)
   GROUP BY 1;
   
-- Q8 --
-- AVERAGE SALE vs RENT --
-- FIND EACH CITY AND THEIR AVERAGE SALE PER CUSTOMER AND AVG RENT PER CUSTOMER --
 
 WITH city_table AS (
    SELECT 
        ct.city_name,
        COUNT(DISTINCT s.customer_id) AS total_customer,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pc
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ct
        ON ct.city_id = c.city_id
    GROUP BY ct.city_name
    ORDER BY total_customer DESC
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    cte.total_customer,
    cte.avg_sale_pc,
    round(cr.estimated_rent /cte.total_customer,2) as average_rent_for_cust
FROM city_rent AS cr
JOIN city_table AS cte
    ON cr.city_name = cte.city_name
 ORDER BY 4 DESC;


-- Q9 -- 
-- MONTHLY SALES GROWTH --
-- SALES GROWTH RATE: CALCULATE THE PERCENTAGE GROWTH (OR DECLINE) IN SALES OVER DIFFERENT TIME PERIOD (MONTHLY) --
-- BY EACH CITY --

WITH monthly_sales AS (
    SELECT 
        ct.city_name,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        SUM(s.total) AS total_sale 
    FROM sales AS s
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ct
        ON ct.city_id = c.city_id
    GROUP BY ct.city_name, year, month
    ORDER BY ct.city_name, year, month
),
growth_ratio AS (
    SELECT 
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale) OVER (PARTITION BY city_name ORDER BY year, month) AS last_month_sale
    FROM monthly_sales
)
SELECT 
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND((cr_month_sale - last_month_sale) / last_month_sale * 100, 2) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;


-- Q10 --
-- MARKET POTENSIAL ANALYSIS --
-- IDENTIFY TOP 3 CITY BASED ON HIGHEST SALES, RETURN CITY NAME, TOTAL SALE, TOTAL RENT, TOTAL CUSTOMERS, ESTIMATED COFFEE CONSUMERS --

WITH city_table AS (
    SELECT 
        ct.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customer,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pc
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ct
        ON ct.city_id = c.city_id
    GROUP BY ct.city_name
    ORDER BY total_customer DESC
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25)/1000000,3) as estimated_coffee_consumer_in_millions
    FROM city
)
SELECT 
    cr.city_name,
    total_revenue,
    cr.estimated_rent as total_rent,
    cte.total_customer,
    estimated_coffee_consumer_in_millions,
    cte.avg_sale_pc,
    round(cr.estimated_rent /cte.total_customer,2) as average_rent_for_cust
FROM city_rent AS cr
JOIN city_table AS cte
    ON cr.city_name = cte.city_name
 ORDER BY 4 DESC;

/*
-- Recomendation
City 1: Pune
	1. Avg rent per customer is very less,
    2. Highest total revenue,
    3. Avg_sale per customers is also high
    
City 2: Delhi
	1. Highest estimated coffee consumer which is 7.7 million
    2. Highest total customers which is 68
    3. Avg rent per customer 330 (still under 500)

City 3. Jaipur
	1. Highest customer no which is 69
    2. Avg rent per customer is very less 156
    3. Avg sale per customer is better which at 11.6k */
    
						/* OBJECTIVES
The goal of this project is to analyze the sales data of Monday Coffee, a company that has
been seeling its prpducts online since January 2023, and to recommend the top three major
cities in india for opening new coffee shop locations based on consumer demand and sales
performance.
*/

-- END -- 