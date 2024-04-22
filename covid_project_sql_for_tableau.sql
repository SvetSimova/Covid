/* 

Queries used for Tableau Project

*/

-- 1. Global Numbers
select SUM(new_cases) as total_cases, 
		SUM(new_deaths) as total_deaths,
		SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 as death_percentage
from CovidProject..CovidDeaths$
where continent is not null

-- 2. 
-- We take these out as they are not included in the above queries and want to stay
-- consistent European Union is part of Europe
select location, SUM(new_deaths) as total_death_count
from CovidProject..CovidDeaths$
where continent is null
	and location not in ('World', 'European Union', 'International'
	--, 'High income', 'Low income', 'Upper middle income', 'Lower middle income'
	)
group by location
order by total_death_count desc

-- 3.
select location, population, 
		MAX(total_cases) as highest_infection_count,
		MAX(total_cases/population)*100 as percent_population_infected
from CovidProject..CovidDeaths$
group by location, population
order by percent_population_infected desc

-- 4.
select location, population, 
		MAX(total_cases) as highest_infection_count,
		MAX(total_cases/population)*100 as percent_population_infected
from CovidProject..CovidDeaths$
group by location, population, date
order by percent_population_infected desc
