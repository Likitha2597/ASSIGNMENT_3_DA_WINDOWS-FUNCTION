use sakila;

-- 1. **Rank the customers based on the total amount they've spent on rentals.**

select c.customer_id,
concat(c.first_name,' ', c.last_name) as customer_name,
sum(p.amount) as total_amount_spent
from customer c 
join payment p on c.customer_id=p.customer_id
group by c.customer_id
order by total_amount_spent desc;

-- 2. **Calculate the cumulative revenue generated by each film over time.**

select f.film_id,
f.title as film_title,
p.payment_date,
sum(p.amount) over(partition by f.film_id order by p.payment_date) as cumulative_revenue
from film f
join inventory i on f.film_id= i.film_id
join rental r on i.inventory_id= r.inventory_id
join payment p on r.rental_id= p.rental_id
order by f.film_id, p.payment_date;

-- 3. **Determine the average rental duration for each film, considering films with similar lengths.**

select f.film_id,
f.title as film_titile,
f.rental_duration,
round(avg(datediff(return_date,rental_date)),2) as avg_rental_duration
from film f
join inventory i on f.film_id= i.film_id
join rental r on i.inventory_id= r.inventory_id
group by f.film_id, f.title, f.rental_duration
order by f.rental_duration, f.film_id;

-- 4. **Identify the top 3 films in each category based on their rental counts.**

select c.name as category_name,
f.title as film_title,
count(r.rental_id) as rental_count
from category c
join film_category fc on c.category_id= fc.category_id= fc.category_id
join film f on fc.film_id= f.film_id
left join inventory i on f.film_id= i.film_id
left join rental r on i.inventory_id= r.inventory_id
group by c.category_id, f.film_id
having rental_count> 0
order by c.name, rental_count desc;

-- 5. **Calculate the difference in rental counts between each customer's total rentals and the average rentals across all customers.**

select c.customer_id,
concat(c.first_name, ' ', c.last_name) as customer_name,
count(r.rental_id) as total_rentals,
count(r.rental_id) - avg_rentals.avg_rentals_all_customers as rental_count_difference
from customer c
left join rental r on c.customer_id= r.customer_id
cross join(
select
avg(sub.total_rentals) as
avg_rentals_all_customers
from(
select c.customer_id,
count(r.rental_id) as total_rentals
from
customer c
left join rental r on c.customer_id= r.customer_id
group by
c.customer_id
) sub
)avg_rentals
group by
c.customer_id, customer_name, avg_rentals.avg_rentals_all_customers
order by
rental_count_difference desc;

-- 6. **Find the monthly revenue trend for the entire rental store over time.**

select
date_format(p.payment_date,'%y-%m') as payment_month,
sum(p.amount) as monthly_revenue
from payment p
group by date_format(p.payment_date, '%y-%m')
order by payment_month;

-- 7. **Identify the customers whose total spending on rentals falls within the top 20% of all customers.**


select customer_id,
concat(first_name, ' ', last_name) as customer_name,
total_amount_spent
from(
select
c.customer_id,
c.first_name,
c.last_name,
sum(p.amount) as
total_amount_spent,
percent_rank() over (order by sum(p.amount) desc) as pct_rank
from
customer c
join
payment p on c.customer_id= p.customer_id
group by
c.customer_id
) ranked_customers
where
pct_rank<= 0.2
order by
total_amount_spent desc;

-- 8. **Calculate the running total of rentals per category, ordered by rental count.**

select c.name as category_name,
f.title as film_title,
count(r.rental_id) as rental_count,
sum(count(r.rental_id)) over
(partition by c.name order by 
count(r.rental_id) desc) as
running_total_rentals
from category c
join film_category fc on c.category_id= fc.category_id
join film f on fc.film_id= f.film_id
left join inventory i on f.film_id= i.film_id
left join rental r on i.inventory_id= r.inventory_id
group by c.category_id, f.film_id
order by rental_count desc;

-- 9. **Find the films that have been rented less than the average rental count for their respective categories.**

select film_title,
category_name,
rental_count
avg_category_rental_count
from(
select
f.title as film_title,
c.name as category_name,
count(r.rental_id) as rental_count,
avg(cnt.rental_count) as
avg_category_rental_count
from film f
join film_category fc on f.film_id= fc.film_id
join category c on fc.category_id= c.category_id
left join(
select
f.film_id,
fc.category_id,
count(r.rental_id) as rental_count
from film f
join film_category fc on f.film_id= fc.film_id
left join inventory i on f.film_id= i.film_id
left join rental r on i.inventory_id= r.inventory_id
group by
f.film_id, fc.category_id
) cnt on f.film_id= cnt.film_id and
c.category_id= cnt.category_id
left join inventory i on f.film_id= i.film_id
left join rental r on i.inventory_id= r.inventory_id
group by
f.film_id, c.category_id
) subquery
where
rental_count<
avg_category_rental_count
order by
category_name, rental_count;

-- 10. **Identify the top 5 months with the highest revenue and display the revenue generated in each month.**

select
date_format(p.payment_date, '%y-%m') as payment_month,
sum(p.amount) as total_revenue
from payment p
group by
date_format(p.payment_date, '%y-%m')
order by
total_revenue desc limit 5;

