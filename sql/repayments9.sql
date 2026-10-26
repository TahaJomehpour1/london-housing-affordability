USE london_property;

SELECT year,
    ROUND(AVG(bank_rate), 2)            AS avg_bank_rate,
    ROUND(AVG(mortgage_rate_2yr_75), 2) AS avg_mortgage_rate
FROM rates
GROUP BY year
ORDER BY year;
-- Yearly average rates

CREATE OR REPLACE VIEW repayment_v AS
WITH yearly_rates AS (
    SELECT year,
        AVG(bank_rate)            AS bank_rate,
        AVG(mortgage_rate_2yr_75) AS mortgage_rate
    FROM rates
    GROUP BY year
),
loans AS (
    SELECT a.*,
        r.bank_rate,
        r.mortgage_rate,
        -- matches the 75% LTV rate series
        0.75 * a.median_price        AS loan,
        r.mortgage_rate / 100 / 12   AS monthly_rate
    FROM affordability_v a
    JOIN yearly_rates r
        ON a.sale_year = r.year
)
SELECT
    district, home_type, sale_year, sales, median_price, median_earnings,
    price_to_earnings, deposit_gap,
    ROUND(mortgage_rate, 2) AS mortgage_rate,
    ROUND(bank_rate, 2)     AS bank_rate,
    -- 25-year repayment mortgage, rate assumed constant over the term
    ROUND(loan * monthly_rate / (1 - POWER(1 + monthly_rate, -300)), 0) AS monthly_payment,
    ROUND(100 * (loan * monthly_rate / (1 - POWER(1 + monthly_rate, -300)))
          / (median_earnings / 12), 1) AS payment_pct_of_pay
FROM loans;

-- Same home, 2021 vs 2025
SELECT
    a.district, a.home_type,
    a.monthly_payment    AS payment_2021,
    b.monthly_payment    AS payment_2025,
    b.monthly_payment - a.monthly_payment AS payment_change,
    a.payment_pct_of_pay AS pct_pay_2021,
    b.payment_pct_of_pay AS pct_pay_2025
FROM repayment_v a
JOIN repayment_v b
    ON  a.district  = b.district
    AND a.home_type = b.home_type
WHERE a.sale_year = 2021
  AND b.sale_year = 2025
  AND a.payment_pct_of_pay IS NOT NULL
ORDER BY pct_pay_2025 ASC;;