-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

-- finds the total number of users
SELECT COUNT(*) AS "total_users"
FROM "users";

-- Selects all users that earn interest in a fixed deposit account
SELECT "id", "first_name", "last_name" FROM "users" WHERE "id" IN (
    SELECT "user_id" FROM "user_accounts" WHERE "account_id" IN (
        SELECT "id" FROM "accounts" WHERE "type" = 'fixed deposit'
    )
);

-- finds the average account balance across all accounts
SELECT AVG("balance") AS avg_balance FROM "accounts";

-- finds the interest at a 4% p.a. earned for all fixed deposit accounts
SELECT "id", ("balance" * 0.04) AS "interest", ("balance" * 1.04) AS "new_balance" FROM "accounts"
WHERE "type" = 'fixed deposit';

-- Selects all users who are millionaires
SELECT "id", "first_name", "last_name" FROM "users" WHERE "id" IN (
    SELECT "user_id" FROM "user_accounts" WHERE "account_id" IN (
        SELECT "id" FROM "accounts" WHERE "balance" > 1000000
    )
);

-- Selects the users with the highest amount received, who have received more than 10000 transactions or $100 million in transactions
SELECT "user_id", "first_name", "last_name" FROM "debits"
WHERE "total_transactions_received" > 10000 OR "total_amount_receied" > 100000000
ORDER BY "total_amount" DESC
LIMIT 5;

-- Selects who have received more money than they have spend
SELECT "d"."user_id", "total_amount_received", "total_amount_sent", ("total_amount_received" - "total_amount_sent") AS "profit" FROM "debits" "d"
INNER JOIN "credits" "c" ON "d"."user_id" = "c"."user_id"
WHERE "profit" > 0;

-- Selects the top 10 users with the highest account balances across all accounts.
SELECT "u"."id", "u"."first_name", "u"."last_name", SUM("a"."balance") AS "total_balance" FROM "users" "u"
INNER JOIN "user_accounts" "ua" ON "u"."id" = "ua"."user_id"
INNER JOIN "accounts" "a" ON "ua"."account_id" = "a"."id"
GROUP BY "u"."id", "u"."first_name", "u"."last_name" -- Allows balances from all accounts of a user to be totalled
ORDER BY "total_balance" DESC
LIMIT 10;

-- Finds all transactions made in 2023
SELECT "id", "from_user_id", "to_user_id", "amount" FROM "transactions"
WHERE "date" BETWEEN '2023-01-01' AND '2023-12-31';

-- Finds which account type is used the least
SELECT "type", COUNT("type") AS "number" FROM "accounts"
GROUP BY "type"
ORDER BY "number" ASC;

--depositing funds into an account
UPDATE "accounts" SET "balance" = "balance" + 1000 WHERE "id" = (
    SELECT "account_id" FROM "user_accounts" WHERE "user_id" = 92
);

--withdrawing funds from an account
UPDATE "accounts" SET "balance" = "balance" - 1000 WHERE "id" = (
    SELECT "account_id" FROM "user_accounts" WHERE "user_id" = 95
);

--transferring funds between a user's accounts
BEGIN TRANSACTION;
UPDATE "accounts" SET "balance" = "balance" + 1200 WHERE "id" = (
    SELECT "account_id" FROM "user_accounts" WHERE "user_id" = 3
);
UPDATE "accounts" SET "balance" = "balance" - 1200 WHERE "id" = (
    SELECT "account_id" FROM "user_accounts" WHERE "user_id" = 3
);
COMMIT;

-- Get the total amount transferred between two users
SELECT
    (SELECT "u"."first_name" || ' ' || "u"."last_name" FROM "users" "u" WHERE "u"."id" = "t"."from_account_id") AS "from_user",
    (SELECT "u"."first_name" || ' ' || "u"."last_name" FROM "users" "u" WHERE "u"."id" = "t"."to_account_id") AS "to_user",
    SUM("t"."amount") AS "total_amount"
FROM "transactions" "t"
GROUP BY "t"."from_account_id", "t"."to_account_id";

-- gets a user's transaction history
SELECT "id", "date", "from_account_id", "to_account_id", "amount" FROM "transactions" "t"
WHERE "t"."from_account_id" IN (
    SELECT "account_id" FROM "user_accounts" WHERE "user_id" = 2
)
OR "t"."to_account_id" IN (
    SELECT "account_id" FROM "user_accounts" WHERE "user_id" = 2
)
ORDER BY "t"."date" DESC;

-- gets the users who have made 0 transactions
SELECT "u"."id", "first_name", "last_name"
FROM "users" "u"
LEFT JOIN "transactions" "t" ON "u"."id" = "t"."from_account_id" OR "u"."id" = "t"."to_account_id"
WHERE "t"."id" IS NULL;

-- resetting user password
UPDATE "users" SET "password" = "seeker26!" WHERE "id" = 5;

-- creating a new user
INSERT INTO "users" ("id", "first_name", "last_name", "age", "username", "password")
VALUES (1, "krish", "shah", 18, "krishshhah", "pizzaforlife"),
(2, "aparna", "shah", 53, "appushah", "531282");

--deleting all accounts of a user
DELETE FROM "accounts" WHERE "id" IN (
    SELECT "accounts_id" FROM "user_accounts" WHERE "user_id" IN (
        SELECT "id" FROM "users" WHERE "id" = 1
    )
);

--deleting a specific account
DELETE FROM "accounts" WHERE "id" = 2;

--finds the most popoular bank for users
SELECT "a"."num_accounts", "b"."name" FROM
(SELECT "bank_id", COUNT("bank_id") AS "num_accounts" FROM "accounts"
GROUP BY "bank_id") "a"
INNER JOIN "banks" "b" ON "a"."bank_id" = "b"."id"
ORDER BY "num_accounts" DESC
LIMIT 1;

-- Creating a new transaction
INSERT INTO "transactions" ("id", "amount", "from_account_id", "to_account_id")
VALUES (1, 1000, 1000, 1001);
