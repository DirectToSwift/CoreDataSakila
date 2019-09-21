# CoreData Sakila w/ N:M Tables

A Sakila database model for CoreData, also known as the DVD Rentals database.

This variant preserves the N:M tables in Sakila:
`film_actor` and `film_category`.
In other words, you need to take two hops. Which isn't really necessary in
CoreData.

The only "extra" column the N:M tables have is the `last_update` (every table
in Sakila has that).

## Adjustments for CoreData

The only column rename necessary is `film.description`, which is now called
`film.summary`.

## ER Diagram

<img src="https://www.jooq.org/img/sakila.png">

## Who

Brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We like
[feedback](https://twitter.com/ar_institute),
GitHub stars,
cool [contract work](http://zeezide.com/en/services/services.html),
presumably any form of praise you can think of.
