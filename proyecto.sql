CREATE DATABASE Cars;
USE Cars;

/* Creación de TABLAS */
CREATE TABLE Category (
    CategoryID INT PRIMARY KEY AUTO_INCREMENT,
    CategoryName VARCHAR(50)
);

CREATE TABLE ToyotaCars (
    CarID INT PRIMARY KEY AUTO_INCREMENT,
    CategoryID INT,
    Model VARCHAR(50),
    Year INT,
    Price INT DEFAULT 0,
    Available BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID)
);

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY AUTO_INCREMENT,
    EmployeeName VARCHAR(100)
);

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerName VARCHAR(100),
    ContactNumber VARCHAR(15),
    Email VARCHAR(100),
    RFC VARCHAR(20)
);

CREATE TABLE Sales (
    SaleID INT PRIMARY KEY AUTO_INCREMENT,
    CarID INT,
    CustomerID INT,
    SaleDate DATE,
    EmployeeID INT,
    SalePrice INT,
    FOREIGN KEY (CarID) REFERENCES ToyotaCars(CarID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);
/* Creación de Vistas */

CREATE VIEW SalesReport AS
SELECT
    s.SaleID AS NumeroDeVenta,
    c.CustomerName AS NombreDelCliente,
    e.EmployeeName AS NombreDelEmpleado,
    t.Model AS ModeloDelAuto,
    s.SaleDate AS FechaDeVenta,
    s.SalePrice AS Precio
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Employees e ON s.EmployeeID = e.EmployeeID
INNER JOIN ToyotaCars t ON s.CarID = t.CarID;

CREATE VIEW InventoryStatus AS
SELECT
    t.Model AS ModeloDelAuto,
    COUNT(*) AS InventarioDisponible,
    c.CategoryName AS CategoriaDelAuto
FROM ToyotaCars t
INNER JOIN Category c ON t.CategoryID = c.CategoryID
WHERE t.Available = TRUE
GROUP BY t.Model, c.CategoryName;

CREATE VIEW EmployeePerformance AS
SELECT
    e.EmployeeID AS IDDelEmpleado,
    e.EmployeeName AS NombreDelEmpleado,
    COUNT(s.SaleID) AS TotalDeVentas,
    SUM(s.SalePrice) AS IngresosGenerados
FROM Employees e
LEFT JOIN Sales s ON e.EmployeeID = s.EmployeeID
GROUP BY e.EmployeeID, e.EmployeeName;

CREATE VIEW CustomerPurchases AS
SELECT
    c.CustomerID AS IDDelCliente,
    c.CustomerName AS NombreDelCliente,
    COUNT(s.SaleID) AS TotalDeCompras,
    SUM(s.SalePrice) AS GastoTotal
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

CREATE VIEW SalesByMonth AS
SELECT
    YEAR(s.SaleDate) AS Año,
    MONTH(s.SaleDate) AS Mes,
    COUNT(s.SaleID) AS TotalVentas,
    SUM(s.SalePrice) AS IngresosTotales
FROM Sales s
GROUP BY YEAR(s.SaleDate), MONTH(s.SaleDate);

/* Creación de procedimientos */

DELIMITER $$
CREATE PROCEDURE RegisterSale(
    IN p_carID INT,
    IN p_customerID INT,
    IN p_employeeID INT
)
BEGIN
    DECLARE v_available BOOLEAN;
    DECLARE v_price INT;

    SELECT Available INTO v_available
    FROM ToyotaCars
    WHERE CarID = p_carID;

    IF v_available = TRUE THEN

        SELECT Price INTO v_price
        FROM ToyotaCars
        WHERE CarID = p_carID;

        INSERT INTO Sales(CarID, CustomerID, SaleDate, EmployeeID, SalePrice)
        VALUES(p_carID, p_customerID, CURDATE(), p_employeeID, v_price);
        UPDATE ToyotaCars
        SET Available = FALSE
        WHERE CarID = p_carID;
    ELSE
        SELECT 'Este carro ya está vendido.' AS Mensaje;
    END IF;
END $$

CREATE PROCEDURE RegisterCustomer(
    IN p_name VARCHAR(100),
    IN p_contactNumber VARCHAR(15),
    IN p_email VARCHAR(100),
    IN p_rfc VARCHAR(20)
)
BEGIN
    INSERT INTO Customers (CustomerName, ContactNumber, Email, RFC)
    VALUES (p_name, p_contactNumber, p_email, p_rfc);
END $$

CREATE PROCEDURE UpdateCarPrice (
    IN p_carModel VARCHAR(50),
    IN p_newPrice INT
)
BEGIN
    UPDATE ToyotaCars
    SET Price = p_newPrice
    WHERE Model = p_carModel;
END $$

CREATE PROCEDURE AddNewCar (
    IN p_categoryID INT,
    IN p_model VARCHAR(50),
    IN p_year INT,
    IN p_price INT
)
BEGIN
    INSERT INTO ToyotaCars (CategoryID, Model, Year, Price, Available)
    VALUES (p_categoryID, p_model, p_year, p_price, TRUE);
END $$

CREATE PROCEDURE TotalSalesByDate (
    IN p_startDate DATE,
    IN p_endDate DATE
)
BEGIN
    SELECT COUNT(*) AS TotalVentas,
    SUM(SalePrice) AS IngresosTotales
    FROM Sales
    WHERE SaleDate BETWEEN p_startDate AND p_endDate;
END $$
DELIMITER ;

/* Creación de Triggers o Disparadores */

DELIMITER $$
CREATE TRIGGER trg_BeforeInsert_Sales
BEFORE INSERT ON Sales
FOR EACH ROW
BEGIN
    IF (SELECT Available FROM ToyotaCars WHERE CarID = NEW.CarID) = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El auto no está disponible.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_AfterInsert_Sales
AFTER INSERT ON Sales
FOR EACH ROW
BEGIN
    UPDATE ToyotaCars
    SET Available = FALSE
    WHERE CarID = NEW.CarID;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_BeforeUpdate_ToyotaCars
BEFORE UPDATE ON ToyotaCars
FOR EACH ROW
BEGIN
    IF NEW.Price < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio no puede ser negativo.';
    END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_BeforeUpdate_Customers
BEFORE UPDATE ON Customers
FOR EACH ROW
BEGIN
    SET NEW.Email = LOWER(NEW.Email);
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_BeforeInsert_ToyotaCars
BEFORE INSERT ON ToyotaCars
FOR EACH ROW
BEGIN
    DECLARE minPrice INT;

    SET minPrice = CASE NEW.CategoryID
        WHEN 1 THEN 15000  -- Sedan
        WHEN 2 THEN 25000  -- SUV
        WHEN 3 THEN 20000  -- Pickup
        ELSE 10000
    END;

    IF NEW.Price < minPrice THEN
        SET NEW.Price = minPrice;
    END IF;
END$$
DELIMITER ;

/* Creación de Funciones */

DELIMITER $$
CREATE FUNCTION CarAge(p_CarID INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE age INT;

    SELECT YEAR(CURDATE()) - Year
    INTO age
    FROM ToyotaCars
    WHERE CarID = p_CarID;

    RETURN age;
END$$
DELIMITER ;



DELIMITER $$
CREATE FUNCTION CustomerTotal(p_CustomerID INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;

    SELECT IFNULL(SUM(SalePrice),0)
    INTO total
    FROM Sales
    WHERE CustomerID = p_CustomerID;

    RETURN total;
END$$
DELIMITER ;




/* Inserciones como TEST para la base de datos */

INSERT INTO Category (CategoryName) VALUES
('Sedan'),
('SUV'),
('Pickup');

INSERT INTO Employees (EmployeeName) VALUES
('Juan Pérez'),
('María López'),
('Carlos Soto'),
('Diana Morales'),
('Luis Hernández');

INSERT INTO Customers (CustomerName, ContactNumber, Email, RFC) VALUES
('Luis Medina', '5551234567', 'luis@mail.com', 'MEDL800101XXX'),
('Ana Torres', '5559876543', 'ana@mail.com', 'TORA900202XXX'),
('Pedro Díaz', '5551122334', 'pedro@mail.com', 'DIAZ850303XXX'),
('Dylan Magallón', '5556677889', 'dylan@gmail.com', 'MAGD900404XXX'),
('Sofía Ramírez', '5554433221', 'sofia@mail.com', 'RAMS910505XXX');

CALL AddNewCar(1, 'Corolla', 2022, 25000);
CALL AddNewCar(1, 'Yaris', 2022, 20000);
CALL AddNewCar(1, 'Camry', 2023, 32000);
CALL AddNewCar(2, 'RAV4', 2021, 35000);
CALL AddNewCar(2, 'Fortuner', 2022, 38000);
CALL AddNewCar(2, 'Highlander', 2023, 42000);
CALL AddNewCar(3, 'Hilux', 2022, 30000);
CALL AddNewCar(3, 'Tundra', 2022, 45000);
CALL AddNewCar(3, 'Tacoma', 2023, 33000);
CALL AddNewCar(3, 'Land Cruiser', 2023, 85000);


CALL RegisterSale(1, 1, 1);  -- Venta de Corolla a Luis Medina por Juan Pérez
CALL RegisterSale(4, 2, 2);  -- Venta de RAV4 a Ana Torres por María López
CALL RegisterSale(7, 3, 3);  -- Venta de Hilux a Pedro Díaz por Carlos Soto
CALL RegisterSale(10, 4, 4); -- Venta de Land Cruiser a Dylan Magallón por Diana Morales