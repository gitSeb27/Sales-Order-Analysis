create table proiect_vanzari
(   row_id int,
    order_id varchar(20),
    order_date date,
    ship_date date,
    ship_mode varchar(20),
    customer_id varchar(20),
    customer_name varchar(100),
    segment varchar(20),
    country varchar(50),
    city varchar(50),
    state varchar(50),
    postal_code varchar(20),
    region varchar(20),
    product_id varchar(20),
    category varchar(50),
    sub_category varchar(50),
    product_name varchar(150),
    sales decimal(10, 2),
    quantity int,
    discount decimal(4, 2),
    profit decimal(10, 4)
)
;



create table dimensiune_produs
(  
    product_key int auto_increment primary key,
    product_id varchar(20),
    product_name varchar(150),
    category varchar(50),
    sub_category varchar(50)
);

insert into dimensiune_produs
(
	product_id, 
	product_name, 
	category, 
	sub_category
)
select
    product_id,
    min(product_name),
    min(category),
    min(sub_category)
from proiect_vanzari
group by product_id;
;



create table dimensiune_client
(  
    customer_key int auto_increment primary key,
    customer_id varchar(20),
    customer_name varchar(100),
    segment varchar(20)
);

insert into dimensiune_client
(
    customer_id,
    customer_name,
    segment
)
select distinct
    customer_id,
    customer_name,
    segment
from proiect_vanzari;
;


create table dimensiune_locatie
(  
    location_key int auto_increment primary key,
    country varchar(50),
    city varchar(50),
    state varchar(50),
    postal_code varchar(20),
    region varchar(20)
);

insert into dimensiune_locatie
(
    country,
    city,
    state,
    postal_code,
    region
)
select distinct
    country,
    city,
    state,
    postal_code,
    region
from proiect_vanzari;
;

create table dimensiune_data_comanda
(  
    date_key int primary key,
    full_date date,
    date_year int,
    date_month int
);

insert into dimensiune_data_comanda 
select distinct
    year(order_date)*10000 + month(order_date) * 100 +day(order_date),
    order_date,
    year(order_date),
    month(order_date)
    
from proiect_vanzari

union select distinct
	year(ship_date)*10000 + month(ship_date) * 100 +day(ship_date),
    ship_date,
    year(ship_date),
    month(ship_date)
    from proiect_vanzari
;


create table fact_table (
	fact_key int auto_increment primary key,
    order_id varchar(20),
    customer_key int,
    product_key int,
    order_date_key int,
    ship_date_key int,
    location_key int,
    sales decimal(10,2),
    quantity int,
    discount decimal(5, 2),
    profit decimal(10, 4),

    foreign key (customer_key) references dimensiune_client(customer_key),
    foreign key (product_key) references dimensiune_produs(product_key),
    foreign key (order_date_key) references dimensiune_data_comanda(date_key),
    foreign key (ship_date_key) references dimensiune_data_comanda(date_key),
    foreign key (location_key) references dimensiune_locatie(location_key)
);

insert into fact_table (
    order_id, 
    customer_key, 
    product_key, 
    order_date_key, 
    ship_date_key, 
    location_key, 
    sales, 
    quantity, 
    discount, 
    profit
)
select
    r.order_id,
    c.customer_key,
    p.product_key,
    YEAR(r.order_date)*10000 + MONTH(r.order_date)*100 + DAY(r.order_date),
    YEAR(r.ship_date)*10000 + MONTH(r.ship_date)*100 + DAY(r.ship_date),
    l.location_key,
    r.sales,
    r.quantity,
    r.discount,
    r.profit
from proiect_vanzari as r
join dimensiune_client as c on r.customer_id = c.customer_id
join dimensiune_produs as p on r.product_id = p.product_id
join dimensiune_locatie as l on r.postal_code = l.postal_code and r.city = l.city and r.state = l.state;

-- monthly sales trend
select 
	d.date_year as "Year", 
	d.date_month as "Month", 
	sum(f.sales) as "Total sales"
from fact_table as f
join dimensiune_data_comanda as d 
on f.order_date_key = d.date_key
group by d.date_year, d.date_month
order by d.date_year, d.date_month;

-- yearly sales trend
select
    d.date_year as "Year", 
    sum(f.sales) as "Total sales"
from fact_table as f
join dimensiune_data_comanda as d
on f.order_date_key = d.date_key
group by d.date_year
order by d.date_year;

-- sales and profit by category and sub-category
select 
	p.category, 
	p.sub_category, 
    sum(f.sales) as total_sales, 
	sum(f.profit) as total_profit, 
    sum(f.profit)/sum(f.sales)*100 as profit_margin
from fact_table as f
join dimensiune_produs as p 
on f.product_key = p.product_key
group by p.category, p.sub_category 
order by p.category, total_sales desc;

-- top 5 products by profit
select 
	p.product_name as "Product name", 
    sum(f.sales) as "Total sales", 
    sum(f.profit) as total_profit
from fact_table as f
join dimensiune_produs as p 
on f.product_key = p.product_key
group by p.product_name 
order by total_profit desc limit 5;

-- top 10 customers by revenue
select 
	c.customer_name as "Customer name", 
    c.segment as "Segment", 
    sum(f.sales) as total_sales,
    sum(f.profit) as total_profit
from fact_table as f
join dimensiune_client as c 
on f.customer_key = c.customer_key
group by c.customer_name, c.segment 
order by total_sales desc limit 10;

-- sales and profit by region
select 
	l.region as "Region", 
    sum(f.sales) as total_sales, 
    sum(f.profit) as total_profit
from fact_table as f
join dimensiune_locatie as l 
on f.location_key = l.location_key
group by l.region
order by total_sales desc;

-- top 10 cities by sales

select
	l.city as "City",
    sum(f.sales) as total_sales
from fact_table as f
join dimensiune_locatie as l
on f.location_key = l.location_key
group by l.city
order by total_sales desc limit 10;

-- states selling at a loss
select 
    l.state,
    sum(f.sales) as total_sales,
    sum(f.profit) as total_profit
from fact_table as f
join dimensiune_locatie as l on f.location_key = l.location_key
group by l.state
having total_profit < 0
order by total_profit asc;

-- products selling at a loss
select 
	p.product_name, 
    sum(f.profit) as total_profit
from fact_table as f
join dimensiune_produs as p 
on f.product_key = p.product_key
group by p.product_name 
having total_profit < 0 
order by total_profit asc;

-- sales by segment 
select 
	c.segment, 
    count(distinct f.order_id) as "Number of orders",
    sum(f.sales) as "Total sales", 
    sum(f.profit) as "Total profit"
from fact_table as f
join dimensiune_client as c 
on f.customer_key = c.customer_key
group by c.segment;

-- discount impact on profits
select 
    case 
        when f.discount = 0 then "No discount"
        when f.discount <= 0.2 then "1-20%"
        when f.discount <= 0.4 then "20-40%"
        when f.discount <= 0.6 then "40-60%"
        else "60%+" 
    end as discount_range,
    count(*) as "Orders",
    round(avg(f.profit), 2) as "Profit average",
    sum(f.sales) as "Total sales"
from fact_table as f
group by discount_range;

-- monthly impact on sales
select 
    d.date_month,
    round(avg(monthly_sales), 2) as avg_sales
from (
    select 
        d.date_month,
        d.date_year,
        sum(f.sales) as monthly_sales
    from fact_table f
    join dimensiune_data_comanda d on f.order_date_key = d.date_key
    group by d.date_year, d.date_month
) as monthly
join dimensiune_data_comanda d on monthly.date_month = d.date_month
group by d.date_month
order by avg_sales desc;
