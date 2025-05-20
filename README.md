# Advanced Data Analytics Project Using SQL

## Project Overview
This project showcases advanced SQL techniques applied to a hypothetical retail sales dataset to uncover insights related to sales trends, customer behavior, and product performance. It includes step-by-step data exploration, segmentation, and reporting logic structured for business intelligence applications.

Developed by **Mason Hollis**, this project leverages real-world SQL practices such as CTEs, window functions, and view creation to support data-driven decision-making.

---

## Key Features

- **Time Series Analysis**  
  Analyze monthly sales trends using `YEAR`, `MONTH`, `DATETRUNC`, and `FORMAT` functions.

- **Cumulative & Moving Metrics**  
  Calculate running totals and moving averages using SQL window functions like `SUM OVER()` and `AVG OVER()`.

- **Product Performance Benchmarking**  
  Compare each product's current sales with its historical average and previous year’s performance using `LAG()` and `AVG()`.

- **Part-to-Whole Contribution**  
  Evaluate how much each product category contributes to total sales with share-of-total logic.

- **Customer & Product Segmentation**  
  Group customers by lifetime value and engagement, and categorize products by cost ranges and performance tiers.

- **Business-Ready Reporting Views**  
  Build reusable SQL views for customer and product dashboards, including key metrics like AOV, lifespan, recency, and segmentation labels.

---

## SQL Modules

### STEP 1: Change-Over Time Trends
- Monthly sales, customer counts, and quantity sold
- Grouping by `YEAR/MONTH`, `DATETRUNC(month)`, and `FORMAT(order_date, 'yyyy-MMM')`

### STEP 2: Cumulative Analysis
- Running totals of sales and moving average prices across months using window functions

### STEP 3: Product Performance Analysis
- Yearly sales compared to averages and previous years using `LAG()` and `AVG() OVER`

### STEP 4: Part-to-Whole Analysis
- Total sales by product category and percentage contribution to overall sales

### STEP 5: Data Segmentations
- Products bucketed into cost ranges
- Customers classified into **VIP**, **Regular**, and **New** segments based on spending and engagement

### STEP 6: Customer Report View
Creates a view `gold.report_customer` summarizing:
- Age, lifespan, total orders, sales, quantity, product diversity
- Customer segment (VIP/Regular/New)
- KPIs: `avg_order_value`, `avg_monthly_spend`, `recency`

### STEP 7: Product Report View
Creates a view `gold.report_product` summarizing:
- Product category, sales volume, quantity, customer reach, cost
- Product segment (High, Mid-Range, Low Performer)
- KPIs: `avg_order_revenue`, `avg_monthly_revenue`, `recency_in_months`

---

## Technologies Used

- **SQL (T-SQL syntax)**
- **Window Functions**
- **Common Table Expressions (CTEs)**
- **Aggregate Functions**
- **Date Functions**

---

## 📂 File Usage

Run the full SQL script (`AdvancedAnalyticsProject.sql`) sequentially in your SQL environment connected to the following base tables:

- `gold.fact_sales`
- `gold.dim_products`
- `gold.dim_customers`

Ensure proper permissions for creating views in the `gold` schema.

---

## Author

**Mason Hollis**   
May 2025 Graduate – B.S. in Business Information Technology  

---

##  License

This project is for educational and portfolio use. All logic is original and intended to demonstrate SQL capabilities for data analytics roles.
