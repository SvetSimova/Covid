select * 
from CovidProject..CovidDeaths$
where continent is not null
order by 3,4

--select * from dbo.CovidVaccinations$
--where continent is not null
--order by 3,4

-- Select Data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths$
where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, 
ROUND((CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100, 2) AS death_percentage
from CovidProject..CovidDeaths$
WHERE continent is not null
--and Location like '%Poland%'
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
Select Location, date, total_cases, population, 
ROUND((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100, 2) AS contract_percentage
from CovidProject..CovidDeaths$
WHERE continent is not null
--and Location like '%Poland%'
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population
Select Location, population,  
	MAX(total_cases) as highest_infection_count, 
	MAX(ROUND((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100, 2)) AS contract_percentage
from CovidProject..CovidDeaths$
where continent is not null
GROUP BY Location, population
order by contract_percentage desc

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continents with Highest Death Count per Population
Select continent, MAX(cast(total_deaths as bigint)) as total_death_count 
from CovidProject..CovidDeaths$
where continent is not null
GROUP BY continent
order by total_death_count desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths,
	ROUND(SUM(cast(new_deaths as bigint)) / NULLIF(CONVERT(float, SUM(new_cases)), 0) * 100, 2) as death_percentage
from CovidProject..CovidDeaths$
WHERE continent is not null
--and Location like '%Poland%'
--GROUP BY date
order by 1,2

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition by dea.Location Order by dea.Location, dea.date) as rolling_vaccinations
	--, rolling_vaccinations/population * 100
FROM CovidProject..CovidDeaths$ as dea 
	JOIN CovidProject..CovidVaccinations$ as vac 
	on dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null
order by 2, 3

-- USE CTE

WITH Pop_vs_Vac (continent, location, date, population, new_vaccination, rolling_vaccinations)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition by dea.Location Order by dea.Location, dea.date) as rolling_vaccinations
	--, rolling_vaccinations/population * 100
FROM CovidProject..CovidDeaths$ as dea 
	JOIN CovidProject..CovidVaccinations$ as vac 
	on dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, ROUND(rolling_vaccinations/population * 100, 2) as CTE
FROM Pop_vs_Vac

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime, 
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition by dea.Location Order by dea.Location, dea.date) as rolling_vaccinations
	--, rolling_vaccinations/population * 100
FROM CovidProject..CovidDeaths$ as dea 
	JOIN CovidProject..CovidVaccinations$ as vac 
	on dea.location = vac.location and dea.date = vac.date
--WHERE dea.continent is not null

SELECT *, ROUND((rolling_vaccinations/population * 100), 2) as CTE
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition by dea.Location Order by dea.Location, dea.date) as rolling_vaccinations
	--, rolling_vaccinations/population * 100
FROM CovidProject..CovidDeaths$ as dea 
	JOIN CovidProject..CovidVaccinations$ as vac 
	on dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPopulationVaccinated