SELECT * 
FROM PortfolioProject_1..CovidDeaths$
ORDER BY 3,4

SELECT * 
FROM PortfolioProject_1..CovidVax$
ORDER BY 3,4

--View data that we are going to be using

SELECT Location, Date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject_1..CovidDeaths$
ORDER BY 1,2



--Look at total deaths vs total cases

--Need to alter the total_deaths and total_cases from nvarchar to numeric (recieved error when tried to divide) 

ALTER TABLE PortfolioProject_1.dbo.CovidDeaths$
ALTER COLUMN total_cases numeric
ALTER TABLE PortfolioProject_1.dbo.CovidDeaths$
ALTER COLUMN total_deaths numeric


--Can now perform aggregate function to compare cases vs deaths 

SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 
FROM PortfolioProject_1..CovidDeaths$
ORDER BY 1,2


--If you want to compare cases vs deaths for specific country

SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 
FROM PortfolioProject_1..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2


--Look @ total case vs population for US (shows what percent of Population has Covid)

SELECT Location, Date, total_cases, population, (total_cases/population)*100 AS PercentCovid
FROM PortfolioProject_1..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2


----Look at Countries with Highest Infection Rate compared to Population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentCovid
FROM PortfolioProject_1..CovidDeaths$
GROUP BY location, population
ORDER BY PercentCovid DESC


--Show countries with Highest Death Count per Population 

SELECT Location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject_1..CovidDeaths$
GROUP BY location
ORDER BY TotalDeathCount DESC


--Running the above query gives death count but also includes columns like 'high income' or continents rather than countries.
--To remedy we add a where statement 

SELECT Location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject_1..CovidDeaths$
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


----Lets break things down by continent just to see continent with highest death count per population.

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject_1..CovidDeaths$
WHERE continent is NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject_1..CovidDeaths$
WHERE continent is NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC




-- GLOBAL NUMBERS 

--need to include NULLIF to avoid division by zero error.
SELECT  Date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as TotalDeathPercentage
FROM PortfolioProject_1..CovidDeaths$
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2




--JOINING BOTH TABLES
SELECT * 
FROM PortfolioProject_1..CovidDeaths$ dea
JOIN PortfolioProject_1..CovidVax$ vac
	ON dea.location = vac.location 
	AND dea.date = vac.date

--Looking at Total Pop vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject_1..CovidDeaths$ dea
JOIN PortfolioProject_1..CovidVax$ vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3

--Want to add a new count that provides a total count as days go on 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location 
	ORDER BY dea.location, dea.date) as RollingPPLVaccinated 
FROM PortfolioProject_1..CovidDeaths$ dea
JOIN PortfolioProject_1..CovidVax$ vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3


--USING CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPPLVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location 
	ORDER BY dea.location, dea.date) as RollingPPLVaccinated 
FROM PortfolioProject_1..CovidDeaths$ dea
JOIN PortfolioProject_1..CovidVax$ vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER BY 2,3
)
SELECT * , (RollingPPLVaccinated/Population)*100
FROM PopvsVAC


--Could also use TEMP TABLE 
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population numeric,
new_vaccinations numeric,
RollingPPLVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location 
	ORDER BY dea.location, dea.date) as RollingPPLVaccinated 
FROM PortfolioProject_1..CovidDeaths$ dea
JOIN PortfolioProject_1..CovidVax$ vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL 
--ORDER BY 2,3

SELECT * , RollingPPLVaccinated/Population*100
FROM #PercentPopulationVaccinated






--Creating View to store data 

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location 
	ORDER BY dea.location, dea.date) as RollingPPLVaccinated 
FROM PortfolioProject_1..CovidDeaths$ dea
JOIN PortfolioProject_1..CovidVax$ vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT * 
FROM PercentPopulationVaccinated