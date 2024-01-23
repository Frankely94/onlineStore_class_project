from flask import Flask,flash,render_template, request, redirect, url_for,session,jsonify
from flask_mysqldb import MySQL
import MySQLdb.cursors
import re
from flask_socketio import SocketIO, send

app = Flask(__name__)

app.secret_key = 'your secret key'

app.config['MYSQL_HOST'] = '127.0.0.1'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'Pj21436587'
app.config['MYSQL_DB'] = 'SellerDatabase'


mysql = MySQL(app)

@app.route("/")
@app.route("/home")
def home():
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)

    # Query to fetch recent orders along with product names
    query = """
    SELECT o.order_id, p.name AS product_name, o.order_status, o.order_date
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    ORDER BY o.order_date DESC
    LIMIT 10
    """
    cursor.execute(query)
    recent_orders = cursor.fetchall()

    return render_template("index.html", recent_orders=recent_orders)

@app.route('/')
def dashboard():
    cursor = mysql.connection.cursor()

    # Monthly Sales Query
    monthly_sales_query = """
    SELECT SUM(p.price) AS total_monthly_sales
    FROM orders o
    INNER JOIN products p ON o.product_id = p.product_id
    WHERE YEAR(o.order_date) = YEAR(CURRENT_DATE()) AND MONTH(o.order_date) = MONTH(CURRENT_DATE());
    """
    cursor.execute(monthly_sales_query)
    monthly_sales = cursor.fetchone()['total_monthly_sales']

    # Weekly Sales Query
    weekly_sales_query = """
    SELECT SUM(p.price) AS total_weekly_sales
    FROM orders o
    INNER JOIN products p ON o.product_id = p.product_id
    WHERE YEARWEEK(o.order_date, 1) = YEARWEEK(CURRENT_DATE(), 1);
    """
    cursor.execute(weekly_sales_query)
    weekly_sales = cursor.fetchone()['total_weekly_sales']

    # Last 24 Hours Sales Query
    last_24_hours_sales_query = """
    SELECT SUM(p.price) AS total_24h_sales
    FROM orders o
    INNER JOIN products p ON o.product_id = p.product_id
    WHERE o.order_date >= NOW() - INTERVAL 1 DAY;
    """
    cursor.execute(last_24_hours_sales_query)
    last_24_hours_sales = cursor.fetchone()['total_24h_sales']

    # Close the cursor
    cursor.close()

    # Render the template with the sales data
    return render_template('index.html', monthly_sales=monthly_sales, weekly_sales=weekly_sales, last_24_hours_sales=last_24_hours_sales)

@app.route("/messages")
def messages():
    return render_template("messages.html")

@app.route("/products")
@app.route("/products/<int:page>")
def products(page=1):
    per_page = 10
    start_at = (page - 1) * per_page
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute('SELECT * FROM products LIMIT %s OFFSET %s', (per_page, start_at))
    products = cursor.fetchall()

    # Fetch the total number of products to calculate total pages
    cursor.execute('SELECT COUNT(*) as count FROM products')
    total_products = cursor.fetchone()['count']
    total_pages = (total_products + per_page - 1) // per_page

    return render_template("prodpage.html", products=products, total_pages=total_pages, current_page=page)

@app.route("/add_product", methods=['POST'])
def add_product():
    name = request.form['name']
    description = request.form['description']
    price = request.form['price']

    cursor = mysql.connection.cursor()
    query = "INSERT INTO products (name, description, price) VALUES (%s, %s, %s)"
    cursor.execute(query, (name, description, price))
    mysql.connection.commit()
    cursor.close()

    return redirect(url_for('products'))

@app.route("/remove_product/<int:product_id>", methods=['POST'])
def remove_product(product_id):
    cursor = mysql.connection.cursor()
    query = "DELETE FROM products WHERE product_id = %s"
    cursor.execute(query, (product_id,))
    mysql.connection.commit()
    cursor.close()

    return redirect(url_for('products'))


@app.route("/analytics")
def analytics():
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)

    # Average Purchase Value Per Customer
    cursor.execute('SELECT AVG(total_purchases) AS average_purchase_value FROM customers')
    average_purchase_value = cursor.fetchone()['average_purchase_value']

    # Total Revenue Generated
    cursor.execute('SELECT SUM(total_purchases) AS total_revenue FROM customers')
    total_revenue = cursor.fetchone()['total_revenue']

    # Product Price Range Analysis
    cursor.execute('SELECT MIN(price) AS min_price, MAX(price) AS max_price, AVG(price) AS avg_price FROM products')
    price_range = cursor.fetchone()

    # Total Customers
    cursor.execute('SELECT COUNT(*) AS total_customers FROM customers')
    total_customers = cursor.fetchone()['total_customers']

    # Most Expensive Product
    cursor.execute('SELECT name, price FROM products ORDER BY price DESC LIMIT 1')
    most_expensive_product = cursor.fetchone()

    # Least Expensive Product
    cursor.execute('SELECT name, price FROM products ORDER BY price ASC LIMIT 1')
    least_expensive_product = cursor.fetchone()

    return render_template("analytics.html", 
                           average_purchase_value=average_purchase_value, 
                           total_revenue=total_revenue,
                           price_range=price_range, 
                           total_customers=total_customers,
                           most_expensive_product=most_expensive_product,
                           least_expensive_product=least_expensive_product)



@app.route("/customers")
@app.route("/customers/<int:page>")
def customers(page=1):
    per_page = 10
    start_at = (page - 1) * per_page
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute('SELECT * FROM customers LIMIT %s OFFSET %s', (per_page, start_at))
    customers = cursor.fetchall()

    # Fetch the total number of customers to calculate total pages
    cursor.execute('SELECT COUNT(*) as count FROM customers')
    total_customers = cursor.fetchone()['count']
    total_pages = (total_customers + per_page - 1) // per_page

    return render_template("customers.html", customers=customers, total_pages=total_pages, current_page=page)

@app.route('/add_customer', methods=['POST'])
def add_customer():
    name = request.form['name']
    email = request.form['email']
    total_purchases = request.form['total_purchases']

    cursor = mysql.connection.cursor()
    query = "INSERT INTO customers (name, email, total_purchases) VALUES (%s, %s, %s)"
    cursor.execute(query, (name, email, total_purchases))
    mysql.connection.commit()
    cursor.close()

    return redirect(url_for('customers'))  # Redirect to the customers page

@app.route('/remove_customer/<int:customer_id>', methods=['POST'])
def remove_customer(customer_id):
    cursor = mysql.connection.cursor()
    query = "DELETE FROM customers WHERE customer_id = %s"
    cursor.execute(query, (customer_id,))
    mysql.connection.commit()
    cursor.close()

    return redirect(url_for('customers'))  # Redirect to the customers page

if __name__ == '__main__':
    app.run(debug=True, port=8000)
    

