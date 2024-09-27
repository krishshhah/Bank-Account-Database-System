# Design Document

* Name: Krish Shah
* email: krishshah180@gmail.com
* edX username: KS_2407_8SE8
* GitHub username: krishshhah
* City, Country: Hong Kong SAR

Video overview: [https://youtu.be/3M8gtOwomi8](Bank.db, CS50 SQL)submit50 cs50/problems/2024/sql/project


## Scope

In this section you should answer the following questions:

What is the purpose of your database?

* To manage the user accounts and financial transactions for a financial institution, such as a bank or credit union.

Which people, places, things, etc. are you including in the scope of your database?

* Users who manage and create bank accounts

* Accounts which are linked to users and contain information on account balance and which banks it is linked to

* Banks who store accounts of certain users

* Transactions which occur between users to debit/credit money from one user's account to another user's account

* User_account_history which contains audits and accounts summaries + histories

* Attachments which are linked to certain transactions, containing proof/pictures of the transactions


Which people, places, things, etc. are *outside* the scope of your database?

* Employees, staff of the financial institution, this only includes the customers. Does not include loans, investments, insurance. No currency exchange rates system: only one currency can be used.

## Functional Requirements

In this section you should answer the following questions:

What should a user be able to do with your database?

* To transfer money between their own and others' bank accounts,
* Create types of bank accounts
* Withdraw and deposit money
* Keep track of their bank balance

What's beyond the scope of what a user should be able to do with your database?

* Cannot modify other users' bank accounts
* Cannot have a negative bank balance
* Cannot modify the account types.

## Representation

### Entities

In this section you should answer the following questions:

Which entities will you choose to represent in your database?

* users
* accounts
* banks
* transactions
* attachments
* account balance history

What attributes will those entities have?

### `users`:
Attributes: `id` (INT, primary key), `first_name` (TEXT), `last_name` (TEXT), `age` (INT), `username` (TEXT, unique), `password` (TEXT)

### `accounts`:
Attributes: `id` (INT, primary key), `type` (TEXT, check constraint), `balance` (REAL, non-negative check constraint), `bank_id` (INTEGER, foreign key)

### `banks`:
Attributes: `id` (INT, primary key), `name` (TEXT, unique), `locations` (TEXT), `branches` (INTEGER)

### `user_accounts`:
Attributes: `user_id` (INTEGER, foreign key), `account_id` (INT, foreign key)

### `transactions`:
Attributes: `id` (INTEGER, primary key), `date` (NUMERIC), `description` (TEXT), `amount` (REAL, non-negative check constraint), `from_account_id` (INTEGER, foreign key), `to_account_id` (INTEGER, foreign key)

### `attachments`:
Attributes: `id` (INTEGER, primary key), `transaction_id` (INTEGER, foreign key), `file_name` (TEXT), `file_type` (TEXT), `file` (BLOB)

### `account_balance_history`:
Attributes: `id` (INTEGER, primary key), `account_id` (INTEGER, foregin key), `balance` (REAL), `timestamp` (NUMERIC)

Why did you choose the types you did?

* REAL for balances so it can have decimals
* NUMERIC for dates so they can be filtered through
* BLOB for files so that images and audios can be stored in the database for a transaction record.

Why did you choose the constraints you did?

* CHECK for `balance` So that a balance can never be negative
* So that and so account `type` are checked for so it is clear the type of account.
* `usernames` are also UNIQUE so that they are different from user to user.

### Relationships
![ER-diagram of this database: tables, fields, and relationships](Bank-ER.png)

* `users` and `accounts` have a one to many relationship. A user can have 0 accounts, each account can only be linked to one user.
* `accounts` and `banks` have a many to one relationship. Banks can house multiple accounts, but each account can only be in one bank.
* `accounts` and `transactions` have a many to many relationship. Multiple accounts(2) and used to make multiple transactions.
* `transactions` and `attachments` have a one to many relationship. One transactions can have multiple attachements as evidence.
* `accounts` and `account_balance_history` have a one to many relationship. Each historical record can only be linked to one account: an account has multiple records of its balance history

## Optimizations

In this section you should answer the following questions:

Which optimizations (e.g., indexes, views) did you create? Why?
### `user_account_summary`
VIEW: allows all date across the "users" and "accounts" table to be combined to easily see which user has which account

### `debits`
VIEW: allows a summary to be gained on how many transcations a user has MADE/SENT and the total amount of all the transactions.

### `credits`
VIEW: allows a summary to be gained on how many transcations a user has RECEIVED and the total amount of all the transactions.

### INDEXES
All indexes include columns that are used heavily and regularly in the queries.sql file, which mostly consist of primary key columns.
* Indexes are made on `accounts`.`balance` as the balance of users is acsessed frequently and heavily for transactions
* Indexes are created on `transactions`.`from_account_id` and `transactions`.`to_account_id` to quickly access their ids and improve the speed of the transactions.
* Indexes are created on `transactions`.`date` to access which transactions have been made before, after, between a certain date.
* Indexes have been created on `accounts`.`type` to access fixed deposit accounts and other account types which have a check constraint.
* Indexes have been created on the `users`.`id` column to quickly access users and their accounts

## Limitations

In this section you should answer the following questions:

What are the limitations of your design?

* The database does not have role-based access controls, all users who have access can see all the data. mysql may need to be used instead so that certain users can only see certain tables or columns (their own data).
* It  does not consider any data backup incase of hacks.
* It does not contain any stored procedures which could be use for ease in withdrawing or depositing money to and from a bank account.

What might your database not be able to represent very well?

* The database does not handle different currencies or exhchange rates between currencies
* It doesn't show any relationships between the family of the users, where there may be joint accounts (no user-to-user) relationships.
