
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

#1. What is the total amount each customer spent at the restaurant?
SELECT customer_id,
	sum(price) AS Sale_Amount
From sales
INNER JOIN menu USING (product_id)
GROUP BY customer_id;
    
# 2. How many days has each customer visited the restaurant?
SELECT customer_id,
	COUNT(DISTINCT order_date) AS Visit_Count 
FROM sales
GROUP BY customer_id;
    
# 3. What was the first item from the menu purchased by each customer?
WITH cte AS 
(SELECT customer_id,product_id,
	ROW_NUMBER() OVER (PARTITION BY customer_id) AS row_no 
    FROM dannys_diner.sales)
SELECT customer_id,product_name FROM cte
INNER JOIN menu USING (product_id) WHERE row_no = 1;

WITH cte AS 
    (SELECT customer_id, product_id,
        RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rank_no
    FROM dannys_diner.sales)
SELECT cte.customer_id, menu.product_name 
FROM cte
INNER JOIN menu ON cte.product_id = menu.product_id 
WHERE cte.rank_no = 1
GROUP BY customer_id, product_name;

# 4. What is the most purchased item on the menu and how many times 
# was it purchased by all customers?
SELECT customer_id,
		product_name AS Popular_item,
        count(product_id) AS Num_purchase 
FROM sales 
INNER JOIN menu USING (product_id)
WHERE product_id = (
		SELECT product_id FROM sales
		GROUP BY product_id
		ORDER BY count(product_id) DESC
		LIMIT 1
) 
GROUP BY customer_id;

SELECT product_name,
		(COUNT(product_id)) AS most_purchased
FROM sales
INNER JOIN menu USING (product_id)
GROUP BY product_id ORDER BY most_purchased DESC LIMIT 1 ; 

# 5. Which item was the most popular for each customer?
WITH cte AS
	(SELECT customer_id, product_id, product_name,
		COUNT(product_id) AS order_count,
		RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS rank_no
	FROM sales
    INNER JOIN menu 
    USING (product_id)
	GROUP BY customer_id, product_id
	)
SELECT customer_id, product_name, order_count 
FROM cte WHERE rank_no = 1;

# 6. Which item was purchased first by the customer after they became a member?
WITH cte AS
	(SELECT customer_id,
		product_id,
        product_name,
        order_date,
        join_date,
        RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rank_order
	FROM sales 
	LEFT JOIN members USING (customer_id)
	INNER JOIN menu USING (product_id)
	WHERE order_date > join_date )
SELECT customer_id, product_name 
FROM cte 
WHERE rank_order = 1;

# 7. Which item was purchased just before the customer became a member?
WITH cte AS 
	(SELECT customer_id,
		product_id,
        product_name,
        order_date,
        join_date,
        RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rank_order
	FROM sales
    LEFT JOIN members USING (customer_id)
    INNER JOIN  menu USING (product_id)
    WHERE order_date < join_date)
SELECT customer_id, product_name 
FROM cte 
WHERE rank_order = 1;

# 8. What is the total items and amount spent for each member before they became a member?
SELECT customer_id,
		COUNT(product_id) AS total_items,
		SUM(price) as amount
        FROM sales 
INNER JOIN menu USING (product_id)
LEFT JOIN members USING (customer_id)
WHERE order_date < join_date OR ISNULL(join_date)
GROUP BY customer_id;

# 9.  If each $1 spent equates to 10 points and sushi 
# has a 2x points multiplier 
# how many points would each customer have?
SELECT customer_id, 
	SUM(CASE
		WHEN product_name = "sushi" THEN price*2*10
        ELSE price*10
		END) AS total_points
FROM sales 
INNER JOIN menu USING (product_id)
GROUP BY customer_id;


# 10. In the first week after a customer joins the program (including 
# their join date) they earn 2x points on all items,not just sushi -
# how many points do customer A and B have at the end of January?
SELECT customer_id,
		SUM(CASE
        WHEN product_name = "sushi" AND datediff(order_date,join_date) >= 0 AND datediff(order_date,join_date) < 7 THEN price*4*10
		WHEN product_name = "sushi" OR (datediff(order_date,join_date) >= 0 AND datediff(order_date,join_date) < 7) THEN price*2*10
        ELSE price*10
		END) AS total_points
FROM sales 
INNER JOIN members USING (customer_id)
INNER JOIN menu USING (product_id)
WHERE order_date <= "2021-01-31" 
GROUP BY customer_id 
ORDER BY customer_id;

/* --------------------
   Bonus Questions
   --------------------*/

# Danny and his team can use to quickly derive insights without needing
# to join the tables using SQL.
# Recreate the  table with customerid,order_date,product_name,price,Member(Y/N)
# using the available data:
SELECT customer_id,order_date,product_name,price,
	CASE
		WHEN datediff(order_date,join_date) >= 0 THEN "Y"
        ELSE "N"
	END AS member
FROM sales 
INNER JOIN menu USING (product_id)
LEFT JOIN members USING (customer_id);

# Danny also requires further information about the ranking of customer 
# products, but he purposely does not need the ranking for non-member 
# purchases so he expects null ranking values for the records 
# when customers are not yet part of the loyalty program.
WITH cte AS
	(SELECT customer_id, order_date, product_name, price,
		CASE
			WHEN datediff(order_date,join_date) >= 0 THEN "Y"
			ELSE "N"
		END AS member    
	FROM sales 
	INNER JOIN menu USING (product_id)
	LEFT JOIN members USING (customer_id))
SELECT *,
		CASE member WHEN "Y" THEN 
		ROW_NUMBER() OVER (PARTITION BY customer_id,member 
				ORDER BY order_date) END rank_order
FROM cte;