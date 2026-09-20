# 查看销售额的变化趋势
with sale as(
select date_format(order_date,'%Y-%m') as date_month,sum(subtotal) as sales from orders where order_status='Delivered' group by date_month order by date_month)
select date_month,sales,lead(sales)over(order by date_month),lead(sales)over(order by date_month)-sales as diff from sale order by date_month;

# 渠道与销售额的交叉分析
with monthly as(
select date_format(order_date,'%Y-%m') as month,marketing_channel,sum(subtotal) as sales 
from orders 
where date_format(order_date,'%Y-%m') in ('2025-01','2025-02') and order_status = 'Delivered' 
group by date_format(order_date,'%Y-%m'),marketing_channel ),
pivot as
(select marketing_channel,sum(case when month = '2025-01' then sales else 0 end) as jan_sales,sum(case when month = '2025-02' then sales else 0 end) as feb_sales 
from monthly group by marketing_channel) 
select marketing_channel,jan_sales,feb_sales,feb_sales-jan_sales as diff from pivot order by diff asc;

# 销售数量和销售额分析
with sale  as (
select order_id,date_format(order_date,'%Y-%m') as date 
from orders 
where date_format(order_date,'%Y-%m') in ('2025-01','2025-02') and marketing_channel in('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search') 
and order_status='Delivered' )
select date,sum(quantity),sum(item_revenue) from sale s left join order_items od on s.order_id=od.order_id group by date order by date;

# 销量效应与价格效应分析
with month_one as (
select  date_format(order_date,'%Y-%m') as date_first,sum(quantity) as first_qu,sum(item_revenue) as first_ir,sum(item_revenue)/sum(quantity) as first_iq 
from orders od left join order_items oi on od.order_id=oi.order_id 
where date_format(order_date,'%Y-%m') = '2025-01' and od.marketing_channel in('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search') 
and od.order_status='Delivered' group by date_first),
month_two as(
select date_format(order_date,'%Y-%m') as date_second,sum(quantity) as second_qu,sum(item_revenue) as second_ir,sum(item_revenue)/sum(quantity) as second_iq 
from orders od left join order_items oi on od.order_id=oi.order_id 
where date_format(order_date,'%Y-%m') = '2025-02' and od.marketing_channel in('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search') 
and od.order_status='Delivered' group by date_second)
select (second_qu-first_qu)*first_iq as quantity_power,(second_iq-first_iq)*second_qu as salary_power from month_one join month_two;

# 订单数VS每笔订单下单量
with monthly as
(select date_format(order_date,'%Y-%m') as month ,count(distinct o.order_id) as order_cnt,sum(oi.quantity) as total_qty,sum(oi.quantity) / count(distinct o.order_id) as qty_per_order 
from orders o left join order_items oi on o.order_id=oi.order_id 
where date_format(order_date,'%Y-%m') in ('2025-01','2025-02') 
and marketing_channel in('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search') 
and order_status='Delivered' group by month) select * from monthly;

# 订单数与渠道分析
with channel_monthly as (
select o.marketing_channel,date_format(o.order_date,'%y-%m') as month,count(distinct o.order_id) as order_cnt,sum(oi.item_revenue) as sales,sum(oi.item_revenue) / count(distinct o.order_id) as aov
from orders o join order_items oi on o.order_id = oi.order_id
where o.order_status = 'delivered'
and date_format(o.order_date,'%y-%m') in ('2025-01','2025-02')
and o.marketing_channel in ('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search') 
group by o.marketing_channel, month)select * from channel_monthly order by marketing_channel, month;

# 老用户流失数
select date_format(last_order_date,'%Y-%m') as month ,customer_segment,count(distinct customer_id) as last_count 
from customers where date_format(last_order_date,'%Y-%m')='2025-01' 
and acquisition_channel in ('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search') 
group by month,customer_segment;

# 1月新用户订单数与新用户数
with first_login as (
select distinct  customer_id 
from customers 
where date_format(customer_signup_date,'%Y-%m')='2025-01' 
and acquisition_channel in ('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search')),
order_second as (
select order_id,customer_id from orders 
where date_format(order_date,'%Y-%m')='2025-01' 
and marketing_channel in('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search') and order_status='Delivered')
select count(os.order_id) from order_second os  join first_login fl on os.customer_id=fl.customer_id;

# 2月新用户订单数与新用户数
with first_login as (
select distinct  customer_id 
from customers
where date_format(customer_signup_date,'%Y-%m')='2025-02' 
and acquisition_channel in ('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search')),
order_second as (
select order_id,customer_id 
from orders 
where date_format(order_date,'%Y-%m')='2025-02' 
and marketing_channel in('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search') 
and order_status='Delivered')
select count(os.order_id) from order_second os  join first_login fl on os.customer_id=fl.customer_id;

#高净值客户1月订单数和销售额
with premium as(
select customer_id 
from customers 
where date_format(last_order_date,'%Y-%m')='2025-01' 
and acquisition_channel in ('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search') and customer_segment='premium' )
select od.marketing_channel,count(order_id),sum(subtotal) 
from budget bd join orders od on bd.customer_id =od.customer_id 
where date_format( od.order_date,'%Y-%m')='2025-01' 
and marketing_channel in ('Organic Search','Social Media - Facebook','Affiliate','Email Marketing','Paid Search') 
group by marketing_channel;
