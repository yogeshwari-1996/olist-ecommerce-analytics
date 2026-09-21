CREATE SCHEMA olist;

select schema_name 
from information_schema.schemata
where schema_name = 'olist';


--- Customer table ----
Create table olist.customers(
customer_id varchar(100) primary key,
customer_unique_id varchar(100) not null,
customer_zip_code_prefix int,
customer_city varchar(100),
customer_state varchar(100)
);


--- Orders Table ----
Create table olist.orders(
order_id varchar(100) Primary key,
customer_id varchar(100) not null,
order_status varchar (100) not null,
order_purchase_timestamp timestamp,
order_approved_at timestamp,
order_delivered_carrier_date timestamp,
order_delivered_customer_date timestamp,
order_estimated_delivery_date timestamp,

CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES olist.customers(customer_id)
);


----------Seller Table --------------
Create table olist.sellers(
seller_id varchar(100) primary key,
seller_zip_code_prefix int,
seller_city varchar(100),
seller_state varchar(100)
);


-----Products Table----
Create table olist.products(
product_id varchar(50) primary key,
product_category_name varchar(50),
product_name_lenght int,
product_description_lenght int,
product_photos_qty int,
product_weight_g int,
product_length_cm int,
product_height_cm int,
product_width_cm int
);


----Product Category---
Create table olist.product_category_translation(
product_category_name varchar(100) Primary Key,
product_category_name_english varchar(100) not null
);


------Order Items---
Create table olist.Order_items(
order_id varchar(100) Not null,
order_item_id int not null,
product_id varchar(100) not null,
seller_id varchar(100) not null,

shipping_limit_date timestamp,
price numeric(12,2),
freight_value numeric(12,2),

Primary Key(Order_id, order_item_id),

CONSTRAINT fk_items_order
        FOREIGN KEY (order_id)
        REFERENCES olist.orders(order_id),

    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id)
        REFERENCES olist.products(product_id),

    CONSTRAINT fk_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES olist.sellers(seller_id)
);


------Payments Table----
Create table olist.payments(
order_id varchar(100) not null,
payment_sequential int not null,
payment_type varchar(50),
payment_installments int,
payment_value numeric(12,2),

PRIMARY KEY(order_id, payment_sequential),

Constraint fk_payments_order
Foreign Key (order_id)
references olist.orders(order_id)
);


-----Reviews-------
Create table olist.order_reviews(
review_id varchar(50) not null,
order_id varchar(100) not null,
review_score int not null,
review_comment_title Text,
review_comment_message text,
review_creation_date timestamp,
review_answer_timestamp timestamp,

Primary Key(review_id, order_id),

  CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES olist.orders(order_id),

    CONSTRAINT chk_review_score
        CHECK (review_score BETWEEN 1 AND 5)
);


---Geolocation table ----------
CREATE TABLE olist.geolocation (
    geolocation_id BIGSERIAL PRIMARY KEY,

    geolocation_zip_code_prefix INT NOT NULL,
    geolocation_lat NUMERIC(10,7),
    geolocation_lng NUMERIC(10,7),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);





---Display Tables---
select table_schema,
table_name,
table_type 
from information_schema.tables
where table_schema ='olist'
order by table_name;


SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'olist'
ORDER BY
    table_name,
    ordinal_position;

------Create Indexes---------
Create index idx_ordes_customer_id
on olist.orders(customer_id);

create index idx_order_items_product_id
on olist.order_items(product_id);

Create index idx_order_items_seller_id
on olist.order_items(seller_id);

Create index idx_order_items_order_id
on olist.order_items(Order_id);

Create index idx_payments_order_id
on olist.payments(Order_id);

Create index idx_reviews_order_id
on olist.payments(Order_id);

create index idx_customers_state
on olist.customers(customer_state);

Create index idx_grolocation_zip
on olist.geolocation(geolocation_zip_code_prefix);




TRUNCATE TABLE olist.geolocation RESTART IDENTITY;

-- Confirm the total number of records
SELECT COUNT(*) AS total_rows
FROM olist.geolocation;


-- Check a few imported records
SELECT *
FROM olist.geolocation
LIMIT 10;


SELECT COUNT(*) FROM olist.orders;

SELECT *
FROM olist.orders
WHERE order_id = '00010242fe8c5a6d1ba2dd792cb16214';


SELECT COUNT(*) FROM olist.products;

SELECT COUNT(*) FROM olist.sellers;
SELECT COUNT(*) FROM olist.orders;


------- Check how many rows were imported into each table----
Select 'customers' as table_name, count(*) as row_count from olist.customers
union all 
select 'orders', count(*) from olist.orders
union all
select 'order_items', count(*) from olist.order_items
union all
select 'payments', count(*) from olist.payments
union all
select 'order_reviews', count(*) from olist.order_reviews
union all
select 'products', count(*) from olist.products
union all
select 'products', count(*) from olist.products
union all
select 'sellers', count(*) from olist.sellers
union all
select 'geolocation', count(*) from olist.geolocation
union all
select 'product_category_translation', count(*) as row_count from olist.product_category_translation;

----primary key duplicates----

---Customers---
select customer_id, count(*)
from olist.customers
group by customer_id
having count(*)>1;


---Orders--
select order_id, count(*)
from olist.orders
group by order_id
having count(*)>1;

--Products---
select product_id, count(*)
from olist.products
group by product_id
having count(*)>1;

---Sellers---
select seller_id, count(*)
from olist.sellers
group by seller_id
having count(*)>1;

------Check broken foreign-key relationships----
select o.order_id, o.customer_id
from olist.orders o
left join olist.customers c
on o.customer_id = c.customer_id
where c.customer_id is null;


SELECT oi.product_id
FROM olist.order_items oi
LEFT JOIN olist.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT oi.seller_id
FROM olist.order_items oi
LEFT JOIN olist.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- Check NULLs in critical order fields
SELECT
    COUNT(*) AS total_orders,
    COUNT(order_id) AS order_ids,
    COUNT(customer_id) AS customer_ids,
    COUNT(order_status) AS order_statuses,
    COUNT(order_purchase_timestamp) AS purchase_dates
FROM olist.orders;

---How much Revenue does the business gemerate---
---calculate total revenue from all order items---

select round(sum(price),2) as Total_revenue
from olist.order_items;


---How many orders were placed---
select count(distinct Order_id) As total_orders
from olist.orders;


--What is the average Order Value?---
select 
round(sum(price)/count(distinct Order_id),
2)
as average_order_value
from olist.order_items;


--Monthly sales Trends---
select
Date_Trunc('month',o.order_purchase_timestamp) as month,
count(distinct oi.order_id) as total_orders,
round(sum(oi.price),2) as revenue
from olist.orders o
join olist.order_items oi
on o.order_id = oi.order_id
group by 1
order by 1;

----Which product categories generate the most revenue?--
select
pct.product_category_name_english as category,
round(sum(oi.price),2) as revenue
from olist.order_items oi
join olist.products p
on oi.product_id = p.product_id
join olist.product_category_translation pct
on p.product_category_name = pct.product_category_name
group by pct.product_category_name_english
order by revenue desc;

-----Which categories have the highest number of orders?---
select 
pct.product_category_name_english as category,
count(distinct oi.order_id) as total_orders
from olist.order_items oi
join olist.products p
on oi.product_id = p.product_id
join olist.product_category_translation pct
on p.product_category_name = pct.product_category_name
group by pct.product_category_name_english
order by total_orders desc;

-----Who are the top 10 sellers by revenue?---
select 
seller_id,
round(sum(price),2) as revenue,
count(distinct order_id) as total_orders
from olist.order_items
group by seller_id
order by revenue desc
limit 10;

------What payment methods do customers prefer?---
select 
payment_type,
count(*) as payment_count,
round(sum(payment_value),2) as total_payment_value
from olist.payments
group by payment_type
order by total_payment_value desc;


------What is the average customer review score?---
select
round(avg(review_score),2) as average_review_score
from olist.order_reviews;


----Does delivery performance affect customer satisfaction?---
select 
case 
when o.order_delivered_customer_date <= o.order_estimated_delivery_date
then 'On Time'
else 'Late'
end as delivery_status,

count(distinct o.order_id) as total_orders,
round(avg(r.review_score),2) as average_review_score

from olist.orders o
join olist.order_reviews r
on o.order_id = r.order_id

where o.order_delivered_customer_date is not null
and o.order_estimated_delivery_date is not null

group by 1
order by average_review_score desc;


----Row Number----
SELECT
    c.customer_unique_id,
    o.order_id,
    o.order_purchase_timestamp,
    ROW_NUMBER() OVER (
        PARTITION BY c.customer_unique_id
        ORDER BY o.order_purchase_timestamp
    ) AS purchase_number
FROM olist.orders AS o
JOIN olist.customers AS c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';


------Rank-----
WITH seller_revenue AS (
    SELECT
        seller_id,
        SUM(price) AS revenue
    FROM olist.order_items
    GROUP BY seller_id
)
SELECT
    seller_id,
    ROUND(revenue, 2) AS revenue,
    RANK() OVER (
        ORDER BY revenue DESC
    ) AS seller_rank
FROM seller_revenue
ORDER BY seller_rank;


---denserank----
WITH product_revenue AS (
    SELECT
        pct.product_category_name_english AS category,
        oi.product_id,
        SUM(oi.price) AS revenue
    FROM olist.order_items AS oi
    JOIN olist.products AS p
        ON oi.product_id = p.product_id
    JOIN olist.product_category_translation AS pct
        ON p.product_category_name = pct.product_category_name
    GROUP BY 1, 2
)
SELECT
    category,
    product_id,
    ROUND(revenue, 2) AS revenue,
    DENSE_RANK() OVER (
        PARTITION BY category
        ORDER BY revenue DESC
    ) AS product_rank
FROM product_revenue
ORDER BY category, product_rank;


-----Lag()----
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
        SUM(oi.price) AS revenue
    FROM olist.orders AS o
    JOIN olist.order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS previous_month_revenue,
    ROUND(
        revenue - LAG(revenue) OVER (ORDER BY month),
        2
    ) AS revenue_difference
FROM monthly_revenue
ORDER BY month;



---sum over()---
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
        SUM(oi.price) AS revenue
    FROM olist.orders AS o
    JOIN olist.order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(revenue) OVER (ORDER BY month),
        2
    ) AS running_revenue
FROM monthly_revenue
ORDER BY month;


















