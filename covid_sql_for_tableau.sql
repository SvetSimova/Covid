/* 

Queries used for Tableau Project

*/

-------------------------------------------------------------------------
-------------------------------------------------------------------------

-- Convert Data Types from NVARCHAR to FLOAT

-- Step 1: Add new temporary columns

ALTER TABLE CovidDeaths
ADD total_cases_ float,
	total_deaths_ float, 
	date_ Date;

ALTER TABLE CovidVaccinations
ADD total_vaccinations_ float,
	new_vaccinations_ float, 
	date_ Date;

-- Step 2: Update the new column using TRY_CONVERT to handle conversion and set null values to 0

UPDATE CovidDeaths
SET total_deaths_ = TRY_CONVERT(float, total_deaths, 0),
	total_cases_ = TRY_CONVERT(float, total_cases, 0), 
	date_ = CONVERT(Date, date);

UPDATE CovidVaccinations
SET total_vaccinations_ = TRY_CONVERT(float, total_vaccinations, 0),
	new_vaccinations_ = TRY_CONVERT(float, new_vaccinations, 0), 
	date_ = CONVERT(Date, date);

-- Step 3: Drop the old column

ALTER TABLE CovidDeaths
DROP COLUMN total_deaths, total_cases, date;

ALTER TABLE CovidVaccinations
DROP COLUMN total_vaccinations, new_vaccinations, date;

-- Step 4: Rename the temporary column to the original column name

EXEC sp_rename 'CovidDeaths.total_cases_', 'total_cases', 'COLUMN';
EXEC sp_rename 'CovidDeaths.total_deaths_', 'total_deaths', 'COLUMN';
EXEC sp_rename 'CovidDeaths.date_', 'date', 'COLUMN';

EXEC sp_rename 'CovidVaccinations.total_vaccinations_', 'total_vaccinations', 'COLUMN';
EXEC sp_rename 'CovidVaccinations.new_vaccinations_', 'new_vaccinations', 'COLUMN';
EXEC sp_rename 'CovidVaccinations.date_', 'date', 'COLUMN';


-------------------------------------------------------------------------
-------------------------------------------------------------------------
-- 1. Global Numbers
select SUM(new_cases) as total_cases, 
		SUM(new_deaths) as total_deaths
		, SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 as death_percentage
		, MAX(new_cases/population*100) as infected_percentage
from Covid_2024..CovidDeaths
where continent is not null

-- 2. 
-- We take these out as they are not included in the above queries and want to stay
-- consistent European Union is part of Europe
Select continent, MAX(total_deaths) as total_death
		, ROUND(MAX(total_deaths / population * 100), 2) AS death_percentage
		, ROUND(MAX((new_cases/population)*100), 2) as infected_percentage
From Covid_2024..CovidDeaths
Where continent is not null 
Group by continent
order by death_percentage desc

-- Showing the world statistics of deaths and infected people by YEAR --> TABLEAU

Select YEAR(date) as YEAR, SUM(new_cases) as total_cases, 
		SUM(new_deaths) as total_deaths 
		, ROUND(SUM(new_deaths)/SUM(new_cases)*100, 2) as death_percentage
		, ROUND(MAX((new_cases/population)*100), 2) as infected_percentage
From Covid_2024..CovidDeaths
where continent is not null 
Group By YEAR(date)
order by 1 desc


-- 3.
select location, population, 
		MAX(total_cases) as highest_infection_count,
		MAX(total_cases/population)*100 as percent_population_infected
from Covid_2024..CovidDeaths

group by location, population
order by percent_population_infected desc

-- 4.
select location, population, date,
		MAX(total_cases) as highest_infection_count,
		MAX(total_cases/population)*100 as percent_population_infected
from Covid_2024..CovidDeaths
group by location, population, date
order by percent_population_infected desc


----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- Poland Statistics on Months


-- 5. Total Cases vs Total Deaths vs Population (likelihood of dying from Covid & percentage of infected)

Select Location, date
		, ROUND(AVG((total_deaths/total_cases)*100), 2) as DeathPercentage
		, ROUND(AVG((total_cases/population)*100), 2) as PercentPopulationInfected
from Covid_2024..CovidDeaths
Where location like '%Poland%'
group by location, date
order by 2, 3
