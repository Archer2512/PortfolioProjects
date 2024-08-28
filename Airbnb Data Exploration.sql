/*
Airbnb Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM layoffs_staging2;

-- view the maximum layoff people and percentage laid off
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- we want to view the companies who completely went under and the total number of employees being laid off
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- we also want to see how much funding these companies who went under was getting
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Next, we want to know in general how many staffs were laid off for each company
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;

-- Vewing by country also gives us an idea which country has the most layoffs
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;

-- We want to see which year have the most layoffs
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY SUM(total_laid_off) DESC;

-- We want to add a year column to the table for Tableau analysis later 
ALTER TABLE layoffs_staging2
ADD COLUMN `Year` INT;

UPDATE layoffs_staging2
SET `Year` = YEAR(`date`);

-- checking the timeline of the dataset
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;
-- the dataset is right when the pandemic started to alomost exactly 3 years later. 

-- What industry got hit the most? 
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;

-- What stages are these companies in? 
SELECT stage, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY total_laid_off DESC;

-- rolling sum of layoffs
SELECT SUBSTRING(`date`, 1, 7) AS `Year-Month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) != 'None'
GROUP BY `Year-Month`
ORDER BY 1;

-- Create CTE for rolling sum
WITH rolling_layoff AS
(
SELECT SUBSTRING(`date`, 1, 7) AS `Year-Month`, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) != 'None'
GROUP BY `Year-Month`
ORDER BY 1
)
SELECT `Year-Month`, sum_laid_off, SUM(sum_laid_off) OVER(ORDER BY `Year-Month`) AS rolling_total
FROM rolling_layoff;

-- We also want to create a new column for Year-Month
ALTER TABLE layoffs_staging2
ADD COLUMN `Year-Month` DATE;

UPDATE layoffs_staging2
SET `Year-Month` = SUBSTRING(`date`, 1, 7);

-- Company layoff per year
SELECT company, `Year`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, `Year`
ORDER BY company;

-- Company layoff per year, and rank the year where the companies have the most layoffs
WITH company_year (company, `year`, total_laid_off) AS
(
SELECT company, `Year`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, `Year`
ORDER BY company
),
# we want to only select the top 5 in each year so making the below a CTE to filter on the rank
company_year_rank AS
(
SELECT *,
DENSE_RANK() OVER(PARTITION BY `year` ORDER BY total_laid_off DESC) AS Ranking
FROM company_year
WHERE `year` != 'None'
)
SELECT * 
FROM company_year_rank
WHERE Ranking <= 5
;

