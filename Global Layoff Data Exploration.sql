/*


Global Layoff Data Exploration 


*/

-- Dataset used is the cleaned data from 'Global Layoff Data Cleaning' project

SELECT *
FROM world_layoffs.layoffs_staging2;

-- Looking at Percentage to see how big these layoffs were
SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off != 0;

-- Companies that laid off 100% of their staff
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Funding for companies that laid off 100% of their staff received
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Companies with the most Total Layoffs
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;

-- Total Layoffs by Country
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;

-- Layoffs by Industry 
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;

-- Layoff by Stages
SELECT stage, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY total_laid_off DESC;


-- BREAKING DOWN BY YEAR

-- Layoffs by Year
SELECT YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY total_laid_off DESC;



-- Create CTE for Rolling Sum of Layoffs by Year-Month
WITH rolling_layoff AS
(
SELECT SUBSTRING(`date`, 1, 7) AS `Year-Month`, SUM(total_laid_off) AS sum_laid_off
FROM world_layoffs.layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) != 'None'
GROUP BY `Year-Month`
ORDER BY 1
)
SELECT `Year-Month`, sum_laid_off, SUM(sum_laid_off) OVER(ORDER BY `Year-Month`) AS rolling_total
FROM rolling_layoff;



-- Company Layoff Per Year
SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY company;

-- Company layoff Per Year, with ranking on the most layoffs
WITH company_year(company, `year`, total_laid_off) AS
(
SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company, `year`
ORDER BY company
),
# we want to only select the top 5 in each year hence create a CTE to filter on the rank
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

