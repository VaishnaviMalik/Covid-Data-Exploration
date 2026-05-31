-- Initialization and schema inspection
USE covid_data_schema;
DESCRIBE coviddeaths;
DESCRIBE covidvaccinations;

-- Overview of tables
SELECT * FROM coviddeaths;
SELECT * FROM covidvaccinations;

-- Percentage of population affected by covid-19 per location
SELECT location, population, AVG((total_cases / population) * 100) AS affected_percentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY affected_percentage DESC;

-- COVID-19 metrics tracking for India specifically
SELECT AVG((total_cases / population) * 100) AS avg_cases, 
	AVG((total_deaths/ total_cases) * 100) AS death_of_affected, 
    AVG((total_deaths/population)*100) AS death_population
FROM coviddeaths 
WHERE location 
	LIKE 'India';

-- Total case counts vs total death percentages per location
SELECT location,
	MAX(total_cases) cases, 
    MAX(total_deaths) deaths,
    MAX(total_deaths) / MAX(total_cases) * 100 death_percentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY cases desc;

-- Continental breakdown of total cases vs deaths
SELECT continent,
	MAX(total_cases) AS cases, 
    MAX(total_deaths) AS deaths,
    MAX(total_deaths) / MAX(total_cases) * 100 AS death_percentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY cases desc;

-- Peak weekly icu admissions by location
SELECT location, 
	MAX(weekly_icu_admissions) AS max_weekly_icu_admissions
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location;

-- Global overall summary of death percentages
SELECT 
	SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths, 
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS death_percentage
FROM coviddeaths;

-- Calculating tracking metrics via Common Table Expressions (CTEs)
WITH PopulationVsVaccination AS(
	SELECT d.continent, 
		d.location, 
		d.date, 
		d.population,  
		v.new_vaccinations,
		SUM(CAST(v.new_vaccinations AS SIGNED)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) RollingVaccinations
	FROM coviddeaths d
	JOIN covidvaccinations v
		ON d.location = v.location AND d.date = v.date
	WHERE d.continent IS NOT NULL
)
SELECT location,
    date,
    population,
    RollingVaccinations,
    (RollingVaccinations / population) * 100 AS vacc_per_populations
FROM PopulationVsVaccination
ORDER BY location, date;
    
-- Achieving identical tracking results using Temporary Tables
DROP TEMPORARY TABLE IF EXISTS RollingPeopleVaccinated;
CREATE TEMPORARY TABLE RollingPeopleVaccinated AS
	SELECT d.continent, 
		d.location, 
		d.date, 
		d.population,  
		v.new_vaccinations,
		SUM(CAST(v.new_vaccinations AS SIGNED)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) RollingVaccinations
	FROM coviddeaths d
	JOIN covidvaccinations v
		ON d.location = v.location AND d.date = v.date
	WHERE d.continent IS NOT NULL;
SELECT location,
    date,
    population,
    RollingVaccinations,
    (RollingVaccinations / population) * 100 AS vacc_per_populations
FROM RollingPeopleVaccinated
ORDER BY location, date;

-- Creating view for the ease of data visualization
DROP VIEW IF EXISTS vw_india_covid_metrics;
CREATE VIEW vw_india_covid_metrics AS
SELECT d.date, 
	d.population,
    d.total_cases,
    d.total_deaths,
    (d.total_cases/ d.population) * 100 AS affected_percentage,
    v.total_tests,
    v.total_vaccinations,
    v.people_vaccinated,
    (v.people_vaccinated / v.total_vaccinations) * 100 AS first_dose_ratio,
    v.people_fully_vaccinated,
    (v.people_fully_vaccinated / v.total_vaccinations) * 100 AS fully_vaccinated_ratio
FROM coviddeaths d
JOIN covidvaccinations v
	ON d.location = v.location AND d.date = v.date
WHERE d.location like 'India';

-- Quering the view
SELECT * FROM vw_india_covid_metrics;

-- Master schema verification and documentation
SELECT 
    TABLE_NAME AS 'Table/View Name',
    COLUMN_NAME AS 'Column Name',
    DATA_TYPE AS 'Data Type',
    IS_NULLABLE AS 'Allows Nulls?'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'covid_data_schema'
  AND TABLE_NAME IN ('coviddeaths', 'covidvaccinations', 'vw_india_covid_metrics')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
