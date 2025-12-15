-- Consumer Group Allocation Table
-- Supports lease/lock pattern for Kafka consumer groups
-- Services acquire locks on startup and release on shutdown
-- Locks expire automatically if service becomes unhealthy
CREATE TABLE IF NOT EXISTS consumer_group_allocations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    consumer_group_name VARCHAR(255) NOT NULL UNIQUE,
    locked_by_instance_id VARCHAR(255) DEFAULT NULL COMMENT 'Instance ID of the service holding the lock',
    locked_at DATETIME DEFAULT NULL COMMENT 'When the lock was acquired',
    lock_expires_at DATETIME DEFAULT NULL COMMENT 'When the lock expires (for handling unhealthy/shutdown services)',
    
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    INDEX idx_consumer_group_name (consumer_group_name),
    INDEX idx_lock_expires_at (lock_expires_at) COMMENT 'For finding expired locks'
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_uca1400_ai_ci;
