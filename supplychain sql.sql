CREATE TABLE supplychain (
    Warehouse_ID VARCHAR(10),
    Location VARCHAR(100),
    Current_Stock INT,
    Demand_Forecast INT,
    Lead_Time_Days INT,
    Shipping_Time_Days INT,
    Stockout_Risk INT,
    Operational_Cost NUMERIC(12,2),
    Supplier_ID VARCHAR(10),
    Product_Category VARCHAR(50),
    Monthly_Sales INT,
    Order_Processing_Time FLOAT,
    Return_Rate FLOAT,
    Customer_Rating FLOAT,
    Warehouse_Capacity INT,
    Storage_Cost NUMERIC(12,2),
    Transportation_Cost NUMERIC(12,2),
    Backorder_Quantity INT,
    Damaged_Goods INT,
    Employee_Count INT
);
select * from supplychain

slowest warehouses...

SELECT Warehouse_ID, location, 
       AVG(Shipping_Time_Days) AS avg_shipping_days, 
       COUNT(*) AS shipments
FROM supplychain
GROUP BY Warehouse_ID, location
ORDER BY avg_shipping_days DESC
LIMIT 20;

Stockout risk by warehouse (how many items at risk)......

SELECT Warehouse_ID, 
        SUM(CASE WHEN Current_Stock < Demand_Forecast THEN 1 ELSE 0 END) AS items_at_risk,
       SUM(CASE WHEN Current_Stock < Demand_Forecast THEN (Demand_Forecast - Current_Stock) ELSE 0 END) AS units_short
FROM supplychain
GROUP BY Warehouse_ID
ORDER BY units_short DESC;

stockout risk by product.....

SELECT 
    Product_Category,
    SUM(CASE WHEN Current_Stock < Demand_Forecast THEN 1 ELSE 0 END) AS products_at_risk,
    SUM(CASE WHEN Current_Stock < Demand_Forecast THEN (Demand_Forecast - Current_Stock) ELSE 0 END) AS total_units_short
FROM supplychain
GROUP BY Product_Category
ORDER BY total_units_short DESC;


Warehouses with Delays.......

SELECT Warehouse_ID, Location, AVG(Shipping_Time_Days) AS avg_days
FROM supplychain
WHERE Shipping_Time_Days > 6
GROUP BY Warehouse_ID, Location
ORDER BY avg_days DESC;

Compare Shipping Time vs Customer Rating.......

SELECT Warehouse_ID, Location,
    AVG(Shipping_Time_Days) AS avg_shipping_time,
    AVG(Customer_Rating) AS avg_rating
FROM supplychain
GROUP BY Warehouse_ID, location
order by avg_rating desc;

check stock utilization........

SELECT Warehouse_ID, Location,
       (Current_Stock / (Monthly_Sales / 30.0)) AS days_of_supply
FROM supplychain
ORDER BY days_of_supply ASC;

How many days current stock will last — lower values mean stock may run out soon...

SELECT Warehouse_ID, Location,
       Current_Stock,
       Warehouse_Capacity,
       ROUND((Current_Stock * 1.0 / Warehouse_Capacity) * 100) AS capacity_used_percent
FROM supplychain
ORDER BY capacity_used_percent DESC;

Warehouses with Stockout Risk...........

SELECT Warehouse_ID, Location, Stockout_Risk, Current_Stock
FROM supplychain
WHERE Stockout_Risk > (
    SELECT AVG(Stockout_Risk) FROM supplychain
)
ORDER BY Stockout_Risk DESC;

Average Monthly Sales by Product Category......

SELECT Product_Category,
       AVG(Monthly_Sales)  AS avg_sales
FROM supplychain
GROUP BY Product_Category
ORDER BY avg_sales DESC;

relation Between Demand and Returns......

SELECT Product_Category,
       (AVG(Demand_Forecast)) AS avg_demand,
       (AVG(Return_Rate)) AS avg_return_rate
FROM supplychain
GROUP BY Product_Category
ORDER BY avg_return_rate DESC;

Total operational cost by warehouse....

SELECT Warehouse_ID, Location,
       SUM(Operational_Cost + Storage_Cost + Transportation_Cost) AS total_cost
FROM supplychain
GROUP BY Warehouse_ID, Location
ORDER BY total_cost DESC;

Backorder and damaged products....

SELECT warehouse_id, SUM(backorder_quantity) AS backorders, SUM(damaged_goods) AS damaged
FROM warehouse_data_cl
GROUP BY warehouse_id
ORDER BY backorders DESC;

Top 10 Largest distance Locations......

SELECT
    Location,
    AVG(Lead_Time_Days + Shipping_Time_Days) AS avg_distance_days
FROM supplychain
GROUP BY Location
ORDER BY avg_distance_days DESC
LIMIT 10;


Largest distance Warehouses......

WITH location_distance AS (
    SELECT
        Location,
        AVG(Lead_Time_Days + Shipping_Time_Days) AS avg_distance
    FROM supplychain
    GROUP BY Location
),
overall_avg AS (
    SELECT AVG(avg_distance) AS overall_avg
    FROM location_distance
)
SELECT
    ld.Location,
    ld.avg_distance,
    CASE
        WHEN ld.avg_distance > oa.overall_avg
        THEN 'Large Distance'
        ELSE 'Normal Distance'
    END AS distance_category
FROM location_distance ld
CROSS JOIN overall_avg oa
ORDER BY ld.avg_distance DESC;

 Warehouses where workforce should reduce.......
 
WITH warehouse_metrics AS (
    SELECT
        Warehouse_ID,
        Location,
        SUM(Monthly_Sales) / NULLIF(AVG(Employee_Count), 0) AS sales_per_employee,
        SUM(Operational_Cost) / NULLIF(AVG(Employee_Count), 0) AS cost_per_employee
    FROM supplychain
    GROUP BY Warehouse_ID, Location
),
benchmarks AS (
    SELECT
        AVG(sales_per_employee) AS avg_sales_per_employee,
        AVG(cost_per_employee) AS avg_cost_per_employee
    FROM warehouse_metrics
)
SELECT
    wm.*
FROM warehouse_metrics wm
CROSS JOIN benchmarks b
WHERE wm.cost_per_employee > b.avg_cost_per_employee
  AND wm.sales_per_employee < b.avg_sales_per_employee
ORDER BY wm.cost_per_employee DESC;




