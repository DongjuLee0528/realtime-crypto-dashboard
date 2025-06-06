#!/bin/bash

echo "🚀 암호화폐 모니터링 시스템 시작! (30초 간격 업데이트)"

echo "*/1 * * * * root /usr/local/bin/update.sh" > /etc/cron.d/crypto-cron
echo "*/1 * * * * root sleep 30 && /usr/local/bin/update.sh" >> /etc/cron.d/crypto-cron

chmod 0644 /etc/cron.d/crypto-cron
crontab /etc/cron.d/crypto-cron

echo "⏰ Cron 작업 설정 완료 - 30초마다 업데이트"

echo "📊 첫 번째 데이터 수집 시작..."
/usr/local/bin/update.sh

echo "✅ 시스템 준비 완료! Cron 데몬 시작..."
cron -f