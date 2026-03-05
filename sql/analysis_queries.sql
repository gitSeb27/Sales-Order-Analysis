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
