-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in all quarters of 2023?


SELECT EXTRACT(quarter FROM sale_date) quarter,
	SUM(total) as total_revenue
FROM coffee.sales
WHERE 
	EXTRACT(YEAR FROM sale_date)  = 2023
group by EXTRACT(quarter FROM sale_date)



SELECT 
	ci.city_name,EXTRACT(quarter FROM s.sale_date) quarter,
	SUM(s.total) as total_revenue
FROM coffee.sales as s
JOIN coffee.customers as c
ON s.customer_id = c.customer_id
JOIN coffee.city as ci
ON ci.city_id = c.city_id
WHERE EXTRACT(YEAR FROM s.sale_date)  = 2023
GROUP BY 1,EXTRACT(quarter FROM s.sale_date)
ORDER BY 3 DESC

-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM coffee.products  p,
coffee.sales  s
where s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC

-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cx
FROM coffee.sales as s
JOIN coffee.customers as c
ON s.customer_id = c.customer_id
JOIN coffee.city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC


-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * 
FROM 
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM coffee.sales as s
	JOIN coffee.products as p
	ON s.product_id = p.product_id
	JOIN coffee.customers as c
	ON c.customer_id = s.customer_id
	JOIN coffee.city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
) as t1
WHERE rank <= 3

-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table
AS(SELECT ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cx
	FROM coffee.sales as s
	JOIN coffee.customers as c
	ON s.customer_id = c.customer_id
	JOIN coffee.city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC),
city_rent AS(SELECT city_name,estimated_rent FROM coffee.city)
SELECT cr.city_name,cr.estimated_rent,ct.total_cx,ct.avg_sale_pr_cx,
	ROUND(cr.estimated_rent::numeric/ct.total_cx::numeric, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC


-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS
(SELECT ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale,
	LAG(SUM(s.total), 1) OVER(PARTITION BY city_name ORDER BY EXTRACT(YEAR FROM sale_date), 
							  EXTRACT(MONTH FROM sale_date)) as last_month_sale
	FROM coffee.sales as s
	JOIN coffee.customers as c ON c.customer_id = s.customer_id
	JOIN coffee.city as ci ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3 ORDER BY 1, 3, 2)
SELECT  city_name,month,year,total_sale as cr_month_sale,
	last_month_sale,
	ROUND((total_sale-last_month_sale)::numeric/last_month_sale::numeric * 100, 2) as growth_ratio
FROM monthly_sales
WHERE last_month_sale IS NOT NULL	

-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table AS
(SELECT ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cx
	FROM coffee.sales as s
	JOIN coffee.customers as c ON s.customer_id = c.customer_id
	JOIN coffee.city as ci ON ci.city_id = c.city_id
	GROUP BY 1 ORDER BY 2 DESC),
city_rent AS(
SELECT city_name,estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM coffee.city)
SELECT cr.city_name,total_revenue,cr.estimated_rent as total_rent,ct.total_cx,
	estimated_coffee_consumer_in_millions,ct.avg_sale_pr_cx,
	ROUND(cr.estimated_rent::numeric/ct.total_cx::numeric, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct ON cr.city_name = ct.city_name
ORDER BY 2 DESC
