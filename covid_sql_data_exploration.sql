/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From Covid..CovidDeaths
where continent is not null
order by 4 desc


-------------------------------------------------------------------------
-------------------------------------------------------------------------

-- Convert Data Types from NVARCHAR to FLOAT

-- Step 1: Add new temporary columns

ALTER TABLE CovidDeaths
ADD total_cases_ float,
	total_deaths_ float;

ALTER TABLE CovidVaccinations
ADD total_vaccinations_ float,
	new_vaccinations_ float;

-- Step 2: Update the new column using TRY_CONVERT to handle conversion and set null values to 0

UPDATE CovidDeaths
SET total_deaths_ = TRY_CONVERT(float, total_deaths, 0),
	total_cases_ = TRY_CONVERT(float, total_cases, 0);

UPDATE CovidVaccinations
SET total_vaccinations_ = TRY_CONVERT(float, total_vaccinations, 0),
	new_vaccinations_ = TRY_CONVERT(float, new_vaccinations, 0);

-- Step 3: Drop the old column

ALTER TABLE CovidDeaths
DROP COLUMN total_deaths, total_cases;

ALTER TABLE CovidVaccinations
DROP COLUMN total_vaccinations, new_vaccinations;

-- Step 4: Rename the temporary column to the original column name

EXEC sp_rename 'CovidDeaths.total_cases_', 'total_cases', 'COLUMN';
EXEC sp_rename 'CovidDeaths.total_deaths_', 'total_deaths', 'COLUMN';

EXEC sp_rename 'CovidVaccinations.total_vaccinations_', 'total_vaccinations', 'COLUMN';
EXEC sp_rename 'CovidVaccinations.new_vaccinations_', 'new_vaccinations', 'COLUMN';


-------------------------------------------------------------------------
-------------------------------------------------------------------------

-- Total Cases vs Total Deaths (likelihood of dying from Covid)


Select Location, date, total_cases, total_deaths, 
		ROUND((total_deaths/total_cases)*100, 2) as DeathPercentage
From Covid..CovidDeaths
order by 1,2

-- Countries with Highest Death Count & Percentage per Population

Select Location, MAX(total_deaths) as total_death_count,
		MAX(ROUND(total_deaths /population * 100, 2)) AS deaths_percentage_total
From Covid..CovidDeaths
Where continent is not null 
Group by Location
order by 3 desc



-- Total Cases vs Population (percentage of infected)


Select Location, date, Population, total_cases,  
		ROUND((total_cases/population)*100, 2) as percent_infected
From Covid..CovidDeaths
order by 1,2

-- Countries with Highest Infection Rate compared to Population

Select Location, 
	MAX(total_cases) as highest_infection_Count,  
	ROUND(AVG((total_cases/population)*100), 2) as percent_infected_total
	, ROUND(MAX((new_cases/population)*100), 2) as percent_infected_new
From Covid..CovidDeaths
Group by Location 
order by percent_infected_new desc, location


-- STATISTICS BY CONTINENTS

-- Showing the world statistics of deaths and infected people per population by CONTINENTS

Select continent, MAX(total_deaths) as total_death
		, ROUND(MAX(total_deaths / population * 100), 2) AS death_percentage
		, ROUND(MAX((new_cases/population)*100), 2) as infected_percentage
From Covid..CovidDeaths
Where continent is not null 
Group by continent
order by death_percentage desc


-- Showing the world statistics of deaths and infected people by YEAR --> TABLEAU

Select YEAR(date) as YEAR, SUM(new_cases) as total_cases, 
		SUM(new_deaths) as total_deaths 
		, ROUND(SUM(new_deaths)/SUM(new_cases)*100, 2) as death_percentage
		, ROUND(MAX((new_cases/population)*100), 2) as infected_percentage
From Covid..CovidDeaths
where continent is not null 
Group By YEAR(date)
order by 1 desc


-- GLOBAL NUMBERS for the whole period --> TABLEAU

Select SUM(new_cases) as total_cases
	, SUM(new_deaths) as total_deaths
	, ROUND(SUM(new_deaths)/SUM(new_cases)*100, 2) as death_percentage
	, ROUND(MAX(new_cases/population*100, 2) as infected_percentage
From Covid..CovidDeaths
where continent is not null


-------------------------------------------------------------------------
-------------------------------------------------------------------------


-- Total Population vs Vaccinations (Percentage at least one Vaccine)

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(vac.new_vaccinations) OVER (
		Partition by dea.Location 
		Order by dea.location, dea.Date
		ROWS BETWEEN 1800 PRECEDING AND CURRENT ROW
		) as RollingPeopleVaccinated
From Covid..CovidDeaths dea
Join Covid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(vac.new_vaccinations) OVER (
		Partition by dea.Location, YEAR(dea.Date)
		Order by dea.location, YEAR(dea.Date)
		ROWS BETWEEN 1800 PRECEDING AND CURRENT ROW
		) as RollingPeopleVaccinated
From Covid..CovidDeaths dea
Join Covid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, ROUND((RollingPeopleVaccinated/Population)*100, 2) as RollVacPercentage
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date nvarchar(255),
Population int,
New_vaccinations int,
RollingPeopleVaccinated float
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(vac.new_vaccinations) OVER (
		Partition by dea.Location, YEAR(dea.Date)
		Order by dea.location, YEAR(dea.Date)
		ROWS BETWEEN 1800 PRECEDING AND CURRENT ROW
		) as RollingPeopleVaccinated
From Covid..CovidDeaths dea
Join Covid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *, ROUND((RollingPeopleVaccinated/Population)*100, 2) as RollVacPercentage
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(vac.new_vaccinations) OVER (
		Partition by dea.Location, YEAR(dea.Date)
		Order by dea.location, YEAR(dea.Date)
		ROWS BETWEEN 1800 PRECEDING AND CURRENT ROW
		) as RollingPeopleVaccinated
From Covid..CovidDeaths dea
Join Covid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, ROUND((RollingPeopleVaccinated/Population)*100, 2) as RollVacPercentage
From PercentPopulationVaccinated


----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- Poland Statistics on Months


-- Total Cases vs Total Deaths vs Population (likelihood of dying from Covid & percentage of infected)

Select Location, YEAR(date) AS YEAR, MONTH(date) AS Month 
		, ROUND(AVG((total_deaths/total_cases)*100), 2) as DeathPercentage
		, ROUND(AVG((total_cases/population)*100), 2) as PercentPopulationInfected
From Covid..CovidDeaths
Where location like '%Poland%'
group by location, YEAR(date), MONTH(date)
order by 2, 3


