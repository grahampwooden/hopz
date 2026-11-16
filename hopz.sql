CREATE TABLE `alarms` (
  `id` int(6) UNSIGNED NOT NULL,
  `events_id` int(11) NOT NULL,
  `timestamp` datetime NOT NULL,
  `details` varchar(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `endpoints` (
  `id` int(6) UNSIGNED NOT NULL,
  `datetime_added` datetime NOT NULL,
  `host` varchar(64) NOT NULL,
  `host_type` enum('','tcp','udp') DEFAULT NULL,
  `host_type_port` varchar(5) DEFAULT NULL,
  `host_interval` enum('1','5','10','15','30','60','120') NOT NULL DEFAULT '1',
  `active` enum('Y','N') NOT NULL DEFAULT 'Y'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `endpoints` (`id`, `datetime_added`, `host`, `host_type`, `host_type_port`, `host_interval`, `active`) VALUES
(1, '2026-11-14 23:29:48', '4.2.2.1', NULL, NULL, '5', 'Y'),
(2, '2026-11-14 23:30:00', '8.8.8.8', NULL, NULL, '10', 'Y'),
(3, '2026-11-14 23:30:13', 'www.yahoo.com', 'tcp', '80', '15', 'Y');

CREATE TABLE `events` (
  `id` int(12) UNSIGNED NOT NULL,
  `endpoint_id` int(6) UNSIGNED NOT NULL,
  `event` varchar(18) NOT NULL,
  `timestamp` datetime NOT NULL,
  `epoch` int(12) UNSIGNED NOT NULL,
  `command_issued` varchar(64) DEFAULT NULL,
  `processed` enum('N','Y') NOT NULL DEFAULT 'N'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `feed` (
  `id` bigint(12) UNSIGNED NOT NULL,
  `events_id` int(12) UNSIGNED NOT NULL,
  `hop` smallint(3) NOT NULL,
  `hop_name` varchar(36) DEFAULT NULL,
  `ms` decimal(12,3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

ALTER TABLE `alarms`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `endpoints`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `events`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `event` (`event`),
  ADD KEY `endpoint_id` (`endpoint_id`);

ALTER TABLE `feed`
  ADD PRIMARY KEY (`id`),
  ADD KEY `events_id` (`events_id`,`hop`) USING BTREE;

ALTER TABLE `alarms`
  MODIFY `id` int(6) UNSIGNED NOT NULL AUTO_INCREMENT;

ALTER TABLE `endpoints`
  MODIFY `id` int(6) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

ALTER TABLE `events`
  MODIFY `id` int(12) UNSIGNED NOT NULL AUTO_INCREMENT;

ALTER TABLE `feed`
  MODIFY `id` bigint(12) UNSIGNED NOT NULL AUTO_INCREMENT;
COMMIT;

