import streamlit as st # this module is for streamlit
import pandas as pd # this module for pandas
import numpy as np # this module is for numpy 
import mysql.connector # this module is for connecting with mysql
import os
from dotenv import load_dotenv
from all_functions import (get_kpis, get_basic_info_tables,
                           inventory_health,
                           get_monthly_sales_restock,
                           category_wise_analysis,
                           product_wise_performance,
                           add_new_product,prod_names, 
                           product_inventory_history,
                           product_shipment_history,
                           place_order_suggestions,
                           place_order,
                           get_ordered_reorders,
                           mark_reorder_received)

# ----------------------------------------------------------------------------------
# connection check point with mysql
env = load_dotenv(".env") # load .env file
try:
    connection = mysql.connector.connect(
        host = os.getenv('db_host'),
        user = os.getenv('db_username'),
        password = os.getenv('db_password'),
        database = os.getenv('db_database')
        )
    st.success(f'Connection setup: {connection.is_connected()}')
    cursor = connection.cursor(dictionary = True)
except Exception as e:
    st.error(f"Connection can't setup, something went wrong. Error : {e}")

# ----------------------------------------------------------------------------------
# Titles and headers
st.title('📦 Retail Inventory and Supply Chain Dashboard')
st.sidebar.header('📈 Inventory Operations')

# ------------------- Sidebar -----------------------------------------------------
option = st.sidebar.radio('Select Option', ['Dashboard','Operational Task'])


# -------------------First page----------------------------------------
if option == 'Dashboard':
    st.header('📊 KPIs')

    # -------------------KPI section queries----------------------------------------
    kpis = get_kpis()
    
    for i in range(0,len(kpis),3):
        cols = st.columns(3)
        with cols[0]:
            cursor.execute(kpis[i])
            fetch = cursor.fetchall()
            st.metric(label = list(fetch[0].keys())[0],value  = list(fetch[0].values())[0])
        with cols[1]:
            cursor.execute(kpis[i+1])
            fetch = cursor.fetchall()
            st.metric(label = list(fetch[0].keys())[0],value  = list(fetch[0].values())[0])
        with cols[2]:
            cursor.execute(kpis[i+2])
            fetch = cursor.fetchall()
            st.metric(label = list(fetch[0].keys())[0],value  = list(fetch[0].values())[0])

    #------------------------Inventory Health-----------------------------------------

    inventory_health_info = inventory_health(cursor)
    # As on above we have already declared cols = st.columns(3), so here we directly used it
    with cols[0]:
        st.metric(label = f"🟢{inventory_health_info[0]['inventory health']}", value = inventory_health_info[0]['total products'])
    with cols[1]:
        st.metric(label = f"🟡{inventory_health_info[1]['inventory health']}", value = inventory_health_info[1]['total products'])
    with cols[2]:
        st.metric(label = f"🔴{inventory_health_info[2]['inventory health']}", value = inventory_health_info[2]['total products'])

    st.divider()
    #------------------------tables on basic info-----------------------------------------

    # Sales and Restock Monthwise 
    st.subheader("Monthly Sales and Restock")
    monthly_sales_restock_data = get_monthly_sales_restock(cursor)
    if not monthly_sales_restock_data.empty: # monthly_sales_restock_data.empty mean it will check is the data structure contains data or not
        st.bar_chart(data = monthly_sales_restock_data,
                     x = 'year_month',
                     y = ['Total_Restock_quantity', 'Total_Sale_quantity'],
                     stack = False,
                     color=['#c9184a','#eae2b7']
                     )
        with st.expander("Show Monthly Sales and Restock Details"): # st.expander will help to Hide and Show the contained info
            st.dataframe(monthly_sales_restock_data, use_container_width=True)
    else:
        st.info("No data available to show")

    # categorywise inventory health
    st.divider()
    category_data = category_wise_analysis(cursor)
    st.subheader('Category wise performance')
    st.dataframe(category_data.set_index('category'), use_container_width=True)

    # Productwise Performance
    st.divider()
    st.subheader("Productwise Performance")
    product_sales = product_wise_performance(cursor)
    product_sales_top10 = product_sales.sort_values(by = 'Total_Sale_quantity', ascending=False).head(10)
    if not product_sales.empty: # monthly_sales_restock_data.empty mean it will check is the data structure contains data or not
        st.bar_chart(data = product_sales_top10 ,
                        x = 'product_name',
                        y = ['Total_Stock_quantity', 'Total_Sale_quantity'],
                        color=["#ade8f4",'#00b4d8'], # assign color such a way that color will apply to alphabtic orderwise of column name
                        stack = False
                    )
        with st.expander("Show productwise performance Details"): # st.expander will help to Hide and Show the contained info
            st.dataframe(product_sales, use_container_width=True)
    else:
        st.info("No data available to show")
    
    
    # st.subheader('Supplier Contact Details')
    tables,subheaders = get_basic_info_tables(cursor) # this function is helpful for showcase the tables in basic page

    # for i,j in zip(tables_queries,subheaders):
    #     st.subheader(j)
    #     cursor.execute(i)
    #     t = cursor.fetchall()
    #     st.dataframe(pd.DataFrame(t))
    st.subheader(subheaders[0]) # this is for product need to reorder table
    st.dataframe(tables[0])

    with st.expander('ℹ️ Show Supplier Details For Respective Product'):
        st.subheader(subheaders[1])
        st.dataframe(tables[1])
        st.subheader(subheaders[2])
        st.dataframe(tables[2])

else: # for operational task
    st.header('⚙️ Operational Tasks')
    task = st.selectbox("Choose a task",['Add New Product','Product History','Place Reorder','Receive Order'])
    
    # --------------- Task wise operation -------------------------------
    
    if task == 'Add New Product':
        st.write('- This funtion is for adding new products only.')
        result_add_new = add_new_product(cursor)
        pn,pc,pprice,pquan,preor,psup_id,submit = result_add_new
        st.write(f'product name{pn,pc,pprice,pquan,preor,psup_id}')
        try:
            if (pn != None and pc != None and pprice != 0 and pquan != 0 and preor != 0 and psup_id != None and submit == True):
                query = """CALL addnewproduct(%s,%s,%s,%s,%s,%s)"""
                parameters = (pn,pc,pprice,pquan,preor,psup_id)
                cursor.execute(query,parameters)
                connection.commit()
                st.success('Deatils added successfully')
        
            elif (pn == None or pc == None or pprice == 0 or pquan == 0 or preor == 0 or psup_id == None) and submit == True:
                st.error('Enter a details correctly')
        except Exception as e:
            st.write(f'There is a error {e}')

    elif task == 'Product History':
        prod_name = st.selectbox('Select a product name...',prod_names(cursor), index=None)
        history = st.radio("Select which type of record want to see....",["Product Inventory Records","Product Shipment Recors"],horizontal=True)
        
        if prod_name != None and history == "Product Inventory Records":
              result = product_inventory_history(cursor,prod_name)
              st.dataframe(result)
        elif prod_name != None and history == "Product Shipment Recors":
                result = product_shipment_history(cursor,prod_name)
                st.dataframe(result)
             
    elif task == 'Place Reorder':
        with st.form("reorder"):
            prod_name = st.selectbox('Select a product name want to reorder...',prod_names(cursor), index=None)
            prod_quant = st.slider("Enter quantity...", max_value = 200)
            submit_reorder = st.form_submit_button("Reorder")
        if submit_reorder == True and prod_name != None:
            try:
                place_order(connection,cursor,prod_name,prod_quant)
                st.success("Ordered Successfully")
            except Exception as e:
                st.error(f"There is some error {e}")

        st.dataframe(place_order_suggestions(cursor))
    else:
        st.subheader('✅ Mark Reorder as received')
        with st.form("mark_ordered_received"):
            reorder_list = list(get_ordered_reorders(cursor))
            reorder_product = st.selectbox("Select a reordered product to mark as received....",reorder_list, index= None)
            received = st.form_submit_button("Mark as received")     
            
            if received == True and reorder_product != None:
                reorder_product_id = int(reorder_product.split('-')[0].strip())
                try:
                    mark_reorder_received(cursor,connection,reorder_product_id)
                    st.success("Updated successfully")
                except Exception as e:
                    st.error(f"error : {e}")
            else:
                st.warning('Select a reorder id and then click on submit')

if connection.is_connected():
    cursor.close()
    connection.close()
 