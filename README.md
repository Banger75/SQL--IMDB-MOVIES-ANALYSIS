# IMDb Movies Data Analysis with SQL

An exploratory SQL portfolio project analyzing IMDb movie data through **70 analytical questions**. The project demonstrates relational data exploration, query design, and ways to interpret movie, genre, and rating data.

## Project at a glance

| Area | Details |
| --- | --- |
| Domain | Movie and entertainment analytics |
| Database | MySQL |
| Techniques | Joins, CTEs, aggregations, window functions, rankings, subqueries, indexing |
| Data | Movie, ratings, genres, names, and role-mapping tables |
| Deliverable | Annotated SQL analysis and database relationship diagram |

## Questions explored

The SQL analysis includes questions such as:
- How do film counts and ratings vary across genres?
- Which movies have the highest average ratings, after applying a minimum-vote filter?
- How can movies and genres be ranked while handling tied results?
- How do movie attributes and related cast/crew records connect?
- What patterns appear across movie years, countries, languages, and ratings?

These describe the **types of analyses in the SQL file**, not independently validated conclusions.

## Repository files

- [SQL analysis](imdb_movies_analysis.sql) — SQL statements and annotated analytical questions.
- [Questions for Analysis](Questions%20for%20Analysis.pdf) — question sheet, if available in the repository.
- CSV datasets — tabular inputs used for the exercises.
- Database EER diagram — visual explanation of table relationships (below).

## SQL techniques demonstrated

- **Joins:** Combine movie, genre, rating, and contributor information.
- **Aggregations:** Use counts, averages, and grouping for summary analysis.
- **CTEs and subqueries:** Break multi-step questions into readable parts.
- **Window functions:** Compare and rank results using `RANK()`, `DENSE_RANK()`, and related functions.
- **Data exploration:** Examine table structure and basic data characteristics.
- **Indexing:** Explore indexes used to support query performance.

## Reproduce the analysis

1. Prepare a MySQL database named `imdb` and import the provided data into the corresponding tables.
2. Open [imdb_movies_analysis.sql](imdb_movies_analysis.sql) in a SQL editor or MySQL Workbench.
3. Review the setup statements before running them: some statements modify database-wide timeout settings or create indexes, so use a local practice environment.
4. Execute the analytical queries in sections and inspect the returned tables.

**Note:** An optional Python CSV-loading example is included as a comment in the SQL file. It reads `DATABASE_URL` and `IMDB_CSV_FOLDER` from your local environment. Do not commit credentials. The SQL file is a learning/analysis script, not a turnkey migration.

## Data model: EER diagram

<img width="1536" height="1024" alt="Entity relationship diagram for IMDb movie analysis tables" src="https://github.com/user-attachments/assets/cdab455d-6938-4a7a-98c4-a7f71f3e6c87" />

## Findings and limitations

This repository shows analytical methods and example queries. **Verified numerical findings are not yet documented** in this README. Query results should be run against the dataset and checked before being presented as business conclusions.

A useful analytical consideration is the number of votes behind an average movie rating. Applying a minimum-vote filter can avoid placing very sparsely rated movies at the top of a simple average-rating leaderboard; the threshold is a business assumption, not a statistical confidence guarantee.

## Planned improvements

- Add screenshots of verified query outputs and five concise insights.
- State the original dataset provenance and any redistribution permissions.
- Add a reproducible schema and import instructions.
- Document important assumptions, validation checks, and query limitations.
