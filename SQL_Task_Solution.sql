/*
TASK 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
*/

SELECT DISTINCT market 
FROM gdb023.dim_customer
WHERE region = 'APAC' AND customer = 'Atliq Exclusive';

-- ***************************************************************

/*
TASK 2. What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields,
						unique_products_2020
						unique_products_2021
						percentage_chg 
*/

SELECT
    A.unique_20 AS unique_products_2020,
    B.unique_21 AS unique_products_2021,
    ROUND((B.unique_21 - A.unique_20) * 100 / A.unique_20, 2) AS percentage_change
FROM 
    (SELECT COUNT(DISTINCT product_code) AS unique_20
     FROM gdb023.fact_sales_monthly
     WHERE fiscal_year = 2020) A,
    (SELECT COUNT(DISTINCT product_code) AS unique_21
     FROM gdb023.fact_sales_monthly
     WHERE fiscal_year = 2021) B;

-- ********************************************************************

/*
Task 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
The final output contains 2 fields, 
					segment
                    product_count			
*/

SELECT 
    segment, 
    COUNT(DISTINCT product_code) AS product_count
FROM gdb023.dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- **************************************************************

/*
TASK 4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
				segment
				product_count_2020
				product_count_2021
				difference
*/

WITH temp_table AS (
    SELECT 
        p.segment,
        s.fiscal_year,
        COUNT(DISTINCT s.Product_code) AS product_count
    FROM 
        gdb023.fact_sales_monthly s
        JOIN gdb023.dim_product p ON s.product_code = p.product_code
    GROUP BY 
        p.segment,
        s.fiscal_year
)
SELECT 
    up_2020.segment,
    up_2020.product_count AS product_count_2020,
    up_2021.product_count AS product_count_2021,
    up_2021.product_count - up_2020.product_count AS difference
FROM 
    temp_table AS up_2020
JOIN 
    temp_table AS up_2021
ON 
    up_2020.segment = up_2021.segment
    AND up_2020.fiscal_year = 2020 
    AND up_2021.fiscal_year = 2021
ORDER BY 
    difference DESC;

-- *******************************************************************

/*
TASK 5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
							product_code
							product
							manufacturing_cost
*/

SELECT 
    F.product_code, 
    P.product, 
    F.manufacturing_cost 
FROM 
    gdb023.fact_manufacturing_cost F 
JOIN 
    gdb023.dim_product P ON F.product_code = P.product_code
WHERE 
    F.manufacturing_cost IN (
        SELECT MAX(manufacturing_cost) 
        FROM gdb023.fact_manufacturing_cost
        UNION
        SELECT MIN(manufacturing_cost) 
        FROM gdb023.fact_manufacturing_cost
    ) 
ORDER BY 
    F.manufacturing_cost DESC;

-- ********************************************

/*
TASK 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
The final output contains these fields,
				customer_code
				customer
				average_discount_percentage
*/

WITH Table1 AS (
    SELECT 
        customer_code AS A, 
        AVG(pre_invoice_discount_pct) AS B 
    FROM 
        gdb023.fact_pre_invoice_deductions
    WHERE 
        fiscal_year = '2021'
    GROUP BY 
        customer_code
),
Table2 AS (
    SELECT 
        customer_code AS C, 
        customer AS D 
    FROM 
        gdb023.dim_customer
    WHERE 
        market = 'India'
)

SELECT 
    Table2.C AS customer_code, 
    Table2.D AS customer, 
    ROUND(Table1.B, 4) AS average_discount_percentage
FROM 
    Table1 
JOIN 
    Table2 ON Table1.A = Table2.C
ORDER BY 
    average_discount_percentage DESC
LIMIT 5;

-- *********************************************

/*
TASK 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.The final report contains these columns:
						Month
						Year
						Gross sales Amount
*/
WITH temp_table AS (
    SELECT 
        customer,
        monthname(date) AS months,
        month(date) AS month_number,
        year(date) AS year,
        (sold_quantity * gross_price) AS gross_sales
    FROM 
        gdb023.fact_sales_monthly s 
        JOIN gdb023.fact_gross_price g ON s.product_code = g.product_code
        JOIN gdb023.dim_customer c ON s.customer_code = c.customer_code
    WHERE 
        customer = 'Atliq exclusive'
)
SELECT 
    months, 
    year, 
    CONCAT(ROUND(SUM(gross_sales) / 1000000, 2), 'M') AS gross_sales 
FROM 
    temp_table
GROUP BY 
    year, 
    months, 
    month_number
ORDER BY 
    year, 
    month_number;

-- ************************************************

/*
TASK 8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
			Quarter
			total_sold_quantity
*/

SELECT 
    CASE
        WHEN date BETWEEN '2019-09-01' AND '2019-11-01' THEN 1  
        WHEN date BETWEEN '2019-12-01' AND '2020-02-01' THEN 2
        WHEN date BETWEEN '2020-03-01' AND '2020-05-01' THEN 3
        WHEN date BETWEEN '2020-06-01' AND '2020-08-01' THEN 4
    END AS Quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM 
    gdb023.fact_sales_monthly
WHERE 
    fiscal_year = 2020
GROUP BY 
    Quarters
ORDER BY 
    total_sold_quantity DESC;

-- ********************************************************

/*
TASK 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
							channel
							gross_sales_mln
							percentage
*/

WITH temp_table AS (
      SELECT 
          c.channel,
          SUM(s.sold_quantity * g.gross_price) AS total_sales
      FROM
          gdb023.fact_sales_monthly s 
      JOIN 
          gdb023.fact_gross_price g ON s.product_code = g.product_code
      JOIN 
          gdb023.dim_customer c ON s.customer_code = c.customer_code
      WHERE 
          s.fiscal_year = 2021
      GROUP BY 
          c.channel
      ORDER BY 
          total_sales DESC
)
SELECT 
    channel,
    ROUND(total_sales / 1000000, 2) AS gross_sales_in_millions,
    CONCAT(ROUND(total_sales / (SUM(total_sales) OVER()) * 100, 2), ' %') AS percentage 
FROM 
    temp_table ;

-- ****************************************************************

/*
TASK 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
										division
										product_code
										product
										total_sold_quantity
										rank_order
*/ 

WITH temp_table AS (
    SELECT 
        s.product_code, 
        p.division,
        CONCAT(p.product, "(", p.variant, ")") AS product,
        SUM(sold_quantity) AS total_sold_quantity
    FROM
        gdb023.fact_sales_monthly s
    JOIN 
        gdb023.dim_product p ON s.product_code = p.product_code
    WHERE 
        fiscal_year = 2021
    GROUP BY 
        s.product_code, 
        p.division, 
        CONCAT(p.product, "(", p.variant, ")")
)
SELECT 
    division, 
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM (
    SELECT *,
        RANK() OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
    FROM temp_table
) AS ranked_data
WHERE 
    rank_order IN (1,2,3);

-- ***************************************************************************