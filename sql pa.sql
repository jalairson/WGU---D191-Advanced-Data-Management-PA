-------------------------------------------------------------------------------------------------
-- detailed table

CREATE FUNCTION condense_name(first_name VARCHAR(45), last_name VARCHAR(45))
RETURNS VARCHAR(90)
LANGUAGE plpgsql
AS $$
DECLARE full_name VARCHAR(90);
BEGIN
SELECT CONCAT (last_name, ', ', first_name)
INTO full_name;
RETURN full_name;
END;
$$;

CREATE TABLE customer_rental (
customer_id INT,
customer_name VARCHAR(90),
customer_email VARCHAR(50),
rental_date TIMESTAMP,
return_date TIMESTAMP
);

INSERT INTO customer_rental (
customer_id, customer_name, customer_email, rental_date, return_date
) 
SELECT customer.customer_id, condense_name(customer.first_name, customer.last_name), customer.email AS customer_email, rental.rental_date, rental.return_date
FROM customer
JOIN rental
ON customer.customer_id = rental.customer_id
ORDER BY customer_id;

SELECT * FROM customer_rental
ORDER BY customer_name;

-------------------------------------------------------------------------------------------------
-- summary table

CREATE TABLE customer_rental_summary (
customer_id INT,
customer_name VARCHAR(90),
num_rentals INT
);

INSERT INTO customer_rental_summary (
customer_id, customer_name, num_rentals)
SELECT customer_rental.customer_id, customer_rental.customer_name,
COUNT (customer_rental.customer_id)
FROM customer_rental
GROUP BY customer_id, customer_name
ORDER BY customer_id;

SELECT * FROM customer_rental_summary
ORDER BY customer_name;

CREATE FUNCTION refresh_summary_on_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE full_name VARCHAR(90);
BEGIN
DELETE FROM customer_rental_summary;
INSERT INTO customer_rental_summary (
customer_id, customer_name, num_rentals)
SELECT customer_rental.customer_id, customer_rental.customer_name,
COUNT (customer_rental.customer_id)
FROM customer_rental
GROUP BY customer_id, customer_name
ORDER BY customer_id;
END;
$$;

CREATE TRIGGER refresh_cr_summary
AFTER INSERT ON customer_rental
FOR EACH STATEMENT
EXECUTE PROCEDURE refresh_summary_on_trigger();

-------------------------------------------------------------------------------------------------
-- detailed + summary refresh

CREATE OR REPLACE PROCEDURE refresh_cr_all()
LANGUAGE plpgsql
AS $$
BEGIN

DELETE FROM customer_rental;
DELETE FROM customer_rental_summary;

INSERT INTO customer_rental (
customer_id, customer_name, customer_email, rental_date, return_date
) 
SELECT customer.customer_id, condense_name(customer.first_name, customer.last_name), customer.email AS customer_email, rental.rental_date, rental.return_date
FROM customer
JOIN rental
ON customer.customer_id = rental.customer_id
ORDER BY customer_id
LIMIT 1000;

INSERT INTO customer_rental_summary (
customer_id, customer_name, num_rentals)
SELECT customer_rental.customer_id, customer_rental.customer_name,
COUNT (customer_rental.customer_id)
FROM customer_rental
GROUP BY customer_id, customer_name
ORDER BY customer_id;

END;
$$;
