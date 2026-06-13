-- =============================================
-- ohnePay — Bank Management System
-- Полная база данных (все таблицы)
-- =============================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- ---------------------------------------------
-- 1. credentials
--    Хранит номера счетов и хешированные пароли
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `credentials` (
  `AccNo` int(11) NOT NULL AUTO_INCREMENT,
  `Pass`  varchar(255) NOT NULL,
  PRIMARY KEY (`AccNo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------
-- 2. userinfo
--    Личные данные пользователей
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `userinfo` (
  `AccNo`   int(11)      NOT NULL,
  `Name`    varchar(100) NOT NULL,
  `Address` varchar(255) NOT NULL,
  `Email`   varchar(100) NOT NULL,
  PRIMARY KEY (`AccNo`),
  UNIQUE KEY `email_unique` (`Email`),
  CONSTRAINT `fk_userinfo_accno` FOREIGN KEY (`AccNo`) REFERENCES `credentials` (`AccNo`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------
-- 3. balance
--    Баланс каждого счёта
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `balance` (
  `AccNo`   int(11)        NOT NULL,
  `Balance` decimal(15, 2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`AccNo`),
  CONSTRAINT `fk_balance_accno` FOREIGN KEY (`AccNo`) REFERENCES `credentials` (`AccNo`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------
-- 4. transactions
--    История всех транзакций
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `transactions` (
  `id`         int(11)        NOT NULL AUTO_INCREMENT,
  `Sender`     int(11)        NOT NULL,
  `Receiver`   int(11)        NOT NULL,
  `Amount`     decimal(15, 2) NOT NULL,
  `Remarks`    varchar(255)            DEFAULT NULL,
  `SenBalance` decimal(15, 2)          DEFAULT NULL,
  `RecBalance` decimal(15, 2)          DEFAULT NULL,
  `DateTime`   datetime       NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_sender`   (`Sender`),
  KEY `idx_receiver` (`Receiver`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------
-- 5. admins
--    Учётные записи администраторов
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `admins` (
  `id`    int(11)      NOT NULL AUTO_INCREMENT,
  `Name`  varchar(100) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `Pass`  varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email_unique` (`Email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Администратор по умолчанию (пароль: Chikko23112000)
INSERT IGNORE INTO `admins` (`Name`, `Email`, `Pass`) VALUES
('Bekmurod Esanov', 'bekmurod04@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

-- ---------------------------------------------
-- 6. user_accounts
--    Дополнительные (суб)счета пользователей
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS `user_accounts` (
  `id`         int(11)  NOT NULL AUTO_INCREMENT,
  `OwnerAccNo` int(11)  NOT NULL,
  `SubAccNo`   int(11)  NOT NULL,
  `CreatedAt`  datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_sub`  (`SubAccNo`),
  KEY        `owner_idx`   (`OwnerAccNo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
