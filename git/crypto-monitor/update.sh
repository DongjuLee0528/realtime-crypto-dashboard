#!/bin/bash

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

BACKUP_DIR="/shared/backup"
LAST_SUCCESS_FILE="$BACKUP_DIR/last_success.json"
LAST_EXCHANGE_FILE="$BACKUP_DIR/last_exchange.txt"

mkdir -p "$BACKUP_DIR"

log "🔄 암호화폐 데이터 업데이트 시작"

generate_html_header() {
    local update_time="$1"
    local api_status="$2"
    
    cat <<EOF
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="30">
    <title>실시간 암호화폐 모니터링</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; margin: 0; padding: 20px; min-height: 100vh;
        }
        .container { 
            max-width: 1400px; margin: 0 auto; padding: 30px;
            background: rgba(255,255,255,0.1); border-radius: 20px; 
            backdrop-filter: blur(20px); box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        h1 { 
            text-align: center; font-size: 2.8rem; margin-bottom: 15px;
            background: linear-gradient(45deg, #fbbf24, #f59e0b);
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }
        .update-info { 
            text-align: center; margin-bottom: 20px; opacity: 0.9;
            font-size: 1.1rem; font-weight: 500;
        }
        .status-info {
            text-align: center; margin-bottom: 20px; padding: 8px 16px; border-radius: 8px;
            font-size: 0.9rem; font-weight: 500;
        }
        .status-success { background: rgba(34,197,94,0.2); color: #4ade80; }
        .status-warning { background: rgba(251,191,36,0.2); color: #fbbf24; }
        .status-error { background: rgba(239,68,68,0.2); color: #ef4444; }
        .exchange-rate-info {
            text-align: center; margin-bottom: 20px; 
            background: rgba(251,191,36,0.2); padding: 10px 20px; border-radius: 10px;
            font-size: 1rem; font-weight: 600;
        }
        .crypto-grid { 
            display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px; margin-bottom: 30px;
        }
        .crypto-card { 
            background: rgba(255,255,255,0.12); border-radius: 18px; padding: 20px; 
            border: 1px solid rgba(255,255,255,0.2); position: relative;
            transition: all 0.3s ease; box-shadow: 0 8px 32px rgba(0,0,0,0.2);
        }
        .crypto-card:hover { 
            transform: translateY(-5px); 
            box-shadow: 0 15px 30px rgba(0,0,0,0.4);
            border-color: rgba(255,255,255,0.3);
        }
        .crypto-card::before {
            content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px;
            background: linear-gradient(90deg, #fbbf24, #f59e0b); 
            border-radius: 18px 18px 0 0;
        }
        .crypto-header {
            display: flex; align-items: center; gap: 12px; margin-bottom: 15px;
        }
        .crypto-rank {
            background: #fbbf24; color: #1e1b4b; padding: 3px 8px;
            border-radius: 6px; font-size: 0.7rem; font-weight: bold;
            min-width: 25px; text-align: center;
        }
        .crypto-logo {
            width: 32px; height: 32px; border-radius: 50%;
            box-shadow: 0 2px 8px rgba(0,0,0,0.3);
        }
        .crypto-info { flex: 1; }
        .crypto-name { 
            font-size: 1.1rem; font-weight: bold; margin-bottom: 2px;
            color: #ffffff; text-shadow: 0 1px 2px rgba(0,0,0,0.3);
        }
        .crypto-symbol {
            font-size: 0.8rem; color: #94a3b8; font-weight: 500;
        }
        .price-usd { 
            font-size: 1.6rem; font-weight: bold; margin-bottom: 5px; 
            color: #fbbf24; text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }
        .price-krw { 
            font-size: 1rem; color: #e2e8f0; margin-bottom: 10px; 
            font-weight: 500;
        }
        .change { font-size: 0.95rem; font-weight: 600; }
        .positive { color: #4ade80; }
        .negative { color: #ef4444; }
        .neutral { color: #94a3b8; }
        .old-data-notice {
            background: rgba(251,191,36,0.15); border: 1px solid rgba(251,191,36,0.3);
            border-radius: 8px; padding: 8px 12px; margin-bottom: 10px;
            font-size: 0.8rem; color: #fbbf24; text-align: center;
        }
    </style>
</head>
<body>
<div class="container">
<h1>실시간 암호화폐 모니터링</h1>
<div class="update-info">시도 시간: $update_time | Top 12 암호화폐</div>
<div class="status-info $api_status">
EOF
}

get_exchange_rate() {
    local usd_rate=1300
    local exchange_source="기본값"
    
    log "💱 환율 정보 수집 중..." >&2
    
    local exchange_data=$(curl -s "https://api.exchangerate-api.com/v4/latest/USD" --connect-timeout 10 --max-time 15)
    
    if [ $? -eq 0 ] && echo "$exchange_data" | jq -e '.rates.KRW' > /dev/null 2>&1; then
        usd_rate=$(echo "$exchange_data" | jq -r '.rates.KRW')
        exchange_source="ExchangeRate-API"
        log "✅ 환율 API 성공: $usd_rate" >&2
        
        echo "$usd_rate|$exchange_source|$(date)" > "$LAST_EXCHANGE_FILE"
    else
        log "⚠️ 환율 API 실패, 백업 데이터 사용" >&2
        
        if [ -f "$LAST_EXCHANGE_FILE" ]; then
            local backup_data=$(cat "$LAST_EXCHANGE_FILE")
            usd_rate=$(echo "$backup_data" | cut -d'|' -f1)
            local backup_time=$(echo "$backup_data" | cut -d'|' -f3)
            exchange_source="백업 데이터 ($(date -d "$backup_time" '+%m/%d %H:%M' 2>/dev/null || echo "이전"))"
            log "📦 백업 환율 사용: $usd_rate" >&2
        fi
    fi
    
    echo "$usd_rate|$exchange_source"
}

get_crypto_data() {
    log "🪙 암호화폐 데이터 수집 중..." >&2
    
    local crypto_data=$(curl -s "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=15&page=1" \
        --connect-timeout 15 --max-time 30 \
        -H "Accept: application/json" \
        -H "User-Agent: CryptoMonitor/1.0")
    
    echo "$crypto_data" > /tmp/crypto_data.json
    
    if [ $? -eq 0 ] && jq -e 'type == "array" and length > 0' /tmp/crypto_data.json > /dev/null 2>&1; then
        log "✅ 암호화폐 API 성공" >&2
        
        cp /tmp/crypto_data.json "$LAST_SUCCESS_FILE"
        echo "success"
    else
        log "⚠️ 암호화폐 API 실패, 백업 데이터 사용" >&2
        
        if [ -f "$LAST_SUCCESS_FILE" ]; then
            cp "$LAST_SUCCESS_FILE" /tmp/crypto_data.json
            echo "backup"
        else
            echo "error"
        fi
    fi
}

generate_crypto_cards() {
    local usd_rate="$1"
    local data_source="$2"
    
    if [ ! -f /tmp/crypto_data.json ]; then
        echo "<div class='crypto-card error-card'><h2>⚠️ 데이터 없음</h2><p>암호화폐 데이터를 불러올 수 없습니다.</p></div>"
        return
    fi
    
    if [ "$data_source" = "backup" ]; then
        echo "<div class='old-data-notice'>📦 이전 데이터 표시 중</div>"
    fi
    
    local count=$(jq 'length' /tmp/crypto_data.json 2>/dev/null || echo "0")
    
    if [ "$count" -gt 12 ]; then
        count=12
    fi
    
    if [ "$count" -eq 0 ]; then
        echo "<div class='crypto-card error-card'><h2>⚠️ 데이터 오류</h2><p>유효한 암호화폐 데이터가 없습니다.</p></div>"
        return
    fi
    
    for i in $(seq 0 $((count-1))); do
        local name=$(jq -r ".[$i].name" /tmp/crypto_data.json 2>/dev/null || echo "알 수 없음")
        local symbol=$(jq -r ".[$i].symbol" /tmp/crypto_data.json 2>/dev/null | tr '[:lower:]' '[:upper:]')
        local price=$(jq -r ".[$i].current_price" /tmp/crypto_data.json 2>/dev/null || echo "0")
        local change=$(jq -r ".[$i].price_change_percentage_24h" /tmp/crypto_data.json 2>/dev/null || echo "0")
        local rank=$(jq -r ".[$i].market_cap_rank" /tmp/crypto_data.json 2>/dev/null || echo "0")
        local image=$(jq -r ".[$i].image" /tmp/crypto_data.json 2>/dev/null || echo "")
        
        if [ "$name" != "null" ] && [ "$price" != "null" ] && [ "$price" != "0" ]; then
            local price_krw=$(echo "scale=2; $price * $usd_rate" | bc 2>/dev/null || echo "0")
            
            local change_class="neutral"
            local change_symbol=""
            if [ "$change" != "null" ] && [ "$change" != "0" ]; then
                if echo "$change" | grep -q "^-"; then
                    change_class="negative"
                else
                    change_class="positive"
                    change_symbol="+"
                fi
            fi
            
            local formatted_price
            if (( $(echo "$price >= 1" | bc -l 2>/dev/null || echo "0") )); then
                formatted_price=$(printf "%.2f" "$price" 2>/dev/null || echo "$price")
            else
                formatted_price=$(printf "%.6f" "$price" 2>/dev/null || echo "$price")
            fi
            
            local formatted_krw
            if (( $(echo "$price_krw >= 1000" | bc -l 2>/dev/null || echo "0") )); then
                formatted_krw=$(printf "%.0f" "$price_krw" 2>/dev/null | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
            else
                formatted_krw=$(printf "%.2f" "$price_krw" 2>/dev/null || echo "$price_krw")
            fi
            
            echo "<div class='crypto-card'>
    <div class='crypto-header'>
        <div class='crypto-rank'>#${rank}</div>
        <img src='$image' alt='$name' class='crypto-logo' onerror='this.style.display=\"none\"' loading='lazy'>
        <div class='crypto-info'>
            <div class='crypto-name'>$name</div>
            <div class='crypto-symbol'>$symbol</div>
        </div>
    </div>
    <div class='price-usd'>\$$formatted_price</div>
    <div class='price-krw'>₩$formatted_krw</div>
    <div class='change $change_class'>${change_symbol}$(printf "%.2f" "${change:-0}" 2>/dev/null || echo "${change:-0}")% (24h)</div>
</div>"
        fi
    done
}

main() {
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    local exchange_result=$(get_exchange_rate)
    local usd_rate=$(echo "$exchange_result" | cut -d'|' -f1)
    local exchange_source=$(echo "$exchange_result" | cut -d'|' -f2)
    
    local crypto_status=$(get_crypto_data)
    
    local status_class=""
    local status_message=""
    
    case "$crypto_status" in
        "success")
            status_class="status-success"
            status_message="🟢 API 연결 정상 | 실시간 데이터"
            ;;
        "backup")
            status_class="status-warning"
            status_message="🟡 API 연결 실패 | 이전 데이터 표시 중 (30초 후 재시도)"
            ;;
        "error")
            status_class="status-error"
            status_message="🔴 API 연결 실패 | 암호화폐 데이터를 가져올 수 없습니다"
            ;;
    esac
    
    generate_html_header "$current_time" "$status_class" > /shared/index.html
    
    echo "$status_message" >> /shared/index.html
    echo "</div>" >> /shared/index.html
    
    echo "<div class='exchange-rate-info'>🏦 실시간 환율: 1 USD = ₩$(printf "%.2f" "$usd_rate" 2>/dev/null || echo "$usd_rate")</div>" >> /shared/index.html
    
    echo "<div class='crypto-grid'>" >> /shared/index.html
    
    if [ "$crypto_status" != "error" ]; then
        generate_crypto_cards "$usd_rate" "$crypto_status" >> /shared/index.html
    else
        echo "<div class='crypto-card error-card'>
    <h2>⚠️ API 연결 실패</h2>
    <p>암호화폐 데이터를 가져올 수 없습니다.</p>
    <p>$current_time</p>
    <p>30초 후 다시 시도됩니다.</p>
</div>" >> /shared/index.html
    fi
    
    echo "</div>" >> /shared/index.html
    
    echo "<div style='text-align: center; margin-top: 20px; opacity: 0.7; font-size: 0.9rem;'>
    <p>🔄 다음 업데이트: $(date -d '+30 seconds' '+%H:%M:%S' 2>/dev/null || date '+%H:%M:%S')</p>
</div>" >> /shared/index.html
    
    echo "</div></body></html>" >> /shared/index.html
    
    rm -f /tmp/crypto_data.json
    
    log "✅ HTML 페이지 업데이트 완료 (상태: $crypto_status)"
}

main