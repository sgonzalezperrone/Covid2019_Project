SELECT *
FROM `my-project-covid-395800.CD.CovidDeaths`
order by 3,4

--Select Data that we are going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `my-project-covid-395800.CD.CovidDeaths`
order by 1, 2

--Looking at Total Cases vs Total Deaths
--"Show the probability of dying if you contract COVID."

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM `my-project-covid-395800.CD.CovidDeaths`
order by 1, 2

--In Argentina

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM `my-project-covid-395800.CD.CovidDeaths`
WHERE location like '%Argentina%'
order by 1, 2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid

SELECT location, date, population, total_cases,  (total_cases/population)*100 AS CasesPercentage
FROM `my-project-covid-395800.CD.CovidDeaths`
WHERE location like '%Argentina%'
order by 1, 2

--Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS HighestInfectionRate
FROM `my-project-covid-395800.CD.CovidDeaths`
GROUP BY location, population
order by HighestInfectionRate desc

--Showing Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM `my-project-covid-395800.CD.CovidDeaths`
WHERE continent is not NULL --Cuando el valor es null, trasladan el nombre del continente a la columna de location. Como resultado salen los          --continentes en la lista.
GROUP BY location 
ORDER BY TotalDeathCount DESC

--Showing Continents with Highest Death Count per Populatio

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM `my-project-covid-395800.CD.CovidDeaths`
WHERE continent is not NULL 
GROUP BY continent 
ORDER BY TotalDeathCount DESC

--Global Numbers

SELECT date, SUM(new_cases), SUM(new_deaths), SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage --Error division by zero: 0 / 0
FROM `my-project-covid-395800.CD.CovidDeaths`
WHERE continent is not NULL
GROUP BY date
order by 1, 2

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
SUM(new_deaths)/NULLIF(SUM(new_cases), 0)*100 as DeathPercentage --This function is useful for avoiding division by zero errors, as you can use it to replace a zero value with NULL, which will prevent the error from occurring.
FROM `my-project-covid-395800.CD.CovidDeaths`
WHERE continent is not NULL
--GROUP BY date
ORDER BY 1, 2

--Looking at Total Population vs Vaccinations

SELECT *
FROM `my-project-covid-395800.CD.CovidDeaths` dea
JOIN `my-project-covid-395800.CD.CovidVaccinations` vac
  ON dea.location = vac.location AND dea.date = vac.date
--El tipo de JOIN que se está utilizando en el script que proporcionaste es un INNER JOIN. Un INNER JOIN devuelve solo las filas de ambas tablas que cumplen con la condición especificada en la cláusula ON. En este caso, solo se devolverán las filas donde el valor de la columna location y la columna date sean iguales en ambas tablas

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM `my-project-covid-395800.CD.CovidDeaths` dea
JOIN `my-project-covid-395800.CD.CovidVaccinations` vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not NULL --AND vac.new_vaccinations is not NULL (agregado y anda ok)
ORDER BY 1, 2, 3

--Rolling count column

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `my-project-covid-395800.CD.CovidDeaths` dea
JOIN `my-project-covid-395800.CD.CovidVaccinations` vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not NULL 
ORDER BY 1, 2, 3

--CTE (Common Table Expression)
--Envuelve todo el script pero no lo guarda, como si fuera una tabla nueva.

WITH PopvsVac
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `my-project-covid-395800.CD.CovidDeaths` dea
JOIN `my-project-covid-395800.CD.CovidVaccinations` vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not NULL --AND vac.new_vaccinations is not NULL
--ORDER BY 1, 2, 3 --The ORDER BY clause should be removed from the WITH clause and placed after the final SELECT statement.
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS Percentage
FROM PopvsVac --Usa todo lo de esta tabla temporaria para hacer mas nuevos calculo (porcentages)

--Temp Table
--La version gratuita no permite INSERT INTO pero el script esta OK

CREATE TABLE `my-project-covid-395800.CD.PercentPopulationVaccinated_tab`
(
Continent string(255),
Location string(255),
Date datetime,
Population numeric,
New_vaccionations numeric,
RollingPeopleVaccinated numeric
);
INSERT INTO `my-project-covid-395800.CD.PercentPopulationVaccinated_tab`
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `my-project-covid-395800.CD.CovidDeaths` dea
JOIN `my-project-covid-395800.CD.CovidVaccinations` vac
  ON dea.location = vac.location AND dea.date = vac.date;
--WHERE dea.continent is not NULL
SELECT *, (RollingPeopleVaccinated/population)*100 AS Percentage
FROM PopvsVac

--Creating View to store data for later visualizations

CREATE VIEW my-project-covid-395800.CD.PercentPopulationVaccinated AS --En BigQuery, cuando se crea una vista, es necesario especificar el conjunto de datos al que pertenece la vista.
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `my-project-covid-395800.CD.CovidDeaths` dea
JOIN `my-project-covid-395800.CD.CovidVaccinations` vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not NULL

--Como visualizar la tabla

SELECT *
FROM `my-project-covid-395800.CD.PercentPopulationVaccinated`