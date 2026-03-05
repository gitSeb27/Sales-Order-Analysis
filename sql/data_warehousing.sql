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
