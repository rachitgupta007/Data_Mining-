-- Manufacturers Table
CREATE TABLE Manufacturers (
    ManufacturerID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Country VARCHAR(50) NOT NULL
);

-- Vehicle Types Table
CREATE TABLE VehicleTypes (
    VehicleTypeID INT AUTO_INCREMENT PRIMARY KEY,
    TypeName VARCHAR(100) NOT NULL,
    Description TEXT
);

-- Cars Table
CREATE TABLE Cars (
    CarID INT AUTO_INCREMENT PRIMARY KEY,
    ManufacturerID INT NOT NULL,
    VehicleTypeID INT NOT NULL,
    ModelName VARCHAR(255) NOT NULL,
    ReleaseYear YEAR NOT NULL,
    FOREIGN KEY (ManufacturerID) REFERENCES Manufacturers(ManufacturerID),
    FOREIGN KEY (VehicleTypeID) REFERENCES VehicleTypes(VehicleTypeID)
);
CREATE INDEX idx_manufacturer_id ON Cars (ManufacturerID);
CREATE INDEX idx_vehicle_type_id ON Cars (VehicleTypeID);

-- Safety Features Table
CREATE TABLE SafetyFeatures (
    FeatureID INT AUTO_INCREMENT PRIMARY KEY,
    FeatureName VARCHAR(255) NOT NULL,
    Description TEXT
);

-- Car Safety Features Junction Table
CREATE TABLE CarSafetyFeatures (
    CarID INT NOT NULL,
    FeatureID INT NOT NULL,
    PRIMARY KEY (CarID, FeatureID),
    FOREIGN KEY (CarID) REFERENCES Cars(CarID),
    FOREIGN KEY (FeatureID) REFERENCES SafetyFeatures(FeatureID)
);
CREATE INDEX idx_car_id ON CarSafetyFeatures (CarID);
CREATE INDEX idx_feature_id ON CarSafetyFeatures (FeatureID);

-- Testing Agencies Table
CREATE TABLE TestingAgencies (
    TestingAgencyID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    AccreditedCountry VARCHAR(50) NOT NULL
);

-- Safety Ratings Table
CREATE TABLE SafetyRatings (
    RatingID INT AUTO_INCREMENT PRIMARY KEY,
    CarID INT NOT NULL,
    TestingAgencyID INT NOT NULL,
    Score DECIMAL(5,2) NOT NULL,
    Date DATE NOT NULL,
    FOREIGN KEY (CarID) REFERENCES Cars(CarID),
    FOREIGN KEY (TestingAgencyID) REFERENCES TestingAgencies(TestingAgencyID)
);
CREATE INDEX idx_car_id_safety_ratings ON SafetyRatings (CarID);
CREATE INDEX idx_testing_agency_id ON SafetyRatings (TestingAgencyID);

-- Owners Table
CREATE TABLE Owners (
    OwnerID INT AUTO_INCREMENT PRIMARY KEY,
    CarID INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    PurchaseDate DATE NOT NULL,
    FOREIGN KEY (CarID) REFERENCES Cars(CarID)
);
CREATE INDEX idx_car_id_owners ON Owners (CarID);

-- Maintenance Records Table
CREATE TABLE MaintenanceRecords (
    RecordID INT AUTO_INCREMENT PRIMARY KEY,
    CarID INT NOT NULL,
    Date DATE NOT NULL,
    Description TEXT,
    Cost DECIMAL(10, 2),
    FOREIGN KEY (CarID) REFERENCES Cars(CarID)
);
CREATE INDEX idx_maintenance_car_id ON MaintenanceRecords (CarID);

-- Detailed Safety Assessment Reports Table
CREATE TABLE SafetyAssessmentReports (
    ReportID INT AUTO_INCREMENT PRIMARY KEY,
    RatingID INT NOT NULL,
    FullReport TEXT,
    FOREIGN KEY (RatingID) REFERENCES SafetyRatings(RatingID)
);

-- Partitioning SafetyRatings by Date
ALTER TABLE SafetyRatings
    PARTITION BY RANGE(YEAR(Date)) (
    PARTITION pBefore2020 VALUES LESS THAN (2020),
    PARTITION p2020 VALUES LESS THAN (2021),
    PARTITION p2021 VALUES LESS THAN (2022),
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION pAfter2023 VALUES LESS THAN MAXVALUE
);

-- Triggers
-- Prevent deletion of manufacturers with existing cars
DELIMITER $$
CREATE TRIGGER PreventManufacturerDeletion
BEFORE DELETE ON Manufacturers
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Cars WHERE ManufacturerID = OLD.ManufacturerID) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete manufacturer with existing cars.';
    END IF;
END$$

DELIMITER ;

-- Validate new safety rating
DELIMITER $$
CREATE TRIGGER ValidateNewSafetyRating
BEFORE INSERT ON SafetyRatings
FOR EACH ROW
BEGIN
    IF NEW.Score < 1 OR NEW.Score > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Safety rating must be between 1 and 5.';
    END IF;
END$$

DELIMITER ;
DELIMITER $$
CREATE TRIGGER UpdateLastMaintenanceDate
AFTER INSERT ON MaintenanceRecords
FOR EACH ROW
BEGIN
    UPDATE Cars
    SET LastMaintenanceDate = NEW.Date
    WHERE CarID = NEW.CarID;
END$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER LogSafetyFeatureChange
AFTER INSERT ON CarSafetyFeatures
FOR EACH ROW
BEGIN
    INSERT INTO SafetyFeatureChangeLog (CarID, FeatureID, ChangeDate, ActionType)
    VALUES (NEW.CarID, NEW.FeatureID, NOW(), 'Added');
END$$

CREATE TRIGGER LogSafetyFeatureRemoval
AFTER DELETE ON CarSafetyFeatures
FOR EACH ROW
BEGIN
    INSERT INTO SafetyFeatureChangeLog (CarID, FeatureID, ChangeDate, ActionType)
    VALUES (OLD.CarID, OLD.FeatureID, NOW(), 'Removed');
END$$
DELIMITER ;
DELIMITER $$
CREATE PROCEDURE AddNewCar(
    IN carModelName VARCHAR(255),
    IN manufacturerID INT,
    IN vehicleTypeID INT,
    IN releaseYear YEAR,
    IN featureIDs VARCHAR(255) -- Comma-separated list of feature IDs
)
BEGIN
    DECLARE carID INT;

    INSERT INTO Cars (ManufacturerID, VehicleTypeID, ModelName, ReleaseYear)
    VALUES (manufacturerID, vehicleTypeID, carModelName, releaseYear);

    SET carID = LAST_INSERT_ID();

    SET @sql = CONCAT('INSERT INTO CarSafetyFeatures (CarID, FeatureID) VALUES ', REPLACE(featureIDs, ',', CONCAT(',', carID), ')'));

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$
DELIMITER ;
DELIMITER $$
CREATE PROCEDURE CalculateAverageSafetyScore(
    IN manufacturerID INT,
    OUT averageScore DECIMAL(5,2)
)
BEGIN
    SELECT AVG(Score)
    INTO averageScore
    FROM SafetyRatings
    WHERE CarID IN (SELECT CarID FROM Cars WHERE ManufacturerID = manufacturerID);
END$$
DELIMITER ;
