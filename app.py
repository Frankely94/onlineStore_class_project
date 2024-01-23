from flask import Flask,flash, render_template, request, redirect, url_for, session, jsonify
from flask_mysqldb import MySQL
import MySQLdb.cursors
import re
import os
#import requests
from decimal import Decimal
import logging
logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)


app.secret_key = 'your secret key'


app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'Passwd_here'
app.config['MYSQL_DB'] = 'databsae_name_here'


mysql = MySQL(app)




##############################################################
@app.route('/broker',methods=['GET', 'POST'])
def broker():
    if 'username' in session:
         logging.debug('broker module')
    return render_template('broker.html')
   

@app.route('/inventoryreport', methods=['GET', 'POST'])
def inventoryreport():
    if 'loggedin' in session:
        logging.debug("Inventory Report module")  
        page = int(request.args.get('page', 1))
        page_size = 3  # Define your page size here
 
        offset = (page - 1) * page_size
 
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute(f'SELECT category, totalquantity FROM Inventorydetails LIMIT {offset}, {page_size}')
        data = cursor.fetchall()
       
        cursor.execute('SELECT category, totalquantity FROM Inventorydetails')
        cdata = cursor.fetchall()
        invdata = []  # Initialize as an empty list for consistency
        tdata = []
 
        if request.method == 'POST':
            logging.debug("POST method triggered")  
            new_category = request.form.get('existing_categories')
            new_sdate = request.form.get('start_date')
            new_edate = request.form.get('end_date')
            new_type = request.form.get('data_type')
            logging.debug(f"Selected category: {new_category}")  
           
            if new_category:
                logging.debug(f"Retrieving details for category: {new_category}")  
                cursor.execute('SELECT pid,pname, qn, pr, pg FROM getDetailedData WHERE pg = %s', (new_category,))
                invdata = cursor.fetchall()
            if new_sdate and new_edate and new_type:
                logging.debug(f"Retrieving details for new_type: {new_type}")  
                logging.debug(f"Retrieving details for Date: {new_sdate}")  
                logging.debug(f"Retrieving details for Date: {new_edate}")  
                if new_type =='delete':
                 cursor.execute('select * from trackInventoryDeletedData WHERE DATE(updatedDate) BETWEEN %s AND %s', (new_sdate, new_edate,))
                 tdata = cursor.fetchall()
                else:
                 cursor.execute('SELECT * FROM trackInventoryData WHERE DATE(updatedDate) BETWEEN %s AND %s', (new_sdate, new_edate,))
                 tdata = cursor.fetchall()
 
                   
                 
                   
    return render_template("inventoryreport.html", data=data, cdata=cdata, invdata=invdata,tdata=tdata, page=page, page_size=page_size)     #return redirect(url_for('broker'))
 
@app.route('/customer_seller_activities', methods=['GET', 'POST'])
def customer_seller_activities():
    if 'username' in session:
        logging.debug('customer_seller_activities module')
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
   
        cursor.execute('call GetBrokerResult();')
        TNcustomer = cursor.fetchone()
        cursor.nextset()
        TNSeller = cursor.fetchone()
        cursor.nextset()
        Tsales = cursor.fetchone()
        cursor.nextset()
        TPrice = cursor.fetchone()
        x=0.00
        x=TPrice['totalprice']
        Tprofit =(x*Decimal(0.90))
        Tprofit=round((x-Tprofit),2)
        cursor.nextset()
        TSProfit= cursor.fetchone()
        y=TSProfit['tps']
        TSProfit =(y*Decimal(0.95))
        TSProfit=round((y-TSProfit),2)
        
        overallProfit=(TSProfit+Tprofit)
        
        
        cursor.execute('select username,email from accounts where userType="user"')
        Allcustomer= cursor.fetchall()
        cursor.execute('select seller_name,seller_email from sellerdata group by seller_name,seller_email')
        AllSeller= cursor.fetchall()
        singleresult=''
        tableresult=[]
        tqa='',
        tlp='',
        STable=[]
       
        if request.method == 'POST':
         logging.debug("POST method triggered")  
         new_Cname = request.form.get('customer_name')
         new_Cemail = request.form.get('customer_email')
         new_Sname = request.form.get('seller_name')
         new_Semail = request.form.get('seller_email')
       
         if new_Sname and new_Semail:
            logging.debug(new_Sname)
            logging.debug(new_Semail)  
            cursor.execute('CALL GetSellerViewResult(%s,%s)', (new_Sname,new_Semail,)) 
            tqa = cursor.fetchone()['stq']
            cursor.nextset()
            tlp = cursor.fetchone()['stp']
            cursor.nextset()
            STable = cursor.fetchall()
            
         if new_Cname and new_Cemail:
            logging.debug(new_Cname)
            logging.debug(new_Cemail)  
            cursor.execute('SELECT id FROM accounts WHERE username = %s AND email = %s', (new_Cname, new_Cemail))
            fetched_id = cursor.fetchone()
   
            if fetched_id:  # Check if a valid ID was fetched
                new_id = int(fetched_id['id'])  # Convert to integer
       
                cursor.execute('CALL GetcustomerViewResult(%s)', (new_id,))  # Pass new_id as a parameter
                singleresult = cursor.fetchone()
                logging.debug(singleresult)
                cursor.nextset()
                tableresult = cursor.fetchall()
                
            else:
              logging.debug("No ID found for the provided username and email.")   
               
       
        return render_template('customer_seller_activities.html', TNcustomer=TNcustomer, TNSeller=TNSeller,Tsales=Tsales,Tprofit=Tprofit,TSProfit=TSProfit,overallProfit=overallProfit,Allcustomer=Allcustomer,singleresult=singleresult,AllSeller=AllSeller,tableresult=tableresult,tqa=tqa,tlp=tlp,STable=STable )
    return render_template('Broker.html')

@app.route('/addInventory', methods=['GET', 'POST'])
def addInventory():
    if 'loggedin' in session:
        logging.debug('addInventory Module')
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute('select category, totalquantity from Inventorydetails')
        data = cursor.fetchall()
        amsg = ''
 
        if request.method == 'POST':
            product_name = request.form.get('product_name')
            existing_categories = request.form.get('existing_categories')
            new_category = request.form.get('new_category')
            quantity = request.form.get('quantity')
            price = request.form.get('price')
 
            if product_name and (existing_categories or new_category) and quantity and price:
                if new_category:
                    product_category = new_category
                    cursor.execute('select count(invprodid) as cnt from InventoryProductCatgeory where InvProdcategory=%s', (new_category,))
                    ispresent=cursor.fetchone()
                    logging.debug(ispresent['cnt'])
                    if ispresent['cnt']==0:
                       insert_newcategory = "INSERT INTO InventoryProductCatgeory (InvProdcategory) VALUES (%s)"
                       cursor.execute(insert_newcategory, (product_category,))
                       mysql.connection.commit()
                    else: amsg = 'Category is already present'
                else:
                    product_category = existing_categories
 
                cursor.execute('SELECT InvProdid FROM InventoryProductCatgeory WHERE InvProdcategory = %s', (product_category,))
                invid = cursor.fetchone()
 
                if invid:
                    insert_newdetails = "INSERT INTO Inventoryproduct (InvProdid, productname, price, quantity) VALUES (%s,%s,%s,%s)"
                    cursor.execute(insert_newdetails, (invid['InvProdid'], product_name, price, quantity))
                    mysql.connection.commit()
                    amsg = 'New products added successfully'
                else:
                    amsg = 'Category not found'
 
            else:
                amsg = 'Please fill in all the details'
 
    return render_template("manageinv.html", data=data, amsg=amsg)
   
@app.route('/updateInventory', methods=['GET', 'POST'])
def updateInventory():
    if 'loggedin' in session:
        logging.debug('updateInventory Module')
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        msg = ''
 
        if request.method == 'POST':
            new_productid = request.form.get('product_id')
            new_quantity = request.form.get('new_quantity')
            new_price = request.form.get('price')
 
            if new_productid and new_quantity and new_price :
               
                update_query = "UPDATE Inventoryproduct SET quantity=%s, price=%s WHERE productid=%s"
                cursor.execute(update_query, (new_quantity, new_price, new_productid))
                mysql.connection.commit()
                msg ='updated sucessfully'
            elif new_productid and new_quantity:
                update_query = "UPDATE Inventoryproduct SET quantity=%s WHERE productid=%s"
                cursor.execute(update_query, (new_quantity, new_productid))
                mysql.connection.commit()
                msg = 'Updated quantity successfully'
 
            elif new_productid and new_price:
                update_query = "UPDATE Inventoryproduct SET price=%s WHERE productid=%s"
                cursor.execute(update_query, (new_price, new_productid))
                mysql.connection.commit()
                msg = 'Updated price successfully'
            else:
                msg = 'Please enter values for either price or quantity '
 
    return render_template("manageinv.html", msg=msg)
 
@app.route('/deleteInventory', methods=['GET', 'POST'])
def deleteInventory():
    if 'loggedin' in session:
        logging.debug('deleteInventory Module')
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        dmsg = ''
 
        if request.method == 'POST':
            new_productid = request.form.get('product_id_to_delete')
 
            if new_productid:
                delete_query = "DELETE FROM Inventoryproduct WHERE productid=%s"
                cursor.execute(delete_query, (new_productid,))
                mysql.connection.commit()
 
                if cursor.rowcount > 0:
                    dmsg = 'Deleted successfully'
                else:
                    dmsg = 'No matching product found'
            else:
                dmsg = 'Please enter product ID'
        else:
            dmsg = 'Invalid request method'
 
    return render_template("manageinv.html", dmsg=dmsg)
 
 
 
 
@app.route('/manageinv', methods=['GET', 'POST'])
def manageinv():
    logging.debug('manageinv Module')
    msg = ''
    return render_template('manageinv.html', msg=msg)
 
 

#############################################################








@app.route('/place_order', methods=['POST'])
def place_order():
      # Check if the user is authenticated
    if 'username' not in session:
        return redirect(url_for('login'))

    # Connect to the MySQL database
    # Connect to the MySQL database
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute( """
    SELECT CP.main_id, P.productid, P.productname, P.price, P.product_category
    FROM cartproducts CP
    JOIN Customer_product P ON CP.product_id = P.productid
    JOIN cart C ON CP.cart_Id = C.Id
    JOIN accounts U ON C.user_id = U.id
    WHERE U.username = %s
    """, (session['username'],))
    cart_products = cursor.fetchall()
	
    
    # Calculate the total price of the cart
    cursor.execute('CALL GetTotal(%s);', (session['username'],))
    total_price = cursor.fetchone()['SUM(P.Price)']

     # Retrieve shipping info from database
    select_user_id_query = "SELECT Id FROM accounts WHERE username = %s"
    cursor.execute(select_user_id_query, (session['username'],))
    user_id = cursor.fetchone()['Id']
	
    
    
    
    cursor.execute("""insert into orders (order_Id, userid, product, price, updatedDate) 
	SELECT c.id, u.id, P.productname, P.price, CURRENT_TIMESTAMP()
    FROM cartproducts CP
    JOIN Customer_product P ON CP.product_id = P.productid
    JOIN cart C ON CP.cart_Id = C.Id
    JOIN accounts U ON C.user_id = U.id
    WHERE U.username = %s""" ,(session['username'],) )
    mysql.connection.commit()
    order_id = cursor.lastrowid

    cursor.callproc('ProcessOrders')
   
    cursor.execute("SELECT Id FROM cart WHERE user_id = %s", (user_id,))
    cart_id = cursor.fetchone()['Id']
	
    
	
    delete_cart_products_query = "DELETE FROM cartproducts WHERE cart_Id = %s"
    cursor.execute(delete_cart_products_query, (cart_id,))
    mysql.connection.commit()
    
    
    cursor.execute( """
    SELECT * FROM ShippingDetails
    INNER JOIN accounts ON ShippingDetails.UserId = accounts.id
     WHERE accounts.username = %s
    """, (session['username'],))
    shipping_info = cursor.fetchall()

    

 
            
    cursor.close()
  
    cart_count = get_cart_count()
    # Render the template and pass the cart data to it
    return render_template('order_confirmation.html',cart_count=cart_count,cart_products=cart_products,total_price=total_price,shipping_info=shipping_info,order_id = order_id)





@app.route('/checkout', methods=['GET', 'POST'])
def checkout():
    # Check if the user is authenticated
    if 'username' not in session:
        return redirect(url_for('login'))

    # Connect to the MySQL database
    # Connect to the MySQL database
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute( """
    SELECT CP.main_id, P.productid, P.productname, P.price, P.product_category
    FROM cartproducts CP
    JOIN Customer_product P ON CP.product_id = P.productid
    JOIN cart C ON CP.cart_Id = C.Id
    JOIN accounts U ON C.user_id = U.id
    WHERE U.username = %s
    """, (session['username'],))
    cart_products = cursor.fetchall()

    # Calculate the total price of the cart
    cursor.execute("""
    SELECT SUM(P.Price)
    FROM cartproducts as CP
    JOIN Customer_product as P ON CP.product_Id = P.productid
    JOIN cart as C ON CP.cart_Id = C.Id
    JOIN accounts as U ON C.user_Id = U.Id
    WHERE U.username = %s
    """, (session['username'],))
    total_price = cursor.fetchone()['SUM(P.Price)']

     # Retrieve shipping info from database
   

    cursor.execute( """
    SELECT * FROM ShippingDetails
    INNER JOIN accounts ON ShippingDetails.UserId = accounts.id
     WHERE accounts.username = %s
    """, (session['username'],))
    shipping_info = cursor.fetchall()

            # Close the cursor and connection
            
    cursor.close()
  

    # Render the template and pass the cart data to it
    return render_template('checkout.html',
                           cart_products=cart_products,
                           total_price=total_price,
                           shipping_info=shipping_info)






# Route for adding shipping information
@app.route('/shipping', methods=['GET', 'POST'])
def shipping():
    # Check if the user is authenticated
    if 'username' not in session:
        return redirect(url_for('login'))

    if request.method == 'POST':
        if 'delete_shipping' in request.form:
            # Delete shipping information
            shipping_id = request.form.get('delete_shipping')
            # Connect to the MySQL database
            cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
            cursor.execute("DELETE FROM ShippingDetails WHERE Id = %s"
            , (shipping_id,))
            mysql.connection.commit()

        
            cursor.close()
          

            # Redirect the user back to the shipping page
            return redirect(url_for('shipping'))

        else:
            # Retrieve shipping information from the form
            full_name = request.form.get('full_name')
            street_address = request.form.get('street_address')
            city = request.form.get('city')
            state_province = request.form.get('state_province')
            postal_code = request.form.get('postal_code')
            country = request.form.get('country')

            # Connect to the MySQL database
            cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)

            # Retrieve the user's ID
            cursor.execute( "SELECT Id FROM accounts WHERE username = %s"
            , (session['username'],))
            user_id = cursor.fetchone()['Id']

            # Insert the shipping information into the shipping table
            cursor.execute("""
            INSERT INTO ShippingDetails (UserId, Full_Name, Street_Address, City, State_Province, Postal_Code, Country)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,(user_id, full_name, street_address, city, state_province, postal_code, country))
            
            mysql.connection.commit()

        
            

            # Retrieve shipping info from database
            cursor.execute( """
            SELECT * FROM ShippingDetails
            INNER JOIN accounts ON ShippingDetails.UserId = accounts.id
            WHERE accounts.username = %s
            """, (session['username'],))
            shipping_info = cursor.fetchall()

            # Close the cursor and connection
            cursor.close()
   

            # redirect the user back to the shipping page
            return render_template('shipping.html', shipping_info=shipping_info)

    # If it's a GET request, render the shipping information form
    # Retrieve existing shipping info from database
    # Connect to the MySQL database
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute( """
    SELECT * FROM ShippingDetails
    INNER JOIN accounts ON ShippingDetails.UserId = accounts.id
    WHERE accounts.username = %s
    """, (session['username'],))
    shipping_info = cursor.fetchall()

    # Close the cursor and connection
    cursor.close()
    

    return render_template('shipping.html', shipping_info=shipping_info)








@app.route('/add_to_cart', methods=['POST'])
def add_to_cart():
    if 'username' not in session:
        return redirect(url_for('login'))

    # Retrieve the product ID from the request form
    product_id = request.form.get('product_id')

    # Connect to the MySQL database
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute( "SELECT Id FROM cart WHERE user_id = (SELECT id FROM accounts WHERE username = %s)", (session['username'],))
    cart_row = cursor.fetchone()

    # Check if the user has an active cart
    if cart_row:
        cart_id = cart_row['Id']
    else:
        # If the user does not have a cart, create a new cart
        cursor.execute( "INSERT INTO cart (user_id) SELECT id FROM accounts WHERE username = %s",(session['username'],))
        mysql.connection.commit()

        # Retrieve the new cart ID
        cart_id = cursor.lastrowid

    # Insert the product into the user's cart
    cursor.execute( "INSERT INTO cartproducts (cart_Id, product_id) VALUES (%s, %s)", (cart_id, product_id))
    mysql.connection.commit()
    cursor.close()
    

    # Redirect back to the products page
    return redirect('cart')


def get_cart_count():
    # Check if the user is authenticated
    if 'username' in session:
        # Connect to the MySQL database
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute( """
        SELECT COUNT(CP.product_id)
        FROM cartproducts CP
        JOIN cart C ON CP.cart_Id = C.Id
        JOIN accounts U ON C.user_Id = U.Id
        WHERE U.username = %s
        """,(session['username'],))
        cart_count = cursor.fetchone()['COUNT(CP.product_id)']

        # Close the cursor and connection
        cursor.close()
       

        return cart_count

    pass





@app.route('/cart')
def cart():
    # Check if the user is authenticated
    if 'username' not in session:
        return redirect(url_for('login'))

    # Connect to the MySQL database
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute( """
    SELECT CP.main_id, P.productid, P.productname, P.price, P.product_category
    FROM cartproducts CP
    JOIN Customer_product P ON CP.product_id = P.productid
    JOIN cart C ON CP.cart_Id = C.Id
    JOIN accounts U ON C.user_id = U.id
    WHERE U.username = %s
    """, (session['username'],))
    cart_products = cursor.fetchall()

    # Calculate the total price of the cart
    cursor.execute("""
    SELECT SUM(P.Price)
    FROM cartproducts as CP
    JOIN Customer_product as P ON CP.product_Id = P.productid
    JOIN cart as C ON CP.cart_Id = C.Id
    JOIN accounts as U ON C.user_Id = U.Id
    WHERE U.username = %s
    """, (session['username'],))
    total_price = cursor.fetchone()['SUM(P.Price)']

     # Retrieve shipping info from database
    cursor.close()
    

    # Render the template and pass the cart data and shipping information to it
    return render_template('cart.html', cart_products=cart_products, total_price=total_price)


@app.route('/remove_from_cart', methods=['POST'])
def remove_from_cart():
	if request.method == 'POST':
		product_to_remove = request.form.get('product_id')
		cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
		
		try:
			cursor.execute("SELECT Id FROM cart WHERE user_id = (SELECT id FROM accounts WHERE username = %s)", (session['username'],))
			cart_id = cursor.fetchone()['Id']
			cursor.execute("DELETE FROM cartproducts WHERE cart_Id = %s AND main_id = %s", (cart_id, product_to_remove))
			mysql.connection.commit()
		except Exception as e:
			return f"Error occurred: {e}"
		finally:
			cursor.close()
			return redirect('cart')
	return "Invalid request"


@app.route('/products')
def index():
	
	if 'username' in session:
	 # Connect to the MySQL database
		cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
		cursor.execute("select * from Customer_product")
		products = cursor.fetchall()

		cursor.execute("SELECT username FROM accounts where username =%s", (session['username'],))
		account = cursor.fetchall()

		cart_count = get_cart_count()	
		return render_template('index.html', products=products, account = account, cart_count=cart_count)
	return render_template('login.html')
		




@app.route('/')
@app.route('/login', methods=['GET', 'POST'])
def login():
	
	msg = ''
	if request.method == 'POST' and 'username' in request.form and 'password' in request.form:
		username = request.form['username']
		password = request.form['password']
		cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
		cursor.execute(
			'SELECT * FROM accounts WHERE username = % s \
			AND password = % s', (username, password, ))
		account = cursor.fetchone()
		if account:
			session['loggedin'] = True
			session['id'] = account['id']
			session['username'] = account['username']
			session['userType'] = account['userType']
			return redirect('home')
		else:
            
			msg = 'Incorrect username / password !'
    
	return render_template('login.html', msg=msg)



@app.route('/home')
def home():
    # Check if the user is authenticated
    if 'username' in session:
        if session['userType'] == 'admin':
            return redirect('broker')
        elif session['userType'] == 'user':
            return redirect('products')
		
        else:
            
            return redirect('seller')
    else:
        return redirect(url_for('login'))




@app.route('/logout')
def logout():
    session.pop('loggedin', None)
    session.pop('id', None)
    session.pop('username', None)
    return redirect(url_for('login'))




@app.route('/register', methods=['GET', 'POST'])
def register():
    msg = ''
    if request.method == 'POST' and 'username' in request.form and 'password' in request.form and 'email' in request.form and 'phone' in request.form  and 'street' in request.form and 'city' in request.form and 'state' in request.form and 'country' in request.form and 'usertype' in request.form:
        username = request.form['username']
        password = request.form['password']
        email = request.form['email']
        phone = request.form['phone']
        street = request.form['street']
        city = request.form['city']
        state = request.form['state']
        country = request.form['country']
        usertype= request.form['usertype']
        #logging.debug('Register Module')
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute(
            'SELECT * FROM accounts WHERE username = % s', (username, ))
        account = cursor.fetchone()
        if account:
            msg = 'Account already exists !'
        elif not re.match(r'[^@]+@[^@]+\.[^@]+', email):
            msg = 'Invalid email address !'
        elif not re.match(r'[A-Za-z0-9]+', username):
            msg = 'name must contain only characters and numbers !'
        else:
            cursor.execute('INSERT INTO accounts VALUES \
            (NULL, % s, % s, % s, % s, % s, % s, % s, % s, % s)',
                        (username, password, email,
                        phone, street, city,
                            state, country, usertype, ))
            mysql.connection.commit()
            msg = 'You have successfully registered !'
    elif request.method == 'POST':
        msg = 'Please fill out the form !'
    return render_template('register.html', msg=msg)






	

 






@app.route("/display")
def display():
	if 'loggedin' in session:
		cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
		cursor.execute('SELECT * FROM accounts WHERE id = % s',
					(session['id'], ))
		account = cursor.fetchone()
		return render_template("userprofile.html", account=account)
	return redirect(url_for('login'))


@app.route("/update", methods=['GET', 'POST'])
def update():
	msg = ''
	if 'loggedin' in session:
		if request.method == 'POST' and 'username' in request.form and 'password' in request.form and 'email' in request.form and 'phone' in request.form and 'street' in request.form and 'city' in request.form and 'state' in request.form and 'country' in request.form:
			username = request.form['username']
			password = request.form['password']
			email = request.form['email']
			phone = request.form['phone']
			street = request.form['street']
			city = request.form['city']
			state = request.form['state']
			country = request.form['country']
			
			cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
			cursor.execute(
				'SELECT * FROM accounts WHERE username = % s',
					(username, ))
			account = cursor.fetchone()
			if account:
				msg = 'Account already exists !'
			elif not re.match(r'[^@]+@[^@]+\.[^@]+', email):
				msg = 'Invalid email address !'
			elif not re.match(r'[A-Za-z0-9]+', username):
				msg = 'name must contain only characters and numbers !'
			else:
				cursor.execute('UPDATE accounts SET username =% s,\
				password =% s, email =% s, phone =% s, \
				street =% s, city =% s, state =% s, \
				country =% s WHERE id =% s', (
					username, password, email, phone, 
				street, city, state, country,
				(session['id'], ), ))
				mysql.connection.commit()
				msg = 'You have successfully updated !'
		elif request.method == 'POST':
			msg = 'Please fill out the form !'
		return render_template("update.html", msg=msg)
	return redirect(url_for('login'))


@app.route("/delete", methods=['GET', 'POST'])
def delete():
	msg = ''
	if 'loggedin' in session:
		if request.method == 'POST' in request.form:
			cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
			cursor.execute('DELETE FROM accounts WHERE id = % s', ((session['id'], ), ))
			mysql.connection.commit()
			msg = 'You have successfully deleted this user !'
			session['loggedin'] = True
		elif request.method == 'POST':
			msg = 'Please fill out the form !'
		return render_template("dlete.html", msg=msg)
	return redirect(url_for('login'))



if __name__ == "__main__":
	app.run(host="localhost", port=int("5000"), debug=True)
