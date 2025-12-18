# Wilfred-s-rfm-analysis
RFM analysis is a customer segmentation method that scores customers based on Recency (R), Frequency (F), and Monetary value (M). Recency measures how recently a customer made a purchase, Frequency captures how often they buy, and Monetary shows how much they spend. This metrics help businesses identify customers and deliver personalized campaigns.

# RFM Customer Segmentation

This project implements **RFM (Recency, Frequency, Monetary) analysis** to segment customers based on their purchase behavior. RFM helps identify **high-value, loyal, or at-risk customers**, enabling personalized marketing and improved retention.

## Features
- Calculates Recency, Frequency, and Monetary scores for each customer
- Assigns RFM scores (1–5) and customer segments:
  - Champions
  - Loyal Customers
  - Potential Loyalists
  - At Risk
  - Lost Customers
- Generates actionable insights for targeted campaigns

## Data
- Source: `clean_transactions` table (invoice, quantity, unit price)
- Output: `vw_customer_rfm` view with RFM metrics, scores, and segments

## Usage
1. Connect to PostgreSQL database
2. Run the provided SQL scripts to create the RFM view
3. Analyze results in SQL or export to tools like Power BI for dashboards

## License
MIT License
