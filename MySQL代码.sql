# 查看销售额的变化趋势
with sale as(
select date_format(order_date,'%Y-%m') as date_month,sum(subtotal) as sales from orders where order_status='Delivered' group by date_month order by date_month)
select date_month,sales,lead(sales)over(order by date_month),lead(sales)over(order by date_month)-sales as diff from sale order by date_month;
