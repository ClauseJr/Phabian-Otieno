DROP TABLE IF EXISTS Books_sold;
DROP TABLE IF EXISTS Num_Customers;
DROP TABLE IF EXISTS Customer_Orders;

CREATE TABLE Books_sold(
	Book_ID	INT PRIMARY KEY,
	Title VARCHAR(100),
	Author VARCHAR(60),
	Genre VARCHAR(25),
	Published_Year SMALLINT,
	Price FLOAT,
	Stock INT
);

CREATE TABLE Num_Customers(
	Customer_ID	INT PRIMARY KEY,
	Name TEXT,
	Email TEXT,
	Phone TEXT,
	City TEXT,	
	Country TEXT
);

CREATE TABLE Customer_Orders(
	Order_ID INT PRIMARY KEY,	
	Customer_ID	INT,
	Book_ID	INT,
	Order_Date DATE,
	Quantity INT,	
	Total_Amount DECIMAL(10,2),
	CONSTRAINT fk_Book_ID FOREIGN KEY (Book_ID) REFERENCES Books_sold(Book_ID),
	CONSTRAINT fk_Customer_ID FOREIGN KEY (Customer_ID) REFERENCES Num_Customers(Customer_ID)
);

SELECT * FROM Books_sold;
SELECT * FROM Customer_Orders;
SELECT * FROM Num_Customers;