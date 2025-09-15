# 🎬 IMDb Analytics SQL Project

## 📌 Project Overview

This project presents an **IMDb Analytics Case Study** using SQL. It explores movie performance, director and actor insights, revenue patterns, and recommendations for market expansion. The analysis leverages SQL queries on IMDb-like datasets to derive meaningful business insights.

---

## 🗂️ Dataset Schema

The database consists of the following tables:

* **movie**: Movie details including title, release year, country, language, gross income.
* **genre**: Mapping between movies and their genres.
* **director\_mapping**: Mapping of movies to directors.
* **role\_mapping**: Mapping of movies to actors/performers.
* **names**: Metadata for actors, actresses, and directors.
* **ratings**: IMDb ratings, including average rating and total votes.

---

## 📊 Key Analyses

1. **Genre Performance**

   * Identifies the **top 5 movies by average rating** in each genre.

2. **Director Insights**

   * Finds directors consistently producing **highly-rated movies** (avg rating > 8, with at least 3 movies).

3. **Actor Popularity**

   * Lists actors who frequently appear in **movies rated above 7.5**.

4. **Country & Language Analysis**

   * Compares **production volume, average ratings, and total gross income** across countries.

5. **Revenue vs Ratings**

   * Calculates the **correlation** between gross income and average ratings.

6. **Trends Over Time**

   * Tracks **yearly trends** in number of movies, ratings, and total gross.

7. **Market Expansion Recommendations**

   * Identifies **growing genres** and **profitable countries**.

8. **Recommendation System**

   * Suggests **similar movies** based on **shared directors, actors, or genres**.

---

## 🛠️ Tools & Technologies Used

* **SQL** (MySQL / PostgreSQL compatible)
* **Window Functions** (ROW\_NUMBER, aggregates)
* **CTEs (Common Table Expressions)**
* **String & Regex Functions** for cleaning gross income data

---

## 🚀 How to Run

1. Clone the repository.
2. Set up the schema with the provided tables (`movie`, `genre`, `ratings`, etc.).
3. Execute the SQL script (`imdb_analytics.sql`) in your database environment.
4. Analyze the output of each query for insights.

---

## 📎 Repository Structure

```
├── imdb_analytics.sql   # Main SQL analysis script
├── README.md            # Documentation (this file)
```

---

## 💡 Use Cases

* Identify **high-performing genres and movies** for streaming platforms.
* Help **producers and studios** understand profitable regions and genres.
* Provide a **data-driven recommendation system** for movie suggestions.

---

## 👨‍💻 Author

**Jayesh Kados**
📧 Email: [jayeshkados@gmail.com](mailto:jayeshkados@gmail.com)
🔗 [LinkedIn](https://www.linkedin.com/) | [GitHub](https://github.com/Jayesh-501)
