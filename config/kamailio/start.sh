#!/bin/bash

# Kamailio 데이터베이스 스키마 생성 스크립트
# 이 스크립트는 Kamailio 컨테이너 내부에서 실행됩니다.

# MariaDB 서버가 준비될 때까지 대기
echo "MariaDB 서버가 준비될 때까지 대기 중..."
sleep 15

# Kamailio 데이터베이스 스키마 생성
echo "Kamailio 데이터베이스 스키마 생성 중..."
cd /usr/share/kamailio
kamdbctl create

# 스키마 생성 확인
if [ $? -eq 0 ]; then
    echo "Kamailio 데이터베이스 스키마가 성공적으로 생성되었습니다."
else
    echo "Kamailio 데이터베이스 스키마 생성 중 오류가 발생했습니다."
    exit 1
fi

# Kamailio 서버 시작
echo "Kamailio 서버 시작 중..."
kamailio -DD -E
