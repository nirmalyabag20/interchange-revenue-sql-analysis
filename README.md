# Interchange Revenue Analytics — Project Report

## Overview

This project looks at a sample interchange transaction dataset — 600 rows covering June to August 2025, with 152 merchants, 65 cards, and two networks (STAR and Visa). The goal was simple: figure out where the revenue is actually coming from, whether it's healthy, and where the risks or opportunities are.

I looked at this from four different angles, the way different teams inside a bank or payments company would each care about different things:

1. Revenue Concentration (risk)
2. PIN vs PINLESS (pricing/product)
3. Card/Customer Segmentation (growth)
4. Network Comparison — STAR vs Visa (operations)

---

## 1. Data Preparation

Before doing any analysis, I checked the data was actually trustworthy:

- Imported the CSV into SQL Server
- Checked column data types made sense
- Checked for missing/null values, both overall and column by column
- Checked for duplicate rows, using the ID column, a combination of ID + date, and a window function to catch exact duplicates
- Checked for invalid or badly formatted dates
- Checked for anything that shouldn't logically happen — negative money amounts, blank merchant names, zero transaction counts
- Cleaned up extra whitespace in text fields
- I also found a few negative amounts in the settlement/revenue columns. Instead of just "fixing" them, I looked into it first, since negative amounts can be legit refunds, not errors. [Fill in what you actually found here — were they refunds, errors, or something else?]

---

## 2. Revenue Concentration (Risk)

**Question I was trying to answer:** Are we relying too much on a small number of merchants or customers?

**What I found:**
- 14 out of 152 merchants (about 9%) bring in half of all revenue
- 44 out of 152 merchants (about 29%) bring in 80% of revenue
- Same pattern with cards — just 5 out of 65 cards (about 8%) generate half the revenue
- The biggest one: my top 3 merchants alone make up almost 27% of total revenue

**Why this matters:**
Basically, a small handful of merchants and customers are carrying most of the business. If even 2-3 of the top merchants left, we'd lose over a quarter of our revenue overnight. That's a real risk — it means the business should probably be paying extra attention to keeping these top accounts happy, since losing even a few of them would hurt a lot more than losing dozens of the smaller ones.

---

## 3. PIN vs PINLESS (Pricing/Product)

**Question I was trying to answer:** Does PIN or PINLESS make more money per transaction, and should the business push merchants toward one or the other?

**What I found:**
- At first glance, PINLESS looked way more profitable — a 0.88% rate vs PIN's 0.09%, almost 10x higher
- But when I dug in, I noticed something odd: every single PIN transaction in this dataset is Debit. PINLESS, on the other hand, is a mix of Debit and Credit
- So I compared debit-to-debit instead: PIN-Debit is 0.09%, PINLESS-Debit is 0.17% — still higher, but only about 1.85x, not 10x
- Credit transactions (which only show up under PINLESS here) have a much higher rate — 1.47% — and that's really what was driving the original 10x number

**Why this matters:**
The first number I got was misleading — it looked like a PIN vs PINLESS story, but it was actually a Debit vs Credit story in disguise. Once I isolated it properly, PINLESS still earns a bit more than PIN, but the real lesson here is that whether a transaction is Debit or Credit matters way more to profitability than whether it's PIN or PINLESS.

---

## 4. Card/Customer Segmentation (Growth)

**Question I was trying to answer:** Who are the most valuable customers, and what makes them valuable?

**What I found:**
- I split cards into three groups based on how many different merchants they used: Loyal (5 or fewer merchants), Moderate (6-15), and Broad (16+)
- Broad spenders: only 4 cards, but they average $76.86 in revenue each
- Moderate spenders: 22 cards, averaging $13.24 each
- Loyal spenders: 39 cards, averaging just $2.69 each
- So the "Broad" cards — just 6% of all cards — are worth about 29x more on average than the "Loyal" ones

**Why this matters:**
This was actually one of my favorite findings. It's not just about who spends the most transactions — it's about how spread out their spending is. Customers who shop around across lots of merchants turn out to be way more valuable than customers who stick to just one or two places. If I were advising the business, I'd say: find ways to encourage "Moderate" customers to become "Broad" ones, since that's where the real value is.

---

## 5. Network Comparison — STAR vs Visa (Operations)

**Question I was trying to answer:** Is STAR or Visa the better network to be processing through?

**What I found:**
- On the surface, Visa looked way better — a 1.47% rate compared to STAR's 0.11%, about 13.5x higher
- But then I checked the Product Type breakdown and found something important: every single STAR transaction is Debit, and every single Visa transaction is Credit. There's zero overlap.
- That means I actually can't fairly compare STAR and Visa here — I'd just be comparing Debit vs Credit again, wearing a different label

**Why this matters:**
Instead of forcing a conclusion the data can't really support, I think the honest answer here is: this dataset doesn't let us compare STAR and Visa properly, because they never process the same type of transaction. That's actually a useful finding on its own — it tells us that if we want to compare networks fairly in the future, we need data where both networks handle both Debit and Credit.

---

## Overall Summary

Across all four angles, one theme kept showing up: **a small number of accounts are doing most of the work.** A handful of top merchants and a small group of "broad-spending" cards account for a disproportionate share of total revenue. That's both a risk (losing a few key accounts would hurt a lot) and an opportunity (growing more of these high-value accounts could meaningfully boost revenue).

I also learned that some comparisons that look obvious at first — like PIN vs PINLESS or STAR vs Visa — turned out to be misleading once I checked what else was going on underneath. In both cases, the real driver was actually Debit vs Credit, not the thing I was originally comparing. That was probably the most useful lesson from this whole project: always double-check a surprising number before trusting it.

**A few things I'd suggest if this were a real business:**
1. Focus extra attention on the top merchants and "Broad" customers, since losing them would hurt the most
2. Think about Debit vs Credit as the main lever for pricing decisions, not PIN vs PINLESS or STAR vs Visa
3. Collect more balanced data going forward, so networks and product types aren't always tied to each other — that would make future comparisons more reliable
