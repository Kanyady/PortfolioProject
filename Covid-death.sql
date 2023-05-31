SELECT*
  FROM [portfolio_project_covid].[dbo].[Covid_deaths]
order by 3,4

  --SELECT*
  --FROM [portfolio_project_covid].[dbo].[Covid_vaccinations]
  --order by 3,4

  SELECT location, date, total_cases, new_cases, total_deaths, population
  FROM [portfolio_project_covid].[dbo].[Covid_deaths]
  order by 1, 2


  -- Looking at Total_cases Vs  Total_deaths--
  -- Shows likelyhood of dying if you contracted COVID in your country--

  SELECT location,
  date,
  CAST(total_cases AS int) AS total_cases,
  CAST(total_deaths AS int) AS total_deaths,
  (CAST(total_deaths AS float) / NULLIF(CAST(total_cases AS float), 0)) * 100 AS Death_Percentage
FROM [portfolio_project_covid].[dbo].[Covid_deaths]
where location like '%indi%'
ORDER BY location, date;

--Looking at Total_cases Vs Population--
-- Shows what percentage of population got COVID--

SELECT
  location,
  date, population,
  CAST(total_cases AS int) AS total_cases,
  (CAST(total_cases AS float) / CAST(population AS float)) * 100 AS Case_Percentage
FROM [portfolio_project_covid].[dbo].[Covid_deaths]
--WHERE location LIKE '%states%'
ORDER BY location, date;

-- Countries with highest infection rate compared to population--
SELECT
  location,
  population,
  max(cast(total_cases AS int)) AS total_cases,
  (max(cast(total_cases AS float)) / CAST(population AS float)) * 100 AS Infection_rate
FROM [portfolio_project_covid].[dbo].[Covid_deaths]
--WHERE location LIKE '%states%'
GROUP By location, population
ORDER BY Infection_rate desc;

--Countires with highest death rate per population--
SELECT
  location,
  max(cast(total_deaths AS int)) AS total_death_count
  FROM [portfolio_project_covid].[dbo].[Covid_deaths]
--WHERE location LIKE '%states%'
where continent is not null 
GROUP By location
ORDER BY total_death_count desc;

-- Breakdown by continent --
-- showing the continents with highest death counts--

SELECT
  continent,
  max(cast(total_deaths AS int)) AS total_death_count
  FROM [portfolio_project_covid].[dbo].[Covid_deaths]
--WHERE location LIKE '%states%'
where continent is not null 
GROUP By continent
ORDER BY total_death_count desc;

--Global Numbers as on youtube--
--SELECT
--  date,
--  SUM(CAST(new_cases AS int)) AS new_cases,
--  SUM(CAST(new_deaths AS int)) AS new_deaths,
--  SUM(CAST(new_deaths AS float) / NULLIF(SUM(CAST(new_cases AS float)), 0)) * 100 AS Death_Percentage
--FROM [portfolio_project_covid].[dbo].[Covid_deaths]
----where location like '%indi%'
--WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY 1;

--Global numbers--

SELECT
  SUM(CAST(new_cases AS bigint)) AS new_cases,
  SUM(CAST(new_deaths AS bigint)) AS new_deaths,
  SUM(CAST(new_deaths AS float)) / NULLIF((SELECT SUM(CAST(new_cases AS float)) FROM [portfolio_project_covid].[dbo].[Covid_deaths]), 0) * 100 AS Death_Percentage
FROM [portfolio_project_covid].[dbo].[Covid_deaths]
--where location like '%indi%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1;

--Looking at Total population and Vaccinations--
--convert(int, new_vaccinations)-- works same as cast function--
SELECT
  dea.continent,
  dea.location,
  dea.date,
  population,
  vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS rolling_vaccinations
FROM
  [portfolio_project_covid].[dbo].[Covid_deaths] dea
JOIN
  [portfolio_project_covid].[dbo].[Covid_vaccinations] vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
  vac.continent IS NOT NULL
ORDER BY
  dea.location, dea.date;


  -- Creating the table -- 
WITH popVsVac (continent, location, date, population, New_vaccination, rolling_vaccinations) AS
(
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
  FROM
    [portfolio_project_covid].[dbo].[Covid_deaths] dea
  JOIN
    [portfolio_project_covid].[dbo].[Covid_vaccinations] vac ON dea.location = vac.location AND dea.date = vac.date
  WHERE
    vac.continent IS NOT NULL
)
SELECT *, (rolling_vaccinations/population)*100
FROM popVsVac;


-- Temp table --
-- Change the table name to a different one
IF OBJECT_ID('tempdb..#VaccinatedPopulation', 'U') IS NOT NULL
    DROP TABLE #VaccinatedPopulation;

CREATE TABLE #VaccinatedPopulation (
  continent nvarchar(255),
  location nvarchar(255),
  date datetime,
  population numeric,
  new_vaccinations numeric,
  rolling_vaccinations numeric
)

INSERT INTO #VaccinatedPopulation
SELECT
  dea.continent,
  dea.location,
  dea.date,
  TRY_CONVERT(numeric(18, 0), CASE WHEN ISNUMERIC(population) = 1 THEN population ELSE NULL END) AS population,
  vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM
  [portfolio_project_covid].[dbo].[Covid_deaths] dea
JOIN
  [portfolio_project_covid].[dbo].[Covid_vaccinations] vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
  vac.continent IS NOT NULL
  AND ISNUMERIC(population) = 1;

SELECT *,
  (rolling_vaccinations / CONVERT(bigint, population) * 100)
FROM
  #VaccinatedPopulation;

  -- creating view to store data for later visualizations--





