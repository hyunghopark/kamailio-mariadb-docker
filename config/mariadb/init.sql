-- Kamailio 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS kamailio;

-- 사용자 생성 및 권한 부여
CREATE USER IF NOT EXISTS 'kamailio'@'%' IDENTIFIED BY 'kamailiorw';
GRANT ALL PRIVILEGES ON kamailio.* TO 'kamailio'@'%';

CREATE USER IF NOT EXISTS 'kamailioro'@'%' IDENTIFIED BY 'kamailioro';
GRANT SELECT ON kamailio.* TO 'kamailioro'@'%';

FLUSH PRIVILEGES;
