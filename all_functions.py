import streamlit as st
import pandas as pd
def get_kpis():
    total_suppliers = """SELECT COUNT(DISTINCT `supplier_name`) AS 'Total Suppliers' FROM suppliers;"""
    total_products = """SELECT COUNT(DISTINCT `product_name`)  AS 'Total products' FROM products;"""
    total_categories = """SELECT COUNT(DISTINCT `category`)  AS 'Total categories' FROM products;"""
    
    total_sales_last3months ="""WITH t1 AS (
                                                SELECT 
                                                `product_id`,ABS(`change_quantity`) AS 'qty', `entry_date`,
                                                (SELECT DATE_SUB(MAX(`entry_date`),INTERVAL 3 MONTH) FROM stock_entries WHERE `change_type` = 'Sale') AS 'prev_3month'
                                                FROM stock_entries WHERE `change_type` = 'Sale'
                                                ORDER BY `entry_date` DESC)
                                                SELECT 
                                                ROUND(SUM(t1.`qty`* p.`price`),2) AS 'Total Sales Last 3months'
                                                FROM t1 LEFT JOIN products AS p
                                                ON t1.`product_id` = p.`product_id`
                                                WHERE `entry_date` >=`prev_3month`;
                                                """
    total_restock_last3months = """WITH t1 AS (
                                                SELECT 
                                                `product_id`,`change_quantity`, `entry_date`,
                                                (SELECT DATE_SUB(MAX(`entry_date`),INTERVAL 3 MONTH) FROM stock_entries) AS 'prev_3month'
                                                FROM stock_entries WHERE `change_type` = 'Restock'
                                                ORDER BY `entry_date` DESC)
                                                SELECT 
                                                ROUND(SUM(t1.`change_quantity`* p.`price`),2) AS 'Total Restock Last3months'
                                                FROM t1 LEFT JOIN products AS p
                                                ON t1.`product_id` = p.`product_id`
                                                WHERE `entry_date` >=`prev_3month`;
                                                """

    below_reorder_no_pending_order = """SELECT 
                                        COUNT( DISTINCT `product_id`) AS 'Below Reorder and No pending Reorders' 
                                        FROM products 
                                        WHERE `stock_quantity`< `reorder_level`
                                        AND 
                                        `product_id` NOT IN (SELECT `product_id` FROM reorders WHERE `status` = 'Pending');"""

    # -------Stored all queries in a variable------------------
    kpis = [total_suppliers, total_products,total_categories, 
            total_sales_last3months, total_restock_last3months, 
            below_reorder_no_pending_order]
    
    return kpis

def inventory_health(cursor):
    query = """SELECT 
                CASE 
                WHEN `stock_quantity`<`reorder_level` THEN 'Critical Stock'
                WHEN `stock_quantity`=`reorder_level` THEN 'Low Stock'
                ELSE 'Good Stock'
                END AS 'inventory health',
                COUNT(`product_id`) AS 'total products'
                FROM products
                GROUP BY `inventory health`;"""
    cursor.execute(query)
    data = cursor.fetchall()
    return data

def get_monthly_sales_restock(cursor):
    query = """SELECT 
                DATE_FORMAT(st.`entry_date`,'%y-%m') AS 'year_month',
                SUM(CASE WHEN `change_type` = 'Restock' THEN st.`change_quantity` ELSE 0 END) AS 'Total_Restock_quantity',
                SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`) ELSE 0 END) AS 'Total_Sale_quantity',
                ROUND(SUM(CASE WHEN `change_type` = 'Restock' THEN st.`change_quantity`*p.`price` ELSE 0 END ),2) AS 'Total_restock_value',
                ROUND(SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`)*ABS(p.`price`) ELSE 0 END ),2) AS 'Total_sales_value',
                ROUND(SUM(CASE WHEN `change_type` = 'Restock' THEN st.`change_quantity`* p.`price` ELSE 0 END ) 
                - SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`)*ABS(p.`price`) ELSE 0 END ),2) AS 'Net stock movement'
                FROM stock_entries  AS st
                LEFT JOIN products AS p
                ON st.`product_id` = p.`product_id`
                GROUP BY DATE_FORMAT(st.`entry_date`,'%y-%m')
                ORDER BY `year_month`;"""
    cursor.execute(query)
    fetch = pd.DataFrame(cursor.fetchall())
    # some times some numeric columns will store as object, in that case , convert them to numeric
    fetch['Total_Restock_quantity'] = pd.to_numeric(fetch['Total_Restock_quantity'])
    fetch['Total_Sale_quantity'] = pd.to_numeric(fetch['Total_Sale_quantity'])

    return fetch

def category_wise_analysis(cursor):
    query = """SELECT 
                `category`, COUNT(`product_id`) AS 'total_product',SUM(`stock_quantity`) AS 'Total Inventory',
                ROUND(SUM(`stock_quantity`*`price`),2) AS 'Total Inventory Value',
                SUM(CASE WHEN `stock_quantity`<= `reorder_level` THEN 1 ELSE 0 END) AS 'No of products below or at reorder level',
                SUM(CASE WHEN `stock_quantity`< `reorder_level` THEN 1 ELSE 0 END) AS 'No of products below reorder level'
                FROM products
                GROUP BY `category`
                ORDER BY `Total Inventory Value` DESC;"""
    cursor.execute(query)
    data = pd.DataFrame(cursor.fetchall())
    return data

def product_wise_performance(cursor):
    query = """SELECT 
                p.`product_id`,p.`product_name`,
                COALESCE(SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`) END),0) AS 'Total_Sale_quantity',
                ROUND(COALESCE(SUM(CASE WHEN `change_type` = 'Sale' THEN ABS(st.`change_quantity`)*ABS(p.`price`)END ),0),2) AS 'Total_sales_value',
                SUM(CASE WHEN `change_type` = 'Restock' THEN ABS(st.`change_quantity`) END) AS 'Total_Stock_quantity'
                FROM stock_entries  AS st
                LEFT JOIN products AS p
                ON st.`product_id` = p.`product_id`
                GROUP BY p.`product_id`,p.`product_name`
                ORDER BY `Total_Sale_quantity` DESC;"""
    cursor.execute(query)
    df = pd.DataFrame(cursor.fetchall())
    df['Total_Sale_quantity'] = df['Total_Sale_quantity'].astype('int64')
    df['Total_Stock_quantity'] = df['Total_Stock_quantity'].astype('int64')
    return df

def get_basic_info_tables(cursor):
    Supplier_Contact_Details = """SELECT 
                                `supplier_name`,`contact_name`,`email`,`phone` 
                                FROM suppliers;"""
    
    Product_required_to_reorder = """SELECT `product_name`,`stock_quantity`,`reorder_level` 
                                    FROM products 
                                    WHERE `stock_quantity`<`reorder_level` 
                                    ORDER BY `product_name`;"""
    Products_with_supplier_stock="""SELECT p.`product_name`,p.`stock_quantity`,p.`reorder_level`,s.`supplier_name`,
                                    CAST(CEIL((p.`reorder_level`*1.10)-p.`stock_quantity`) AS SIGNED) AS 'quantity need to reorder'
                                    FROM products AS p
                                    LEFT JOIN
                                    suppliers AS s
                                    ON p.`supplier_id`= s.`supplier_id`
                                    WHERE p.`stock_quantity`<p.`reorder_level`
                                    ORDER BY `product_name`;"""

    cursor.execute(Supplier_Contact_Details)
    Supplier_Contact = pd.DataFrame(cursor.fetchall())

    cursor.execute(Product_required_to_reorder)
    prod_required_to_reorder = pd.DataFrame(cursor.fetchall())

    cursor.execute(Products_with_supplier_stock)
    prod_with_supplier_stock = pd.DataFrame(cursor.fetchall())

    #tables_queries = [Product_required_to_reorder,Products_with_supplier_stock,Supplier_Contact_Details]
    subheaders = ['⚠️Product Required to Reorder','Products with Supplier Stock','Supplier Contact Details']
    tables = [prod_required_to_reorder,prod_with_supplier_stock,Supplier_Contact]

    return tables, subheaders

def add_new_product(cursor):
    with st.form("add_new_product"):
        pn,pc,pprice,pquan,preor,psup_id = None, None, 0.00,0,0,None
        pn = st.text_input('Type a product name', value=None, max_chars=100, key = 'product_name')

        # check if the product name exits or not
        cursor.execute("""SELECT DISTINCT `product_name` FROM products;""")
        existed_pname = list(pd.DataFrame(cursor.fetchall())['product_name'].str.lower())
        
        
        if pn!=None and pn.lower() in existed_pname:
            st.write(f'New product name: {None}')
            st.error('This product already exits')
            submit = st.form_submit_button('Add Product')
            return pn,pc,pprice,pquan,preor,psup_id,submit
        else:
            st.write(f'New product name: {pn}')

            # add product category
            cursor.execute("""SELECT DISTINCT `category` FROM products;""")
            pcategory = list(pd.DataFrame(cursor.fetchall())['category'])
            pc = st.selectbox('Choose one category',pcategory, index = None,
                              placeholder='Choose a category.....',key='product_category'
                              )
            
            
            # add product price
            pprice = st.number_input('Enter a price per quantity', min_value=0.00,key = 'product_price',step=0.50)

            # add product quantity
            pquan = st.slider('Enter number quantity', min_value= 0 , max_value=100)
            st.write('* For a new product max stock allowed is 100 & for now default reorder level is "50%" of quantity ordered ')

            # add reorder level
            preor = pquan//2
            
            # add supplier id
            # better to select name and then update data base for it's id
            cursor.execute("""SELECT DISTINCT `supplier_name` FROM suppliers;""")
            snames = list(pd.DataFrame(cursor.fetchall())['supplier_name'])
            psup_names = st.selectbox('Select a supplier name',snames,index=None,placeholder='Select a name',key = 'suppliers_names')
            if psup_names == None:
                st.write(f'id of this supplier is : {None}')
            else:
                cursor.execute(f"""SELECT `supplier_id` FROM suppliers WHERE supplier_name = '{psup_names}';""")
                psup_id = int(cursor.fetchall()[0]['supplier_id'])
            
            submit = st.form_submit_button('Add Product')
            return pn,pc,pprice,pquan,preor,psup_id,submit
        
def prod_names(cursor):
    query = """SELECT DISTINCT `product_name` FROM products;"""
    cursor.execute(query)
    prod_name = list(pd.DataFrame(cursor.fetchall())['product_name'].str.upper())
    return prod_name


def product_inventory_history(cursor,prod_name):
    query = """SELECT * FROM product_inventory_history WHERE `Product Name` = %s;"""
    cursor.execute(query,(prod_name,))
    result = pd.DataFrame(cursor.fetchall())
    return result

def product_shipment_history(cursor,prod_name):
    query = """SELECT * FROM product_shipment_history WHERE `Product Name` = %s;"""
    cursor.execute(query,(prod_name,))
    result = pd.DataFrame(cursor.fetchall())
    return result

def place_order_suggestions(cursor):
    query  = """SELECT 
                p.`product_id`,p.`product_name`,p.`stock_quantity`,p.`reorder_level`,
                CAST(CEIL(p.`reorder_level`*1.10 - p.`stock_quantity`) AS SIGNED) AS 'Quantity Need to reorder (recommended)'
                FROM products AS p
                WHERE p.`stock_quantity`<= p.`reorder_level`;"""
    cursor.execute(query)
    result = pd.DataFrame(cursor.fetchall())
    return result

def place_order(connection,cursor,prod_name,prod_quant):
    query = """CALL place_order(%s,%s);"""
    cursor.execute(query,(prod_name,prod_quant))
    connection.commit()

def get_ordered_reorders(cursor):
    cursor.execute("""SELECT 
                        CONCAT(r.`reorder_id`,' - ',p.`product_name`)
                        FROM reorders AS r
                        INNER JOIN products AS p
                        ON r.`product_id` = p.`product_id`
                        WHERE r.`status` = 'Ordered'
                        ORDER BY r.`reorder_id`;""")
    result = pd.DataFrame(cursor.fetchall()).iloc[:,0]
    return result

def mark_reorder_received(cursor,connection,id):
    cursor.execute("""CALL order_received(%s);""",(id,))
    connection.commit()
