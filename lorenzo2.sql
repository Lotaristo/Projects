# An SQL-code for a shipping company Lorenzo (fictional). Created a database, made some cleaning and transformating, conducted small analysis with sql. 
# Also made a dashboard with Tableau https://public.tableau.com/app/profile/al.chernyshev/viz/LorenzoShippingDashboard/Dashboard1


# 1. Database and tables creation, loading data.
  
        drop schema if exists lorenzo;
        create schema lorenzo;
        use lorenzo;

        drop table if exists city;
        create table city(
        city_id int not null primary key,
        city_name varchar(50),
        state varchar(50),
        population int,
        area float);
    
        drop table if exists customer;
        create table customer(
        cust_id int not null primary key,
        cust_name varchar(100),
        annual_revenue int,
        cust_type varchar(50),
        address varchar(255),
        city varchar (50),
        state varchar(50),
        zip int,
        phone varchar(20));
    
        drop table if exists driver;
        create table driver(
        driver_id int not null primary key,
        first_name varchar(50),
        last_name varchar(50),
        address varchar(100),
        city varchar(50),
        state varchar(50),
        zip_code int,
        phone varchar(20));
    
        drop table if exists shipment;
        create table shipment(
        ship_id int not null primary key,
        cust_id int,
        weight float,
        truck_id int,
        driver_id int,
        city_id int,
        ship_date date);
    
        drop table if exists truck;
        create table truck(
        truck_id int not null primary key,
        make varchar(20),
        model_year year);*/
    
# Next, I imported the data (using GUI that's why there is no code)
        select * from city;
   
# 2. Data Cleaning and formating
# I've already checked for null values that's why i wont' do it
    
# Checking for incorrect values
        select * from city
        join shipment sh on city.city_id=sh.city_id
        join customer cus on sh.cust_id=cus.cust_id
        join driver dr on sh.driver_id=dr.driver_id
        join truck tr on  sh.truck_id=tr.truck_id
        where population<=0 or area<=0 or weight<=0 or annual_revenue<=0;
   
# Converting phone to numbers (although there isn't much sense in it I did it for practice)
        update driver
        set phone=replace(replace(replace(replace(Phone, ')', ''), '(', ''), '-', ''), ' ', '');
   
        update customer
        set phone=replace(replace(replace(replace(Phone, ')', ''), '(', ''), '-', ''), ' ', '');
    
        alter table driver
        modify phone bigint;
    
        alter table customer
        modify phone float;
    
        select cus.phone, dr.phone from shipment sh
        join customer cus on sh.cust_id=sh.cust_id
        join driver dr on sh.driver_id=dr.driver_id;
    
# Combining customer adresses together
        alter table customer
        add column full_address varchar(255) after zip;
    
        update customer
        set full_address =  concat(state, ', ', city, ', ', address, ', ', zip);
    
# Combining first and last names of drivers
        alter table driver
        add column name varchar(100) after driver_id;
    
        update driver
        set name = concat(first_name, ' ', last_name);
    
        alter table driver
        drop column first_name,
        drop column last_name;
    
        select city_id, count(*) from city
        group by city_id
        having count(*)>1;
    
        select cust_id, annual_revenue, full_address, phone, count(*) from customer
        group by cust_id, annual_revenue, full_address, phone
        having count(*)>1;
    
        select ship_id, count(*) from shipment
        group by ship_id
        having count(*)>1;
    
# 3. Data Exploration

# Creating temporaty table to facilitate subsequent work (and view)
        drop temporary table if exists tab;
#       create or replace view as
        create temporary table tab 
        select city.city_name as city_name, city.state as state, population, area, cust_name, cust_type, annual_revenue, cus.city as cust_city, cus.state as cust_state,
        name as dr_name, dr.city as dr_city, dr.state as dr_state, weight, ship_date, make, model_year
        from city
        join shipment sh on city.city_id=sh.city_id
        join customer cus on sh.cust_id=cus.cust_id
        join driver dr on sh.driver_id=dr.driver_id
        join truck tr on  sh.truck_id=tr.truck_id;
        
        
    
# Average weight delivered by different drivers
        select dr_name, avg(annual_revenue) as avg_annual_revenue, avg(weight) as avg_weight, count(weight) as number_of_shipments from tab
        group by dr_name
        order by number_of_shipments desc;
            # As we can see, some drivers tend to deliver more weight with different value compared to others (even considering the amount of shipments),
            # it may be intrested to company.
               
# Average weight delivered by different trucks
        select  make, model_year, avg(annual_revenue) as avg_annual_revenue, avg(weight) as avg_weight, count(weight) as number_of_shipments from tab
        group by make, model_year
        order by make, model_year;
                # Considering that number of shipments is same for all except one, some trucks tend to be able to deliver more weight the others.
                # Also, considering that there are two trucks with considerable higher and lower income made on them, it may seems interesting to know why it is so.
        
# Average annual_revenue by different customers
        select  cust_name, avg(annual_revenue) as avg_annual_revenue, avg(weight) as avg_weight, count(weight) as number_of_shipments from tab
        group by cust_name
        order by avg_annual_revenue desc;
                # Looks like that annual revenue not correlated with amount or weight of shipments, there must be other factors.

# Average annual_revenue by different cities
        select  cus_state, cus_city, avg(annual_revenue) as avg_annual_revenue, avg(weight) as avg_weight, count(weight) as number_of_shipments from tab
        group by cus_state, cus_city
        order by avg_annual_revenue desc;
                # There may be some need to dig further to discover why in some cities revenue is higher and in others is lower.

# Average annual_revenue by months 
        select  ship_date, avg(annual_revenue) as avg_annual_revenue, avg(weight) as avg_weight, count(weight) as number_of_shipments from tab
        group by month(ship_date), year(ship_date)
        order by ship_date;
                # In first 3 month income varies greatly, later it seems much more stable
    
# Difference between two years
        select ship_date, sum(annual_revenue) as total_annual_revenue, sum(weight) as total_weight, count(weight) as number_of_shipments, 
        count(distinct(model_year)) as amount_of_unique_trucks, count(distinct(dr_name)) as amount_of_unique_drivers  from tab
        group by year(ship_date)
        order by ship_date;
                # The amount of unique trucks and drivers are the same, but total amount and weight of deliveries increased - I presume, that company is prosperous

# Dependence between total area of companies in different cities and amount of shipments
        select cust_name, sum(area) as total_area, avg(annual_revenue) as avg_annual_revenue, avg(weight) as avg_weight, count(weight) as number_of_shipments from tab
        group by cust_name
        order by total_area desc;
                # Although correlation between area and profit isn't visible, majority of shipments were to the companies with larger area of influence - 
                # I guess that company should pay more attention to them and increase their opportunities for shipments to these cities.

# Dependence between type of customer and proft
        select cust_type as sutomer_type, avg(annual_revenue) as avg_annual_revenue, avg(weight) as avg_weight, count(weight) as number_of_shipments from tab
        group by cust_type
        order by avg_annual_revenue desc;
                # Considering retailers and manufacturers, average revenues higher for the first ones. Also, for wholesalers amount of shipments is
                # considerably lower with almost the same income, so increasing contracts with these customers may be beneficial.













    
    
    
