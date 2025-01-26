-- table for all users
CREATE TABLE `users` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `first_name` VARCHAR(50) NOT NULL,
    `last_name` VARCHAR(100) NOT NULL,
    `age` INT UNSIGNED NOT NULL,
    `username` VARCHAR(255) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`id`)
);

-- table for all accounts a user may have
CREATE TABLE `accounts` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `type` ENUM('savings', 'current', 'fixed deposit', 'money market', 'CD') NOT NULL, -- different account types
    `balance` DECIMAL(12,2) NOT NULL DEFAULT 0, -- ensuring no negative values
    `bank_id` INT UNSIGNED,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`bank_id`) REFERENCES `banks`(`id`) ON DELETE CASCADE ON UPDATE CASCADE -- optional actions
);

-- table for all the financial institutions
CREATE TABLE `banks` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL UNIQUE,
    `locations` TEXT NOT NULL,
    `branches` INT NOT NULL,
    PRIMARY KEY (`id`)
);

-- connecting users to accounts: one to many
CREATE TABLE `user_accounts` (
    `user_id` INT,
    `account_id` INT,
    PRIMARY KEY (`user_id`, `account_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`account_id`) REFERENCES `accounts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- records all transfers/payments between users
CREATE TABLE `transactions` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `description` TEXT DEFAULT NULL,
    `amount` DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK(`amount` >= 0),
    `from_account_id` INT NOT NULL,
    `to_account_id` INT NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`from_account_id`) REFERENCES `accounts`(`id`),
    FOREIGN KEY (`to_account_id`) REFERENCES `accounts`(`id`)
);

-- allows files, photos, invoices, to be linked to certain transactions: many to one.
CREATE TABLE `attachments` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `transaction_id` INT,
    `file_name` VARCHAR(100) NOT NULL,
    `file_type` CHAR(5) NOT NULL,
    `file` LONGBLOB,
    PRIMARY KEY(`id`),
    FOREIGN KEY(`transaction_id`) REFERENCES `transactions`(`id`)
);

-- makes changes to account balances for every new transaction, automatically
CREATE TRIGGER `payment`
BEFORE INSERT ON `transactions`
FOR EACH ROW
BEGIN
    -- Check if the "from_account_id" has sufficient balance
    SELECT @from_balance = `balance` FROM `accounts` WHERE `id` = NEW.`from_account_id`;
    IF @from_balance < NEW.`amount` THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;

    -- Update the balance of the "from" account
    UPDATE `accounts`
    SET `balance` = `balance` - NEW.`amount`
    WHERE `id` = NEW.`from_account_id`;

    -- Update the balance of the "to" account
    UPDATE `accounts`
    SET `balance` = `balance` + NEW.`amount`
    WHERE `id` = NEW.`to_account_id`;
END;

-- Additional check to ensure balance is positive
CREATE TRIGGER `check_balance`
AFTER UPDATE OF `balance` ON `accounts`
FOR EACH ROW
BEGIN
    IF NEW.`balance` < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Negative balance not allowed';
    END IF;
END;

-- creates a summary of all the user's accounts and balances
CREATE VIEW `user_account_summary` AS
SELECT `u`.`id` AS `user_id`, `u`.`first_name`, `u`.`last_name`, `a`.`id` AS `account_id`, `a`.`type`, `a`.`balance`
FROM `users`
INNER JOIN `user_accounts` ua ON `ua`.`user_id` = `u`.`id`
INNER JOIN `accounts` a ON `ua`.`account_id` = `a`.`id`
ORDER BY `u`.`id`;

-- records the changes in balance of an account
CREATE TABLE `account_balance_history` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `account_id` INT,
    `balance` DECIMAL(10,2) NOT NULL,
    `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(`id`),
    FOREIGN KEY(`account_id`) REFERENCES `accounts`(`id`)
);

-- after every update of balance due to a transaction, the new balance is recorded and added to the `account_balance_history` table
CREATE TRIGGER `track_balance_history`
AFTER UPDATE OF `balance` ON `accounts`
FOR EACH ROW
BEGIN
    INSERT INTO `account_balance_history` (`account_id`, `balance`)
    VALUES (NEW.`id`, NEW.`balance`);
END;

-- displays a user's activity, in terms of amount and the number of their transactions MADE
CREATE VIEW `debits` AS
SELECT
    `u`.`id` AS `user_id`,
    `u`.`first_name`,
    `u`.`last_name`,
    COUNT(`t`.`id`) AS `total_transactions_sent`,
    SUM(`t`.`amount`) AS `total_amount_sent`
FROM `users` `u`
JOIN `user_accounts` `ua` ON `u`.`id` = `ua`.`user_id`
JOIN `transactions` `t` ON `ua`.`account_id` = `t`.`from_account_id`
GROUP BY `u`.`id`;

-- displays a user's activity, in terms of amount and the number of their transactions RECEIVED
CREATE VIEW `credits` AS
SELECT
    `u`.`id` AS `user_id`,
    `u`.`first_name`,
    `u`.`last_name`,
    COUNT(`t`.`id`) AS `total_transactions_received`,
    SUM(`t`.`amount`) AS `total_amount_received`
FROM `users` `u`
JOIN `user_accounts` `ua` ON `u`.`id` = `ua`.`user_id`
JOIN `transactions` `t` ON `ua`.`account_id` = `t`.`to_account_id`
GROUP BY `u`.`id`;

-- indexes used to speed up queries
CREATE INDEX `idx_users` ON `users` (`id`);
CREATE INDEX `idx_user_accounts` ON `user_accounts` (`user_id`, `account_id`);
CREATE INDEX `idx_accounts` ON `accounts` (`type`, `balance`, `bank_id`);
CREATE INDEX `idx_transactions` ON `transactions` (`date`, `from_account_id`, `to_account_id`);
