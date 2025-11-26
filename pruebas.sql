--Pruebas de inserción estos son datos básicos

-- Categorías
INSERT INTO Category (CategoryName) VALUES
('Sedan'), ('SUV'), ('Pickup');

INSERT INTO ToyotaCars (CategoryID, Model, Year, Price) VALUES
(1, 'Corolla', 2022, 25000),
(1, 'Yaris', 2022, 20000),
(2, 'RAV4', 2021, 35000);

INSERT INTO Employees (EmployeeName) VALUES
('Juan Pérez'), ('María López');

INSERT INTO Customers (CustomerName, ContactNumber, Email, RFC) VALUES
('Luis Medina', '5551234567', 'luis@mail.com', 'MEDL800101XXX'),
('Ana Torres', '5559876543', 'ana@mail.com', 'TORA900202XXX');


--Probar llaves foraneas 

INSERT INTO Sales (CarID, CustomerID, SaleDate, EmployeeID, SalePrice)
VALUES (1, 1, CURDATE(), 1, 25000);

INSERT INTO Sales (CarID, CustomerID, SaleDate, EmployeeID, SalePrice)
VALUES (99, 1, CURDATE(), 1, 25000);

--Probar defaults y booleans

INSERT INTO ToyotaCars (CategoryID, Model, Year) VALUES (1, 'Camry', 2023);

SELECT * FROM ToyotaCars WHERE Model='Camry';

-- Probar triggers

-- Intentar vender el mismo auto dos veces
INSERT INTO Sales (CarID, CustomerID, SaleDate, EmployeeID, SalePrice)
VALUES (1, 2, CURDATE(), 2, 25000);

UPDATE ToyotaCars SET Price=-5000 WHERE CarID=2;

-- Probar funciones
SELECT CarAge(1);

SELECT CustomerTotal(1);

-- Probar vistas

SELECT * FROM SalesReport;
SELECT * FROM InventoryStatus;
SELECT * FROM EmployeePerformance;
SELECT * FROM CustomerPurchases;
SELECT * FROM SalesByMonth;

