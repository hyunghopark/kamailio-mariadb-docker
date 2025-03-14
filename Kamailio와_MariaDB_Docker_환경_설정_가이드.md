# Kamailio와 MariaDB Docker 환경 설정 가이드

## 목차
1. [소개](#소개)
2. [사전 요구사항](#사전-요구사항)
3. [Docker 환경 설정](#docker-환경-설정)
4. [MariaDB Docker 컨테이너 설정](#mariadb-docker-컨테이너-설정)
5. [Kamailio Docker 컨테이너 설정](#kamailio-docker-컨테이너-설정)
6. [Kamailio와 MariaDB 연동 설정](#kamailio와-mariadb-연동-설정)
7. [Docker Compose 설정](#docker-compose-설정)
8. [테스트 및 검증](#테스트-및-검증)
9. [문제 해결](#문제-해결)
10. [참고 자료](#참고-자료)

## 소개

이 가이드는 Docker 환경에서 Kamailio SIP 서버와 MariaDB 데이터베이스를 설정하고 연동하는 방법을 설명합니다. Kamailio는 오픈 소스 SIP 서버로, VoIP 및 실시간 통신을 위한 강력한 플랫폼을 제공합니다. MariaDB는 MySQL의 포크로, Kamailio의 데이터베이스 백엔드로 사용됩니다.

### Kamailio 소개

Kamailio(이전 OpenSER 및 SER)는 GPLv2+ 라이선스로 배포되는 오픈 소스 SIP 서버로, 초당 수천 개의 통화 설정을 처리할 수 있습니다. Kamailio는 VoIP 및 실시간 통신(화상 통화, WebRTC, 인스턴트 메시징 등)을 위한 대규모 플랫폼을 구축하는 데 사용할 수 있습니다. 또한 SIP-to-PSTN 게이트웨이, PBX 시스템 또는 Asterisk, FreeSWITCH, SEMS와 같은 미디어 서버의 확장에도 쉽게 사용할 수 있습니다.

주요 기능:
- 비동기 TCP, UDP 및 SCTP 지원
- TLS를 통한 보안 통신
- WebRTC를 위한 WebSocket 지원
- IPv4 및 IPv6 지원
- SIMPLE 인스턴트 메시징 및 프레즌스
- IMS 확장 기능
- ENUM 지원
- 최소 비용 라우팅
- 로드 밸런싱
- 라우팅 장애 조치
- 계정, 인증 및 권한 부여
- MySQL, Postgres, Oracle, Radius, LDAP, Redis, Cassandra, MongoDB, Memcached 등 다양한 백엔드 시스템 지원

### MariaDB 소개

MariaDB는 MySQL의 커뮤니티 개발 포크로, 오픈 소스 관계형 데이터베이스 관리 시스템(RDBMS)입니다. Kamailio는 MariaDB를 사용하여 사용자 계정, 라우팅 규칙, 통화 기록 등의 데이터를 저장하고 관리합니다.

## 사전 요구사항

이 가이드를 따르기 위해 필요한 사항:

1. Docker가 설치된 Linux 시스템 (Ubuntu 22.04 LTS 권장)
2. Docker Compose 설치
3. 기본적인 Linux 명령어 및 Docker 지식
4. SIP 프로토콜에 대한 기본 이해

### Docker 및 Docker Compose 설치

Ubuntu 22.04에 Docker 및 Docker Compose를 설치하는 방법:

```bash
# 필요한 패키지 설치
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Docker 공식 GPG 키 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Docker 저장소 추가
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Docker 설치
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Docker Compose 설치
sudo apt install -y docker-compose

# 현재 사용자를 docker 그룹에 추가 (sudo 없이 Docker 명령어 실행 가능)
sudo usermod -aG docker $USER
```

설치 후 시스템을 재부팅하거나 다음 명령어로 변경사항을 적용합니다:
```bash
newgrp docker
```

## Docker 환경 설정

Docker 환경에서 Kamailio와 MariaDB를 설정하기 위한 기본 디렉토리 구조를 생성합니다:

```bash
mkdir -p ~/kamailio-docker/{kamailio,mariadb,config}
cd ~/kamailio-docker
```

이 디렉토리 구조는 다음과 같습니다:
- `kamailio`: Kamailio 관련 파일 저장
- `mariadb`: MariaDB 데이터 저장
- `config`: 설정 파일 저장

## MariaDB Docker 컨테이너 설정

### MariaDB Docker 이미지 선택

MariaDB의 공식 Docker 이미지를 사용합니다. 최신 안정 버전을 사용하는 것이 좋지만, 특정 버전이 필요한 경우 해당 태그를 지정할 수 있습니다.

### MariaDB 설정 파일 생성

MariaDB의 문자 인코딩을 UTF-8로 설정하기 위해 다음 설정 파일을 생성합니다:

```bash
mkdir -p ~/kamailio-docker/config/mariadb
```

`~/kamailio-docker/config/mariadb/mariadb.cnf` 파일을 생성하고 다음 내용을 추가합니다:

```ini
[client]
default-character-set=utf8mb4

[mysql]
default-character-set=utf8mb4

[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
skip-character-set-client-handshake

[mysqldump]
default-character-set=utf8mb4
```

## Kamailio Docker 컨테이너 설정

### Kamailio Docker 이미지 선택

Kamailio의 공식 Docker 이미지를 사용합니다. GitHub 패키지 레지스트리에서 제공하는 이미지를 사용할 수 있습니다:
- `ghcr.io/kamailio/kamailio`: Debian 기반 이미지
- `ghcr.io/kamailio/kamailio-ci`: Alpine 기반 이미지 (더 작고 안전한 이미지)

### Kamailio 설정 파일 생성

Kamailio의 기본 설정 파일을 생성합니다:

```bash
mkdir -p ~/kamailio-docker/config/kamailio
```

`~/kamailio-docker/config/kamailio/kamailio.cfg` 파일을 생성하고 기본 설정을 추가합니다. 다음은 간단한 예시입니다:

```
#!KAMAILIO

#!define WITH_MYSQL
#!define WITH_AUTH

# 데이터베이스 URL 설정
#!define DBURL "mysql://kamailio:kamailiorw@mariadb/kamailio"

# 기본 설정
listen=udp:0.0.0.0:5060
```

## Kamailio와 MariaDB 연동 설정

### Kamailio 데이터베이스 스키마 생성

Kamailio는 MariaDB에 여러 테이블을 생성하여 사용자 정보, 라우팅 규칙 등을 저장합니다. Docker Compose 설정에서 이를 자동화할 수 있습니다.

### Kamailio 데이터베이스 연결 설정

Kamailio가 MariaDB에 연결하도록 설정하기 위해 다음 파일을 생성합니다:

`~/kamailio-docker/config/kamailio/kamctlrc` 파일:

```
DBENGINE=MYSQL
DBHOST=mariadb
DBPORT=3306
DBNAME=kamailio
DBRWUSER=kamailio
DBRWPW=kamailiorw
DBROUSER=kamailioro
DBROPW=kamailioro
```

## Docker Compose 설정

Docker Compose를 사용하여 Kamailio와 MariaDB 컨테이너를 함께 실행하고 관리합니다.

`~/kamailio-docker/docker-compose.yml` 파일을 생성하고 다음 내용을 추가합니다:

```yaml
version: '3'

services:
  mariadb:
    image: mariadb:latest
    container_name: kamailio-mariadb
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=rootpassword
      - MYSQL_DATABASE=kamailio
      - MYSQL_USER=kamailio
      - MYSQL_PASSWORD=kamailiorw
      - TZ=Asia/Seoul
    volumes:
      - ./mariadb:/var/lib/mysql
      - ./config/mariadb:/etc/mysql/conf.d
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
    networks:
      - kamailio-net

  kamailio:
    image: ghcr.io/kamailio/kamailio:latest
    container_name: kamailio-sip
    restart: always
    depends_on:
      - mariadb
    ports:
      - "5060:5060/udp"
      - "5060:5060/tcp"
      - "5061:5061/tcp"
    volumes:
      - ./config/kamailio:/etc/kamailio
    environment:
      - TZ=Asia/Seoul
      - SIP_DOMAIN=sip.example.com
    networks:
      - kamailio-net

networks:
  kamailio-net:
    driver: bridge
```

### 초기 설정 스크립트

MariaDB 컨테이너가 시작된 후 Kamailio 데이터베이스 스키마를 생성하기 위한 초기화 스크립트를 생성합니다:

`~/kamailio-docker/config/mariadb/init.sql` 파일:

```sql
-- Kamailio 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS kamailio;

-- 사용자 생성 및 권한 부여
CREATE USER IF NOT EXISTS 'kamailio'@'%' IDENTIFIED BY 'kamailiorw';
GRANT ALL PRIVILEGES ON kamailio.* TO 'kamailio'@'%';

CREATE USER IF NOT EXISTS 'kamailioro'@'%' IDENTIFIED BY 'kamailioro';
GRANT SELECT ON kamailio.* TO 'kamailioro'@'%';

FLUSH PRIVILEGES;
```

## 실행 및 테스트

### Docker Compose로 컨테이너 실행

```bash
cd ~/kamailio-docker
docker-compose up -d
```

### Kamailio 데이터베이스 스키마 생성

컨테이너가 실행된 후 Kamailio 컨테이너에 접속하여 데이터베이스 스키마를 생성합니다:

```bash
docker exec -it kamailio-sip bash
kamdbctl create
```

프롬프트에서 모든 질문에 "yes"로 답합니다.

### 상태 확인

Kamailio와 MariaDB 컨테이너가 정상적으로 실행 중인지 확인합니다:

```bash
docker ps
```

Kamailio 로그를 확인합니다:

```bash
docker logs kamailio-sip
```

### SIP 사용자 계정 생성

Kamailio에 SIP 사용자 계정을 생성합니다:

```bash
docker exec -it kamailio-sip bash
kamctl add 1001@sip.example.com password123
```

## 문제 해결

### 일반적인 문제 및 해결 방법

1. **MariaDB 연결 오류**
   - MariaDB 컨테이너가 실행 중인지 확인
   - 네트워크 설정 확인
   - 사용자 이름과 비밀번호 확인

2. **Kamailio 시작 실패**
   - 로그 확인: `docker logs kamailio-sip`
   - 설정 파일 오류 확인
   - 포트 충돌 확인

3. **SIP 등록 실패**
   - Kamailio 로그 확인
   - 방화벽 설정 확인
   - SIP 도메인 설정 확인

## 참고 자료

- [Kamailio 공식 웹사이트](https://www.kamailio.org/)
- [Kamailio Docker 이미지](https://github.com/kamailio/kamailio-docker)
- [MariaDB Docker 이미지](https://hub.docker.com/_/mariadb)
- [Kamailio 문서](https://www.kamailio.org/w/documentation/)
- [MariaDB 문서](https://mariadb.com/kb/en/documentation/)
