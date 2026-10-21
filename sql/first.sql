USE london_property;
SELECT COUNT(*) FROM sales;
SELECT YEAR(date_of_transfer) AS yr, COUNT(*) AS sales
FROM sales GROUP BY yr ORDER BY yr;