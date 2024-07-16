CREATE DATABASE MusicStore;

USE MusicStore;


--1. Who is the senior most employee based on job title?

SELECT TOP 1 employee_id, first_name, last_name, levels 
FROM employee
ORDER BY levels DESC;

--2. Which countries have the most Invoices?

SELECT * FROM invoice;
SELECT billing_country, COUNT(*) as invoice_count
FROM invoice 
WHERE billing_country IS NOT NULL
GROUP BY billing_country
ORDER BY invoice_count DESC;

--3. What are top 3 values of total invoice?

SELECT TOP 3 total
FROM invoice
ORDER BY total DESC;

--4. Which city has the best customers We would like to throw a promotional Music Festival in the city we made the most money. 
--Write a query that returns one city that has the highest sum of invoice totals. 
--Return both the city name & sum of all invoice totals

SELECT TOP 1 billing_city, SUM(total) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC;

--5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
--Write a query that returns the person who has spent the most money

SELECT TOP 1 c.customer_id, c.first_name, c.last_name, SUM(i.total) AS invoice_total
FROM customer c
JOIN invoice i 
ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY invoice_total DESC;

--6. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--Return your list ordered alphabetically by email starting with A

SELECT DISTINCT(c.email), c.first_name, c.last_name FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email ASC;

--7. Let's invite the artists who have written the most rock music in our dataset. 
--Write a query that returns the Artist name and total track count of the top 10 rock bands

EXEC sp_rename 'dbo.album.﻿album_id', 'album_id', 'COLUMN';

SELECT TOP 10 a.artist_id,  a.name, COUNT(*) AS total_songs
FROM artist a
JOIN album al ON a.artist_id = al.artist_id
JOIN track t ON t.album_id = al.album_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY a.name, a.artist_id
ORDER BY total_songs DESC;


--8. Return all the track names that have a song length longer than the average song length. 
--Return the Name and Milliseconds for each track. 
--Order by the song length with the longest songs listed first

SELECT * FROM track;
SELECT name, milliseconds AS song_length
FROM track
WHERE milliseconds > 
(
SELECT AVG(milliseconds) 
FROM track
)
ORDER BY song_length DESC;

--9. Find how much amount spent by each customer on artists? 
--Write a query to return customer name, artist name and total spent

WITH best_selling_artist AS
(
SELECT TOP 1 a.artist_id, a.name, SUM(il.unit_price*il.quantity) AS total_spent
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN artist a ON al.artist_id = a.artist_id
GROUP BY a.artist_id, a.name
ORDER BY 3 DESC
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.name,
SUM(il.unit_price * il.quantity) AS total_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN best_selling_artist bsa ON al.artist_id = bsa.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.name
ORDER BY total_spent DESC;



--10. We want to find out the most popular music Genre for each country. 
--We determine the most popular genre as the genre with the highest amount of purchases. 
--Write a query that returns each country along with the top Genre. 
--For countries where the maximum number of purchases is shared return all Genres

WITH popular_genre AS
(
SELECT c.country, COUNT(il.quantity) AS purchases, g.name, g.genre_id,
ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS rn
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY c.country, g.name, g.genre_id
)
SELECT * FROM popular_genre
WHERE rn <= 1
ORDER BY 2 DESC;

--11. Write a query that determines the customer that has spent the most on music for each country. 
--Write a query that returns the country along with the top customer and how much they spent. 
--For countries where the top amount spent is shared, provide all customers who spent this amount

WITH top_customer AS
(
SELECT c.first_name, c.last_name, i.billing_country, SUM(i.total) AS amount_spent, 
ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) AS rn
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.first_name,c.last_name, i.billing_country
)
SELECT * FROM top_customer
WHERE rn <= 1
ORDER BY billing_country ASC;