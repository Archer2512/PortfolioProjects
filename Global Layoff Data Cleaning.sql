/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM world_layoffs.layoffs;

--------------------------------------------------------------------------------------------------------------------------

-- Copy data to create new table

CREATE TABLE layoffs_staging
LIKE world_layoffs.layoffs;

SELECT * 
FROM world_layoffs.layoffs_staging;

INSERT world_layoffs.layoffs_staging
SELECT *
FROM world_layoffs.layoffs;

SELECT * 
FROM world_layoffs.layoffs_staging;

--------------------------------------------------------------------------------------------------------------------------

-- 1. Remove Duplicates

SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
	ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
	FROM world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
-- There are duplicates

-- Create another table with the row_num column to delete duplicates
CREATE TABLE `world_layoffs`.`layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` text,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` text,
row_num INT
);

INSERT INTO world_layoffs.layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging;

-- Select to view the duplicates
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

-- Delete the duplicates
DELETE
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

--------------------------------------------------------------------------------------------------------------------------

-- 2. Standardizing Data

SELECT *
FROM world_layoffs.layoffs_staging2;
-- we can see that there are some spaces in front of the company names, we will use TRIM on them

SELECT company, (TRIM(company))
FROM world_layoffs.layoffs_staging2;

-- We now update the trimmed company names
UPDATE world_layoffs.layoffs_staging2
SET company = TRIM(company);



-- Check Industry
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY 1;
-- We noticed there are blank columns and duplicates such as 'Crypto', 'CryptoCurrency' and 'Crypto Currency'

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry like 'Crypto%';
-- These companies all look like cryptocurrency companies
-- We are going to update them to have the same industry name

UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';



-- Check Location
SELECT DISTINCT location
FROM world_layoffs.layoffs_staging2
ORDER BY 1;
-- no issue with location



-- Check Country
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY 1;
-- looks like there is an issue with 'United States.'
-- We will remove the '.' from United States

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

UPDATE world_layoffs.layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';



-- Change Date Type 
 
-- since there are MM/DD/YYYY, and YYYY-MM-DD format, we need to update accordingly
UPDATE layoffs_staging2
SET `date` = CASE
    -- When the date is in MM/DD/YYYY format, convert to YYYY-MM-DD format
    WHEN `date` LIKE '%/%/%' THEN STR_TO_DATE(`date`, '%m/%d/%Y')
    -- When the date is already in YYYY-MM-DD format, keep it as is
    WHEN `date` LIKE '____-__-__' THEN `date`
    ELSE NULL
END;

-- Now we can convert column type from text to date
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- Convert total_laid_off to INT
UPDATE layoffs_staging2
SET `total_laid_off` = 0
WHERE `total_laid_off` = 'None';

ALTER TABLE layoffs_staging2
MODIFY COLUMN `total_laid_off` INT;

-- Convert funds_raised_millions, since there are decimals, we will use DECIMAL type
UPDATE layoffs_staging2
SET `funds_raised_millions` = 0
WHERE `funds_raised_millions` = 'None';

ALTER TABLE layoffs_staging2
MODIFY COLUMN `funds_raised_millions` DECIMAL(10, 1);

-- Convert percentage_laid_off, since there are decimals, we will use DECIMAL type
UPDATE layoffs_staging2
SET `percentage_laid_off` = 0
WHERE `percentage_laid_off` = 'None';

ALTER TABLE layoffs_staging2
MODIFY COLUMN `percentage_laid_off` DECIMAL(10, 2);

--------------------------------------------------------------------------------------------------------------------------

-- 3. Handling Null Values (Populate / Delete)

SELECT *
FROM layoffs_staging2
WHERE industry = 'None' 
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = "Airbnb";
-- We can see that one row states that Airbnb is in the Travel industry, we can populate that

-- Change the blank values to NULL to populate
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
    
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL)
AND t2.industry IS NOT NULL;      

-- check key layoff variables for null values
SELECT *
FROM layoffs_staging2
WHERE total_laid_off = 'None'
AND percentage_laid_off = 'None';
-- seems like there are a lot of none values and we cannot populate them so we will delete them

DELETE
FROM layoffs_staging2
WHERE total_laid_off = 'None'
AND percentage_laid_off = 'None';

SELECT *
FROM layoffs_staging2;

--------------------------------------------------------------------------------------------------------------------------

-- 4. Delete Unused Columns

-- remove redundant row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

