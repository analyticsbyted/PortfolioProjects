SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3, 4

--SELECT *
--FROM PortfolioProject..CovidVacinnations
--ORDER BY 3, 4


-- Select Data we are going to be using


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1, 2


-- Looking at Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- Looking at Deathrate for USA
-- Shows likelihood of dying if you contract Covid
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2


-- Looking at Total Cases vs Population
-- Shows what percentage of population contracted Covid

SELECT location, date,  population, total_cases,(total_cases/population)*100 as InfectionRate
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%'
And WHERE continent is not null
ORDER BY 1, 2


-- Looking at Countries with highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectionRate
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location, population
ORDER BY InfectionRate desc


-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- Showing continents with the highest per capita death count

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

-- (these numbers do not look accurate, trying a differnt query on the dataset)

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc
-- While these numbers appear better, this could mess up the drilldown effect in Tableau later




-- GLOBAL NUMBERS
-- By Day

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2

--global total
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
    SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1, 2


-- JOin second table

SELECT *
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinnations vac
	On dea.location = vac.location
	    and dea.date = vac.date

-- Looking at Total Population vs Vacinnations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinnations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
Order by 2,3

-- how many people in that country are vaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinnations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
Order by 2,3

-- USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
  as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinnations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--Order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac



-- TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinnations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--Order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinnations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
-- Order by 2,3


Select *
From PercentPopulationVaccinated