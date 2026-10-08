-- =====================================================================
-- Airbnb Housing Market Analysis Database (REAL DATA, Barcelona)
-- File: sql/real/01_real_data_schema.sql
-- Purpose: Final schema for the real datasets. It is based on
--          sql/mock/01_schema.sql, which stays unchanged.
-- DBMS: MySQL 8.0.16+ (CHECK constraints are enforced from this version)
-- Run: mysql -u <user> -p < sql/real/01_real_data_schema.sql
-- Note: It drops and recreates airbnb_market_real so it can be re-run.
--       It never touches the mock database airbnb_market.
--
-- CHANGES compared to the mock schema (each is marked CHANGED below):
--  C1 host.source_host_id added: keeps the Airbnb host ID.
--  C2 host_type, verified, registration_date nullable: unknown is not false.
--  C3 property_type is VARCHAR(100): 50 real categories, not 5.
--  C4 bedrooms, street_address nullable: missing in the source.
--  C5 ownership_type nullable: source gives a link, not a legal role.
--  C6 listing.source_listing_id added and UNIQUE(platform_id, source_listing_id).
--  C7 room_type gets hotel_room: 68 records in the source.
--  C8 license_number is TEXT, no UNIQUE: long and repeated in the source.
--  C9 first_listed_date, minimum_nights nullable: missing in the source.
--  C10 nightly_price, active nullable: 1,938 prices missing, activity unknown.
--  C11 housing_market_observation.avg_gross_household_income added.
--  C12 CHECK rent > 0 and income > 0 (NULL still allowed).
-- =====================================================================

DROP DATABASE IF EXISTS airbnb_market_real;
CREATE DATABASE airbnb_market_real CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE airbnb_market_real;

-- ---------------------------------------------------------------------
-- CITY
-- ---------------------------------------------------------------------
CREATE TABLE city (
    city_id     INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    country     VARCHAR(100) NOT NULL,
    UNIQUE KEY uq_city_name_country (name, country)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- NEIGHBORHOOD (belongs to a CITY)
-- ---------------------------------------------------------------------
CREATE TABLE neighborhood (
    neighborhood_id INT AUTO_INCREMENT PRIMARY KEY,
    city_id         INT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    census_code     VARCHAR(20)  NULL,
    latitude        DECIMAL(9,6) NULL,
    longitude       DECIMAL(9,6) NULL,
    CONSTRAINT fk_neighborhood_city
        FOREIGN KEY (city_id) REFERENCES city(city_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    UNIQUE KEY uq_neighborhood_census_code (census_code),
    UNIQUE KEY uq_neighborhood_city_name (city_id, name),
    CONSTRAINT chk_latitude  CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT chk_longitude CHECK (longitude BETWEEN -180 AND 180)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- REGULATION (adopted by a CITY, e.g. short-term-rental bans/limits)
-- ---------------------------------------------------------------------
CREATE TABLE regulation (
    regulation_id           INT AUTO_INCREMENT PRIMARY KEY,
    city_id                 INT NOT NULL,
    regulation_type         VARCHAR(100) NOT NULL,
    effective_from          DATE NOT NULL,
    effective_to            DATE NULL,
    annual_night_limit      SMALLINT UNSIGNED NULL,
    registration_required   BOOLEAN NOT NULL DEFAULT FALSE,
    description             TEXT NULL,
    CONSTRAINT fk_regulation_city
        FOREIGN KEY (city_id) REFERENCES city(city_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_regulation_dates
        CHECK (effective_to IS NULL OR effective_to >= effective_from)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- REGULATION_AREA — junction table: which NEIGHBORHOODs a REGULATION covers
-- ---------------------------------------------------------------------
CREATE TABLE regulation_area (
    regulation_id   INT NOT NULL,
    neighborhood_id INT NOT NULL,
    PRIMARY KEY (regulation_id, neighborhood_id),
    CONSTRAINT fk_regarea_regulation
        FOREIGN KEY (regulation_id) REFERENCES regulation(regulation_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_regarea_neighborhood
        FOREIGN KEY (neighborhood_id) REFERENCES neighborhood(neighborhood_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- HOST
-- ---------------------------------------------------------------------
CREATE TABLE host (
    host_id             INT AUTO_INCREMENT PRIMARY KEY,
    source_host_id      BIGINT UNSIGNED NULL UNIQUE, --C1: external Airbnb host ID
    host_type           ENUM('individual','professional','commercial') NULL, -- C2: was NOT NULL, now NULL allowed
    verified            BOOLEAN NULL, -- C2: was NOT NULL DEFAULT FALSE
    registration_date   DATE NULL, -- C2: was NOT NULL
    country_origin      VARCHAR(100) NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- PROPERTY (physical unit, located in a NEIGHBORHOOD)
-- ---------------------------------------------------------------------
CREATE TABLE property (
    property_id             INT AUTO_INCREMENT PRIMARY KEY,
    neighborhood_id         INT NOT NULL,
    property_type           VARCHAR(100) NOT NULL, -- C3: was ENUM with 5 values
    bedrooms                TINYINT UNSIGNED NULL, -- C4: was NOT NULL DEFAULT 0
    capacity                TINYINT UNSIGNED NOT NULL DEFAULT 1,
    street_address          VARCHAR(255) NULL, -- C4: was NOT NULL
    price_per_m2_purchased  DECIMAL(10,2) NULL,
    CONSTRAINT fk_property_neighborhood
        FOREIGN KEY (neighborhood_id) REFERENCES neighborhood(neighborhood_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_property_capacity CHECK (capacity >= 1)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- HOST_PROPERTY — junction table: which HOSTs own/manage which PROPERTYs
-- ---------------------------------------------------------------------
CREATE TABLE host_property (
    host_id             INT NOT NULL,
    property_id         INT NOT NULL,
    ownership_type      ENUM('owner','manager','agent') NULL, -- C5: was NOT NULL
    acquisition_date    DATE NULL,
    PRIMARY KEY (host_id, property_id),
    CONSTRAINT fk_hostproperty_host
        FOREIGN KEY (host_id) REFERENCES host(host_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_hostproperty_property
        FOREIGN KEY (property_id) REFERENCES property(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- PLATFORM (Airbnb, Booking.com, Vrbo, ...)
-- ---------------------------------------------------------------------
CREATE TABLE platform (
    platform_id     INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    website_url     VARCHAR(255) NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- LISTING (a PROPERTY marketed by a HOST on a PLATFORM)
-- ---------------------------------------------------------------------
CREATE TABLE listing (
        listing_id          INT AUTO_INCREMENT PRIMARY KEY,
        source_listing_id   BIGINT UNSIGNED NULL, -- C6: external Airbnb listing ID
    property_id         INT NOT NULL,
    host_id             INT NOT NULL,
    platform_id         INT NOT NULL,
    room_type           ENUM('entire_home','private_room','shared_room','hotel_room') NOT NULL, -- C7: added hotel_room
    license_number      TEXT NULL, -- C8: was VARCHAR(50) with a UNIQUE key
    first_listed_date   DATE NULL, -- C9: was NOT NULL
    last_listed_date    DATE NULL,
    minimum_nights      SMALLINT UNSIGNED NULL, -- C9: was NOT NULL DEFAULT 1
    UNIQUE KEY uq_listing_source (platform_id, source_listing_id), -- C6: new key, replaces uq_listing_license
    CONSTRAINT fk_listing_property
        FOREIGN KEY (property_id) REFERENCES property(property_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_listing_host
        FOREIGN KEY (host_id) REFERENCES host(host_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_listing_platform
        FOREIGN KEY (platform_id) REFERENCES platform(platform_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_listing_dates
        CHECK (last_listed_date IS NULL OR last_listed_date >= first_listed_date),
    CONSTRAINT chk_listing_min_nights CHECK (minimum_nights >= 1)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- LISTING_SNAPSHOT (time series: price / availability of a LISTING)
-- ---------------------------------------------------------------------
CREATE TABLE listing_snapshot (
    snapshot_id                 INT AUTO_INCREMENT PRIMARY KEY,
    listing_id                  INT NOT NULL,
    snapshot_date               DATE NOT NULL,
    nightly_price               DECIMAL(8,2) NULL, -- C10: was NOT NULL (1,938 prices missing)
    available_days_next_365     SMALLINT UNSIGNED NULL,
    active                      BOOLEAN NULL, -- C10: was NOT NULL DEFAULT TRUE (activity unknown)
    reviews_count               INT UNSIGNED NOT NULL DEFAULT 0,
    CONSTRAINT fk_snapshot_listing
        FOREIGN KEY (listing_id) REFERENCES listing(listing_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE KEY uq_snapshot_listing_date (listing_id, snapshot_date),
    CONSTRAINT chk_snapshot_price CHECK (nightly_price > 0),
    CONSTRAINT chk_snapshot_availability CHECK (available_days_next_365 BETWEEN 0 AND 365)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- HOUSING_MARKET_OBSERVATION (macro housing-market stats per NEIGHBORHOOD, over time)
-- ---------------------------------------------------------------------
CREATE TABLE housing_market_observation (
    observation_id              INT AUTO_INCREMENT PRIMARY KEY,
    neighborhood_id             INT NOT NULL,
    observation_date            DATE NOT NULL,
    avg_rent_per_m2             DECIMAL(8,2) NULL,
    avg_gross_household_income  DECIMAL(12,2) NULL, -- C11: new column (2023 income dataset)
    average_sale_price_per_m2   DECIMAL(10,2) NULL,
    long_term_rental_units      INT UNSIGNED NULL,
    relative_poverty_household  DECIMAL(5,2) NULL,
    total_households            INT UNSIGNED NULL,
    CONSTRAINT fk_observation_neighborhood
        FOREIGN KEY (neighborhood_id) REFERENCES neighborhood(neighborhood_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_rent_positive CHECK (avg_rent_per_m2 IS NULL OR avg_rent_per_m2 > 0), -- C12: new
    CONSTRAINT chk_income_positive CHECK (avg_gross_household_income IS NULL OR avg_gross_household_income > 0), -- C12: new
    UNIQUE KEY uq_observation_neighborhood_date (neighborhood_id, observation_date)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Helpful indexes for common lookups / joins used by the queries later on
-- ---------------------------------------------------------------------
CREATE INDEX idx_property_neighborhood   ON property(neighborhood_id);
CREATE INDEX idx_listing_property        ON listing(property_id);
CREATE INDEX idx_listing_host            ON listing(host_id);
CREATE INDEX idx_listing_platform        ON listing(platform_id);
CREATE INDEX idx_snapshot_listing_date   ON listing_snapshot(listing_id, snapshot_date);
CREATE INDEX idx_observation_neighborhood_date ON housing_market_observation(neighborhood_id, observation_date);
