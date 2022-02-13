# An SQL-code for well-known Superstore dataset. Created a database, made some cleaning, add some code for basic analysis. 
# Also made a Dashboard with Power BI (for some reason map doesn't work).

# 1.Creating database, table and filling it with data from csv file
	commit;

	create database shop_project;
	use shop_project;

	drop table if exists shop;
	create table shop(
	ship_mode varchar(255),
	segment varchar(255),
	country varchar(255),
	city varchar(255),
	state varchar(255),
	postal_code int(6),
	region varchar(255),
	category varchar(255),
	subcategory varchar(255),
	sales float,
	quantity int,
	discount float,
	profit float,
	id int not null auto_increment primary key);

	LOAD DATA LOCAL INFILE 'C:/Users/user/Desktop/SampleSuperstore.csv' 
	INTO TABLE shop 
	FIELDS TERMINATED BY ',' 
	LINES TERMINATED BY '\n' 
	IGNORE 1 ROWS;

	alter table shop 
	change id id int not null first;

	select * from shop;


# 2. Cleaning dataset

# Checking for incorrect values
	select distinct(ship_mode) from shop;
	select distinct(segment) from shop;
	select distinct(country) from shop; # only USA
	select distinct(category) from shop;
	select distinct(subcategory) from shop;
	select distinct(region) from shop;
	select distinct(city) from shop;  # everything seems correct

	select * from shop where sales<=0 or quantity <=0 or discount<0 or profit<=0; # for some reason there are entries with negative and zero values in profit column, 
																			      # i'm not sure that it has to be so that's why i decided to correct it
    update shop
    set profit=round(abs(profit),3)
    where profit<0;		# update column and changed values to positive
    
    select * from shop where sales<=0 or quantity <=0 or discount<0 or profit<=0; # there are still entries with zero profit, because i'm not sure how to 
																				  # calculate them i'll delete them
	delete from shop
    where profit=0;
    
    select * from shop where sales<=0 or quantity <=0 or discount<0 or profit<=0; # everthing seems normal now

# Checking for duplicates
	select ship_mode, segment, city, state, postal_code, subcategory, sales, quantity, discount, profit, count(*) from shop 
	group by ship_mode, segment, city, state, postal_code, subcategory, sales, quantity, discount, profit
	having count(*) > 1; # Although we've got 17 entries we're unable to know if they were really duplicates or not.
		
# Checking for missing values
	select ship_mode, subcategory, sales, quantity, discount, profit from shop
    where ship_mode is null or subcategory is null or sales is null or quantity is null or profit is null;
		# although we didn't inspected every columns, the most important columns are ok (and anyway i checked it by eye arlier)

# 3. Exploration (and creating some views)

# Average and total sums
	create or replace view avg_sum as
	select round(sum(sales),2) as total_sales, round(sum(profit),2) as total_profit, round(avg(sales),2) as average_sales,
	round(avg(profit),2) as average_profit, round(avg(discount),2) as average_discount, round((sum(profit)/sum(sales)*100),2) as profit_ratio from shop;

# Top 20 cities by average profit
	select state, city, round(avg(profit),2) as avg_profit from shop
	group by state, city
	order by avg_profit desc
	limit 20;
    
# Average profit by regions
	select region, round(avg(profit),2) as avg_profit from shop
    group by region
    order by avg_profit desc;
    
# Average profit by shipments
	select ship_mode, round(avg(profit),2) as avg_profit from shop
    group by ship_mode
    order by avg_profit desc;
    
# Average profit, quantity and discount by categories
	create or replace view avg_category as
	select category, subcategory, round(avg(profit), 2) as avg_profit, round(avg(quantity),2), round(avg(discount), 3)  from shop
    group by category, subcategory
    order by avg_profit desc;

# For visualisations I decided to transfer data to Power BI.





