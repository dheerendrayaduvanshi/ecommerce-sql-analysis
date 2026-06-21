-- DEFINE SALES FUNNEL AND THE DIFFERENT STAGES

with funnel_stages as 
(
	select 
		  count(distinct case when event_type = 'page_view' then user_id end) as stage_1_views,
          count(distinct case when event_type = 'add_to_cart' then user_id end) as stage_2_cart,
          count(distinct case when event_type = 'checkout_start' then user_id end) as stage_3_checkout,
          count(distinct case when event_type = 'payment_info' then user_id end) as stage_4_payment,
          count(distinct case when event_type = 'purchase' then user_id end) as stage_5_purchase
	from user_events
)
select
	  *
from funnel_stages;

-- CONVERSION RATES THROUGH THE FUNNEL

with funnel_stages as 
(
	select 
		  count(distinct case when event_type = 'page_view' then user_id end) as stage_1_views,
          count(distinct case when event_type = 'add_to_cart' then user_id end) as stage_2_cart,
          count(distinct case when event_type = 'checkout_start' then user_id end) as stage_3_checkout,
          count(distinct case when event_type = 'payment_info' then user_id end) as stage_4_payment,
          count(distinct case when event_type = 'purchase' then user_id end) as stage_5_purchase
	from user_events
)
select
	  stage_1_views,
      stage_2_cart,
      round(stage_2_cart * 100 / stage_1_views) as views_to_cart_rate,
      
      stage_3_checkout,
	  round(stage_3_checkout * 100 / stage_2_cart) as cart_to_checkout_rate,
      
      stage_4_payment,
      round(stage_4_payment * 100 / stage_3_checkout) as checkout_to_payment_rate,
      
      stage_5_purchase,
      round(stage_5_purchase * 100 / stage_4_payment) as payment_to_purchase_rate,
      
      round(stage_5_purchase * 100 / stage_1_views) as overall_conversion_rate
      
from funnel_stages;

-- FUNNEL BY SOURCE

with source_funnel as 
(
	select 
		  traffic_source,
		  count(distinct case when event_type = 'page_view' then user_id end) as views,
          count(distinct case when event_type = 'add_to_cart' then user_id end) as carts,
          count(distinct case when event_type = 'purchase' then user_id end) as purchases
	from user_events
    group by traffic_source
)
select 
	 traffic_source,
     views,
     carts,
     purchases,
     round(carts * 100 / views) as cart_conversion_rate,
     round(purchases * 100 / views) as purchase_conversion_rate,
     round(purchases * 100 / carts) as cart_to_purchase_conversion_rate
from source_funnel
order by purchases desc;

-- TIME TO CONVERSION ANALYSIS

with user_journey as 
(
	select 
		  user_id,
		  min(case when event_type = 'page_view' then event_date end) as view_time,
          min(case when event_type = 'add_to_cart' then event_date end) as cart_add_time,
          min(case when event_type = 'purchase' then event_date end) as purchase_time
	from user_events
    group by user_id
    having min(case when event_type = 'purchase' then event_date end) is not null
)
select 
	 count(*) as converted_users,
     round(avg(timestampdiff(minute,view_time,cart_add_time)),2) as avg_view_to_cart_minutes,
	 round(avg(timestampdiff(minute,cart_add_time,purchase_time)),2) as avg_cart_to_purchase_minutes,
	 round(avg(timestampdiff(minute,view_time,purchase_time)),2) as avg_view_to_purchase_minutes
from user_journey;

-- revenue funnel analysis

with funnel_revenue as 
(
	select 
		  count(distinct case when event_type = 'page_view' then user_id end) as total_visitors,
          count(distinct case when event_type = 'purchase' then user_id end) as total_buyers,
          round(sum(case when event_type = 'purchase' then amount end),2) as total_revenue,
          count(case when event_type = 'purchase' then 1 end) as total_orders
	from user_events
)
select 
	 total_visitors,
     total_buyers,
     total_orders,
     total_revenue,
     round(total_revenue / total_orders , 2) as avg_order_value,
     round(total_revenue / total_buyers , 2) as revenue_per_buyer,
	 round(total_revenue / total_visitors , 2) as revenue_per_visitor

from funnel_revenue;

-- revenue by products

with product_revenue as
(
	select
		 product_id,
         round(sum(amount),2) as revenue
	from user_events
    group by product_id
)
select
	 product_id,
     revenue
from product_revenue
order by revenue desc;