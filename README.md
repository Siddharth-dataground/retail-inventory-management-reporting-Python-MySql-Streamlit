# 📦 Retail Inventory Management & Operational Reporting System

## 💡 The Story Behind the Project

Have you ever visited a store, found something you really liked, and then discovered that the size or variant you wanted was not available?

I have experienced this myself.

On one occasion, I found a shirt I liked, but my size was not available. On another occasion, I was interested in a phone, but the variant I wanted was out of stock.

These experiences made me think about the problem from the **retailer's perspective**:

> **How does a retailer know which products are running low, which products need to be reordered, and whether incoming stock has actually been received and added to inventory?**

This question led me to build this prototype.

---

## 🎯 The Business Problem

Inventory management is not only about knowing how much stock is currently available.

A retail operation also needs visibility into:

- Products that are out of stock
- Products which are close to their reorder level
- Sales and restocking movement
- Products with higher sales activity
- Reorder requests
- Received orders
- Inventory movement history
- Shipment history

Without a centralized system, these activities can become difficult to track and monitor consistently.

The goal of this project is to create a simple system that brings these **inventory and operational activities together** and provides useful reporting for day-to-day decision-making.

---

## 💡 The Solution

I built a **Retail Inventory Management & Operational Reporting System** that combines operational workflows with management reporting.

The system allows a retail user to:

- Monitor overall inventory KPIs
- Check inventory health
- Identify products requiring reorder
- Analyze monthly sales and restocking activity
- Analyze inventory by category
- Identify top-selling products
- Compare sales activity with current stock
- Place reorder requests
- Receive incoming orders
- Track inventory history
- Track shipment history

The project is designed as a **prototype** demonstrating how a retail operation could combine its database, operational processes, and reporting into one application.

---

## 📊 What the Dashboard Provides

### Overall KPIs

Provides a quick summary of:

- Total Suppliers
- Total Products
- Total Categories
- Total Sales Last 3months
- Total Restock Last 3months
- Below Reorders and no pending reorders

### Inventory Health

Products are grouped into:

- Out of Stock
- Low Stock
- Healthy Stock


### Monthly Sales vs Restock

Provides a monthly comparison of:

- Units sold
- Units restocked

This helps provide visibility into inventory movement over time.

### Category-wise Inventory Analysis

Summarizes inventory across product categories to help understand how stock is distributed.

### Top Products by Sales

Ranks products based on historical recorded sales activity.

### Sales vs Current Stock

Compares historical sales activity with the current stock available for each product.

### Reorder Attention

Identifies products that are currently at or below their reorder level and require attention.

---

## ⚙️ Operational Features

The application also supports operational activities rather than functioning only as a reporting dashboard.

### Add New Product

Allows a user to add a new product along with relevant inventory and supplier information.

### Place Reorder

Allows the user to identify products requiring a reorder.

### Receive Order

Allows the user to mark a reorder as received and update the corresponding inventory records.

### Product History

Provides historical inventory movement for a selected product.

### Shipment History

Provides information about shipments associated with products and suppliers.

---

## 🔄 Overall Operational Flow

The basic workflow of the system is:

Product
↓
Inventory Monitoring
↓
Reorder Required
↓
Place Reorder
↓
Receive Order
↓
Inventory Updated
↓
Inventory History
↓
Shipment History

This connects the **reporting side** of the project with the **operational side**.

---

## 🛠️ Technology Stack

- **Python** – Application logic and database interaction
- **MySQL** – Database and business logic
- **Pandas** – Data processing and reporting
- **Streamlit** – Dashboard and user interface
- **excel(.csv)** - Data set format

---

## 🗄️ Database

The project uses MySQL to store and manage the operational data.

The main datasets include:

- Products
- Suppliers
- Stock Entries
- Reorders
- Shipments

SQL is used for:

- Inventory reporting
- Reorder identification
- Sales and restock analysis
- Product ranking
- Inventory health classification
- Operational procedures
- Inventory updates

---

## 📁 Project Structure

```text
retail-inventory-management-reporting/
│
├── data/
│   ├── products.csv
│   ├── reorders.csv
│   ├── shipments.csv
│   ├── stock_entries.csv
│   └── suppliers.csv
│
├── all_functions.py
├── project_retail_streamlit.py
├── Project_RETAIL.sql
├── README.md
└── .gitignore
```

### The application follows a simple flow:

```text
                    ┌─────────────────────┐
                    │       MySQL         │
                    │                     │
                    │ Products            │
                    │ Suppliers           │
                    │ Stock Entries       │
                    │ Reorders            │
                    │ Shipments           │
                    └──────────┬──────────┘
                               │
                               │ SQL Queries /
                               │ Stored Procedures
                               ▼
                    ┌─────────────────────┐
                    │       Python        │
                    │                     │
                    │ mysql.connector     │
                    │ Pandas              │
                    │ Application Logic   │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │     Streamlit       │
                    │                     │
                    │ Dashboard           │
                    │ Reporting           │
                    │ Operational Tasks   │
                    └─────────────────────┘
```

## 🚀 How to Run the Project

### 1. Clone the repository
```bash
git clone https://github.com/<your-username>/retail-inventory-management-reporting.git
cd retail-inventory-management-reporting
```

### 2. Install the required libraries
```bash
pip install streamlit pandas mysql-connector-python python-dotenv
```

### 3. Open MySql workbench and excute below file:
Project_RETAIL.sql

This creates the required database objects and loads the project structure needed by the application.

### 4. Configure database credentials
create a .env file in the project folder
In that add below details:

```text
db_host=your_host
db_username=your_username
db_password=your_password
db_database=your_database
```
Note: The .env file is excluded from GitHub using .gitignore so that database credentials are not exposed.

### 5. Run the Streamlit application in command line
streamlit run project_retail_streamlit.py

---
```markdown

## 👨‍💻 About This Project

This project was created as a portfolio project to demonstrate practical application of:

- SQL and relational database concepts
- Python database integration
- Data analysis using Pandas
- Operational reporting
- Streamlit application development
- Inventory and replenishment business logic

- The focus was on building a **practical business solution rather than a purely technical exercise**.
```

#### Author : Siddharth Shreekumar