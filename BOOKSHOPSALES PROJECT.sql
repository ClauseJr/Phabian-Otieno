-- Q1 Total Revenue from Book Sales
-- What is the total revenue generated from book sales across all customers in the year 2024?

SELECT 
	COUNT(customer_id) num_customers,
	EXTRACT(YEAR FROM order_date) yr,
	SUM(total_amount) total_revenue
FROM Customer_Orders
GROUP BY EXTRACT(YEAR FROM order_date)
	-- HAVING EXTRACT(YEAR FROM order_date) = 2024
ORDER BY total_revenue DESC;


-- Q2 Order Count for Each Book
-- How many units of each book have been sold across all orders?

SELECT
	bs.title,
	SUM(co.quantity) total_quantity,
	ROW_NUMBER() OVER(ORDER BY SUM(co.quantity) DESC ) rank_bks_sold
FROM Customer_Orders co
LEFT JOIN Books_sold bs
	ON co.book_id = bs.book_id
GROUP BY bs.title;


-- Q3 Average Order Value per Customer
-- What is the average total amount spent per customer?

SELECT 
	nc.name,
	ROUND(AVG(co.total_amount)::numeric,2) avg_order
FROM Num_Customers nc
INNER JOIN Customer_Orders co
	ON nc.customer_id = co.customer_id
GROUP BY nc.name
ORDER BY avg_order DESC
LIMIT 5;

-- Q4 Top Selling Books by Genre
-- What are the top 3 selling books in each genre based on sales volume?


WITH CTE_sales_volume AS
(
	SELECT
		bs.title,
		bs.genre,
		SUM(co.quantity) sales_volume
	FROM Books_sold bs
	INNER JOIN Customer_Orders co
		ON bs.book_id = co.book_id
	GROUP BY bs.genre, bs.title
),
CTE_rank_sales_vol AS
(
SELECT
	title,
	genre,
	sales_volume,
	ROW_NUMBER() OVER (PARTITION BY genre ORDER BY sales_volume DESC) rank_sales_volume
FROM CTE_sales_volume
)
SELECT
	title,
	genre,
	sales_volume,
	rank_sales_volume
FROM CTE_rank_sales_vol
WHERE rank_sales_volume <= 3


-- Q5 Customer Segmentation by Genre
-- How many unique customers have purchased books from each genre?


WITH CTE_unique_customers AS 
(
	SELECT
		bs.genre,
		COUNT(DISTINCT co.customer_id) unique_customer,
		EXTRACT(YEAR FROM co.order_date) year_sales
	FROM Customer_Orders co
	INNER JOIN Num_Customers nm
		ON co.customer_id = nm.customer_id
	LEFT JOIN Books_sold bs
		on co.book_id = bs.book_id
	GROUP BY bs.genre, co.order_date
),
CTE_rank_unique_customers AS
(
SELECT  
	genre, 
	unique_customer,
	year_sales,
	ROW_NUMBER() OVER(PARTITION BY genre ORDER BY unique_customer DESC ) rank_unique_customers
FROM CTE_unique_customers
)
SELECT
	genre, 
	unique_customer,
	year_sales,
	rank_unique_customers
FROM CTE_rank_unique_customers
WHERE rank_unique_customers <= 3;


-- Q6 Average Book Price vs Average Purchase Amount
-- Compare each genre’s average book price with the average total amount spent per order.

SELECT 
	bs.genre,
	ROUND(SUM(bs.price)::numeric,2) total_bks_price,
	SUM(co.total_amount) total_bks_amount,
	ROUND(AVG(bs.price)::numeric,2) avg_bks_price,
	ROUND(AVG(co.total_amount)::numeric,2) avg_total_amount
FROM Customer_Orders co
LEFT JOIN Books_sold bs
	ON co.book_id = bs.book_id
GROUP BY bs.genre
ORDER BY avg_total_amount DESC

-- Q7 Monthly Sales Growth
-- Calculate the percentage growth (or decline) in total sales on a monthly basis in 2024.

WITH CTE_monthly_sales AS 
(
	SELECT
		COUNT(customer_id) num_customers,
		EXTRACT(MONTH FROM order_date) mon_sales,
		EXTRACT(YEAR FROM order_date) yr_sales,
		SUM(total_amount) total_revenue
	FROM Customer_Orders
	GROUP BY EXTRACT(MONTH FROM order_date),EXTRACT(YEAR FROM order_date)
		HAVING EXTRACT(YEAR FROM order_date) = 2024
	-- ORDER BY total_revenue DESC
),
CTE_diff_sales AS 
(
	SELECT
		num_customers,
		mon_sales,
		yr_sales,
		total_revenue AS sales_revenue,
		LAG(total_revenue, 1) OVER(PARTITION BY num_customers ORDER BY mon_sales, yr_sales ) diff_sales
	FROM CTE_monthly_sales
)
SELECT
	num_customers,
	mon_sales,
	yr_sales,
	sales_revenue,
	diff_sales,
	ROUND((sales_revenue - diff_sales)::numeric/diff_sales::numeric * 100, 2) pec_sales_diff
FROM CTE_diff_sales
WHERE diff_sales IS NOT NULL;


-- Q8 Market Potential by Genre
-- Identify the top 3 genres based on total sales, total orders, and number of unique customers.

SELECT 
	bs.genre,
	COUNT(DISTINCT co.customer_id) unique_cus,
	COUNT(co.order_id) unique_ord,
	SUM(co.total_amount) total_sales
FROM Customer_Orders co
INNER JOIN Books_sold bs
	ON co.book_id = bs.book_id
GROUP BY bs.genre
ORDER BY total_sales DESC;



-- Q9 Most Frequent Buyers
-- Which customers have placed the highest number of orders overall?

SELECT
	nc.name,
	nc.city,
	COUNT(co.order_id) num_orders
FROM Num_Customers nc
INNER JOIN Customer_Orders co
	ON nc.customer_id = co.customer_id
GROUP BY nc.name, nc.city
ORDER BY num_orders DESC
LIMIT 5;

-- Q10 Inventory Risk Insight
-- Which books are most frequently ordered but currently have low stock?

WITH CTE_most_orders AS 
(
	SELECT 
		bs.title,
		bs.stock,
		SUM(co.quantity) total_bks_ordered
	FROM Books_sold bs
	INNER JOIN Customer_Orders co
		ON bs.book_id = co.book_id
	GROUP BY title, bs.stock
		-- HAVING bs.stock < 10 AND SUM(co.quantity) > 15
	ORDER BY total_bks_ordered DESC
	)
SELECT
	title,
	stock,
	total_bks_ordered
FROM CTE_most_orders
WHERE stock < 10 AND total_bks_ordered > 15
ORDER BY stock ASC



-- Q11 Customer Lifetime Analysis
-- Which customers have generated the highest lifetime revenue for the library, and when did each make their most recent purchase?


WITH CTE_customer_analysis AS
(
	SELECT
		nc.customer_id,
		nc.name,
		MAX(co.order_date) last_purchase,
		SUM(co.total_amount) total_revenue,
		COUNT(co.order_id) num_orders
	FROM Customer_Orders co
	INNER JOIN Num_Customers nc
		ON co.customer_id = nc.customer_id
	INNER JOIN Books_sold bs
		ON co.book_id = bs.book_id
	GROUP BY nc.name, nc.customer_id
	ORDER BY total_revenue DESC
)
SELECT
	customer_id,
	name,
	last_purchase,
	total_revenue,
	num_orders,
	RANK() OVER(ORDER BY total_revenue DESC) rank_customer_sales
FROM CTE_customer_analysis
ORDER BY total_revenue DESC
LIMIT 3;



-- Q12 Monthly Revenue Contribution by Top Authors
-- Which authors contributed the highest share of total revenue each month in 2024, and how does their performance trend over time?


WITH CTE_authors_con AS 
(
	SELECT
		bs.author,
		EXTRACT(MONTH FROM co.order_date) months,
		SUM(co.total_amount) total_revenue
	FROM Customer_Orders co
	LEFT JOIN Books_sold bs
		ON bs.book_id = co.book_id
	GROUP BY co.book_id, bs.author, co.order_date
		HAVING EXTRACT(YEAR FROM co.order_date) = 2024
	ORDER BY total_revenue DESC
),
CTE_total_sales_authors AS
(
	SELECT
		months,
		SUM(total_revenue) sales_revenue
	FROM CTE_authors_con
	GROUP BY months
),
CTE_ranks_authors AS
(
	SELECT
		cac.author,
		cac.months,
		cac.total_revenue,
		ROUND((cac.total_revenue / ctsa.sales_revenue)::numeric * 100, 2) pec_sales_bks,
		ROW_NUMBER() OVER(PARTITION BY cac.months ORDER BY cac.total_revenue DESC ) rank_sales
	FROM CTE_authors_con  cac
	INNER JOIN CTE_total_sales_authors  ctsa
		ON cac.months = ctsa.months
	GROUP BY cac.months, cac.author, cac.total_revenue, ctsa.sales_revenue
)
SELECT 
	author,
	months,
	total_revenue,
	pec_sales_bks,
	rank_sales
FROM CTE_ranks_authors
WHERE rank_sales <= 3

-- Q13. Seasonal Customer Buying Pattern and Revenue Share
-- Which customers contributed the most to total sales during each quarter of 2024, and how does their purchase frequency compare across the year?

WITH CTE_customer_contribution AS
(
	SELECT
		nc.name,
		EXTRACT(QUARTER FROM co.order_date) qtr,
		SUM(co.total_amount) total_revenue
	FROM Customer_Orders co
	LEFT JOIN Num_Customers nc
		ON co.customer_id = nc.customer_id
	GROUP BY nc.name, co.order_date
		HAVING EXTRACT(YEAR FROM co.order_date) = 2024
	ORDER BY total_revenue DESC
),
CTE_sales_revenue AS 
(
	SELECT
		qtr,
		SUM(total_revenue) sales_revenue
	FROM CTE_customer_contribution
	GROUP BY qtr
),
CTE_rank_contribution AS
(
	SELECT
		cc.name,
		cc.qtr,
		cc.total_revenue,
		ROUND((cc.total_revenue / sr.sales_revenue)::numeric * 100, 2) pec_contribution,
		ROW_NUMBER() OVER(PARTITION BY cc.qtr ORDER BY cc.total_revenue DESC ) rank_contribution
	FROM CTE_customer_contribution cc
	INNER JOIN CTE_sales_revenue  sr
		ON cc.qtr = sr.qtr
	GROUP BY cc.qtr, cc.name, cc.total_revenue, sr.sales_revenue
)
SELECT
	name,
	qtr,
	total_revenue,
	pec_contribution,
	rank_contribution
FROM CTE_rank_contribution
WHERE rank_contribution <= 3

/*
SUMMARY OF CUSTOMERS WITH THE HIGHEST PURCHASE
 
1. Kim Turner 
Made the highest purchases at a total of 13.989k with 4 orders of books

2. Jonathon Strickland 
Made higher purchases at a total of 10.81k with 4 orders

3. Carrie Perez 
Made higher purchases at a total of 10.52k with a higher order of 6 books


SUMMARY OF THE MOST LIKED GENRES OF BOOKS


Genre 1: Romance
	a. Most loved genre with a total of 75 customers 
	b. Highest sales recorded from the customers at 13.0886k
Genre 2: Mystery
	a. Mostly loved genre with a total of 76 customers 
	b. Highest sales recorded from the customers at 12.788k
	c. Recorded a higher number of orders from the sales of books at 83
Genre 3: Science Fiction
	a. Most loved genre with a total of 75 customers 
	b. Recorded the highest number of orders from the sales of books at 84

*/

