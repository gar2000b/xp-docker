-- Insert consumer group leases
-- These represent the available consumer groups that services can acquire leases for
INSERT INTO consumer_group_leases (consumer_group_name) VALUES
('xp-marketdata-service-group-1'),
('xp-marketdata-service-group-2'),
('xp-marketdata-service-group-3');
