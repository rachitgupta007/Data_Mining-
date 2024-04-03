/* query to select avg no of safety feature in cars of a particular year */
SELECT c.ReleaseYear, AVG(FeatureCount) AS AvgNumberOfSafetyFeatures
FROM (
    SELECT c.CarID, c.ReleaseYear, COUNT(cs.FeatureID) AS FeatureCount
    FROM Cars c
    LEFT JOIN CarSafetyFeatures cs ON c.CarID = cs.CarID
    GROUP BY c.CarID, c.ReleaseYear
) AS CarFeatures
WHERE CarFeatures.ReleaseYear = 2022
GROUP BY CarFeatures.ReleaseYear;

/* query for avg manufacturer safety rating */
SELECT m.Name AS Manufacturer, AVG(sr.Score) AS AverageSafetyRating
FROM Manufacturers m
JOIN Cars c ON m.ManufacturerID = c.ManufacturerID
JOIN SafetyRatings sr ON c.CarID = sr.CarID
GROUP BY m.Name
ORDER BY AverageSafetyRating DESC;

/* analyze the trend in safety ratings */
SELECT c.ReleaseYear, AVG(r.Score) AS AvgSafetyRating
FROM Cars c
JOIN SafetyRatings r ON c.CarID = r.CarID
GROUP BY c.ReleaseYear
ORDER BY c.ReleaseYear;

-- 1. List of All Cars with Their Manufacturers and Release Year
-- This query lists all cars in the database, along with their manufacturers and release years, ordered by the most recent release year and manufacturer name.
SELECT c.ModelName, m.Name AS Manufacturer, c.ReleaseYear
FROM Cars c
JOIN Manufacturers m ON c.ManufacturerID = m.ManufacturerID
ORDER BY c.ReleaseYear DESC, m.Name;

-- 2. Cars with Safety Ratings Above 4.5
-- This query fetches cars that have a safety rating above 4.5, showing the model name, score, and the testing agency that provided the rating, ordered by the score in descending order.
SELECT c.ModelName, r.Score, t.Name AS TestingAgency
FROM SafetyRatings r
JOIN Cars c ON r.CarID = c.CarID
JOIN TestingAgencies t ON r.TestingAgencyID = t.TestingAgencyID
WHERE r.Score > 4.5
ORDER BY r.Score DESC;

-- 3. Count of Safety Features per Car Model
-- This query provides the number of safety features each car model has, ordered by the count of features in descending order and then by model name.
SELECT c.ModelName, COUNT(cs.FeatureID) AS NumberOfSafetyFeatures
FROM CarSafetyFeatures cs
JOIN Cars c ON cs.CarID = c.CarID
GROUP BY cs.CarID
ORDER BY NumberOfSafetyFeatures DESC, c.ModelName;

-- 4. List of Car Models and Their Owners
-- This query lists car models along with their owners, useful for seeing which models are most popular among owners or how ownership is distributed across models.
SELECT c.ModelName, o.Name AS OwnerName
FROM Owners o
JOIN Cars c ON o.CarID = c.CarID
ORDER BY c.ModelName, o.Name;

-- 5. Safety Features Not Present in Each Car Model
-- This query lists which safety features are missing from each car model, useful for identifying potential improvements or variations in safety equipment across models.
SELECT c.ModelName, f.FeatureName
FROM Cars c
CROSS JOIN SafetyFeatures f
LEFT JOIN CarSafetyFeatures cs ON c.CarID = cs.CarID AND f.FeatureID = cs.FeatureID
WHERE cs.FeatureID IS NULL
ORDER BY c.ModelName, f.FeatureName;

-- 6. Average Safety Rating by Manufacturer
-- This query calculates the average safety rating for cars by each manufacturer, providing insights into which manufacturers produce the safest cars according to the testing agencies' ratings.
SELECT m.Name AS Manufacturer, AVG(r.Score) AS AverageRating
FROM SafetyRatings r
JOIN Cars c ON r.CarID = c.CarID
JOIN Manufacturers m ON c.ManufacturerID = m.ManufacturerID
GROUP BY m.ManufacturerID
ORDER BY AverageRating DESC;

-- Advanced Analysis Queries

-- 1. List of Cars with Most Safety Features by Manufacturer
-- Identifies the car model with the most safety features for each manufacturer.
WITH SafetyFeaturesCount AS (
    SELECT c.CarID, c.ModelName, m.Name AS Manufacturer, COUNT(cs.FeatureID) AS FeatureCount
    FROM CarSafetyFeatures cs
    JOIN Cars c ON cs.CarID = c.CarID
    JOIN Manufacturers m ON c.ManufacturerID = m.ManufacturerID
    GROUP BY c.CarID
),
RankedCars AS (
    SELECT *,
    RANK() OVER(PARTITION BY Manufacturer ORDER BY FeatureCount DESC) AS Rank
    FROM SafetyFeaturesCount
)
SELECT ModelName, Manufacturer, FeatureCount
FROM RankedCars
WHERE Rank = 1;

-- 2. Average Safety Rating Per Year
-- Calculates the average safety rating for all cars released in each year.
SELECT c.ReleaseYear, AVG(r.Score) AS AvgRating
FROM SafetyRatings r
JOIN Cars c ON r.CarID = c.CarID
GROUP BY c.ReleaseYear
ORDER BY c.ReleaseYear;

-- 3. Car Models with Above-Average Safety Ratings for Their Manufacturer
-- Finds car models that have a safety rating above the average for their manufacturer.
WITH ManufacturerAvgRating AS (
    SELECT m.ManufacturerID, AVG(r.Score) AS AvgRating
    FROM SafetyRatings r
    JOIN Cars c ON r.CarID = c.CarID
    JOIN Manufacturers m ON c.ManufacturerID = m.ManufacturerID
    GROUP BY m.ManufacturerID
)
SELECT c.ModelName, m.Name AS Manufacturer, r.Score
FROM SafetyRatings r
JOIN Cars c ON r.CarID = c.CarID
JOIN Manufacturers m ON c.ManufacturerID = m.ManufacturerID
JOIN ManufacturerAvgRating mar ON m.ManufacturerID = mar.ManufacturerID
WHERE r.Score > mar.AvgRating
ORDER BY m.Name, r.Score DESC;

-- 4. Safety Features Common to All Cars of a Manufacturer
-- Lists safety features that are common to all cars produced by each manufacturer.
WITH ManufacturerFeatures AS (
    SELECT m.Name AS Manufacturer, f.FeatureName
    FROM CarSafetyFeatures csf
    JOIN Cars c ON csf.CarID = c.CarID
    JOIN Manufacturers m ON c.ManufacturerID = m.ManufacturerID
    JOIN SafetyFeatures f ON csf.FeatureID = f.FeatureID
    GROUP BY m.Name, f.FeatureName
    HAVING COUNT(DISTINCT c.CarID) = (SELECT COUNT(*) FROM Cars WHERE ManufacturerID = m.ManufacturerID)
)
SELECT Manufacturer, FeatureName
FROM ManufacturerFeatures
ORDER BY Manufacturer, FeatureName;

-- 5. Owners with Multiple Cars Having Different Safety Ratings
-- Identifies owners who have multiple cars with varying safety ratings.
WITH OwnerRatings AS (
    SELECT o.OwnerID, o.Name, r.Score
    FROM Owners o
    JOIN Cars c ON o.CarID = c.CarID
    JOIN SafetyRatings r ON c.CarID = r.CarID
)
SELECT Name
FROM OwnerRatings
GROUP BY OwnerID, Name
HAVING COUNT(DISTINCT Score) > 1;
