SELECT *
FROM CovidDeaths

SELECT *
FROM CovidVaccinations

-- Select Data that are going to be used 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

-- Looking at total cases vs total deaths 
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) *100 AS death_percentage
FROM CovidDeaths
WHERE location LIKE '%Slovakia'
ORDER BY 1,2

-- Looking at total cases vs population
-- Shows what percentage of population got covid
SELECT location, date, total_cases, population, (total_cases/population) *100 AS case_percentage 
FROM CovidDeaths
WHERE location LIKE '%Slovakia'
ORDER BY 1,2

-- Looking at countries with the highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX(total_cases/population) *100 AS percentage_population_infected
FROM CovidDeaths
GROUP BY location, population
ORDER BY percentage_population_infected DESC

-- Showing countries with the highest death count per population 
-- total_deaths needed to be change to int 
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Showing the continets with the highest death count
SELECT continent, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- Global numbers 
SELECT SUM(new_cases) AS total_cases, 
SUM(CAST(new_deaths AS int)) AS total_deaths, 
SUM(CAST(new_deaths AS int)) / SUM(new_cases) *100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Joining two tables by location and date
SELECT *
FROM CovidDeaths
JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location AND
	CovidDeaths.date = CovidVaccinations.date

-- Using CTE
WITH popVSvac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) 
AS
(
-- Population vs vaccination
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations, 
SUM(CONVERT(bigint, CovidVaccinations.new_vaccinations)) OVER(PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS rolling_people_vaccinated
FROM CovidDeaths
JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location AND
	CovidDeaths.date = CovidVaccinations.date
)

SELECT *, (rolling_people_vaccinated/population) *100
FROM popVSvac

-- Temp table 
DROP TABLE IF EXISTS #PercentPopulationVaccinated --Include for alterations / no need to delete things 
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255), 
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated

SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations, 
SUM(CONVERT(bigint, CovidVaccinations.new_vaccinations)) OVER(PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS rolling_people_vaccinated
FROM CovidDeaths
JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location AND
	CovidDeaths.date = CovidVaccinations.date

SELECT *, (rolling_people_vaccinated / population) *100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations 
CREATE VIEW PercentPopulationVaccinated 
AS
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations, 
SUM(CONVERT(bigint, CovidVaccinations.new_vaccinations)) OVER(PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS rolling_people_vaccinated
FROM CovidDeaths
JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location AND
	CovidDeaths.date = CovidVaccinations.date

SELECT *
FROM PercentPopulationVaccinated