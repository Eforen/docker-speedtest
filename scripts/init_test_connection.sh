#!/bin/sh
FILE="/opt/speedtest/test_connection.log"
INTERVAL=${TEST_INTERVAL:-900}
DATABASE="${INFLUXDB_DB:-speedtest}"
SERVER_HOST="${INFLUXDB_HOST:-influxdb}"
SERVER_PORT="${INFLUXDB_PORT:-8086}"

while true
do
	TIMESTAMP=$(date "+%s")

	echo "Run speedtest ..."
	# timeout and exit with 143 if speed test is not done within 300 seconds (5 minutes)
	timeout 300 speedtest --accept-license --accept-gdpr --format=json > $FILE

	EXIT_CODE=$?
	echo "Speedtest exited with $EXIT_CODE"
	# Set defaults
	PACKET_LOSS="0"
	IDLE_LATENCY="0"
	IDLE_LATENCY_LOW="0"
	IDLE_LATENCY_HIGH="0"
	IDLE_LATENCY_JITTER="0"
	
	DOWNLOAD="0"
	DOWNLOAD_LATENCY="0"
	DOWNLOAD_LATENCY_LOW="0"
	DOWNLOAD_LATENCY_HIGH="0"
	DOWNLOAD_LATENCY_JITTER="0"
	
	UPLOAD="0"
	UPLOAD_LATENCY="0"
	UPLOAD_LATENCY_LOW="0"
	UPLOAD_LATENCY_HIGH="0"
	UPLOAD_LATENCY_JITTER="0"

	# ISP=""
	# SERVER_NAME=""
	SERVER_ID="0"
	# SERVER_HOST=""
	# SERVER_PORT=""
	# SERVER_LOCATION=""
	# SERVER_IP=""
	RESULT_ID="none"
	# RESULT_URL=""
	# RESULT_PERSISTED=""
	IP_EXTERNAL="0.0.0.0"
	
	# if exit code of speed test command is not 0 the speed test failed and it's save to assume that no internet connection exits
	if [ $EXIT_CODE -ne 0 ]
	then
		if [ $EXIT_CODE -eq 143 ]; then
			echo "Speedtest timed out."
		fi
		echo "Speedtest failed. No internet connection!"
	else

		# {
		#     "type": "result",
		#     "timestamp": "2023-06-17T00:36:22Z",
		#     "ping": {
		#         "jitter": 2.459,
		#         "latency": 12.150,
		#         "low": 8.649,
		#         "high": 17.909
		#     },
		#     "download": {
		#         "bandwidth": 99931249,
		#         "bytes": 1028301150,
		#         "elapsed": 10603,
		#         "latency": {
		#             "iqm": 35.603,
		#             "low": 11.987,
		#             "high": 126.449,
		#             "jitter": 5.909
		#         }
		#     },
		#     "upload": {
		#         "bandwidth": 5182352,
		#         "bytes": 20243040,
		#         "elapsed": 3906,
		#         "latency": {
		#             "iqm": 8.456,
		#             "low": 4.701,
		#             "high": 16.136,
		#             "jitter": 2.371
		#         }
		#     },
		#     "packetLoss": 0,
		#     "isp": "Comcast Cable",
		#     "interface": {
		#         "internalIp": "10.42.6.2",
		#         "name": "eth0",
		#         "macAddr": "46:4B:07:FF:B6:E8",
		#         "isVpn": false,
		#         "externalIp": "24.14.95.136"
		#     },
		#     "server": {
		#         "id": 12187,
		#         "host": "speedtest.chi1.nitelusa.net",
		#         "port": 8080,
		#         "name": "Nitel",
		#         "location": "Chicago, IL",
		#         "country": "United States",
		#         "ip": "45.61.24.34"
		#     },
		#     "result": {
		#         "id": "195943eb-b0e2-4c07-8998-0ba9c062291e",
		#         "url": "https://www.speedtest.net/result/c/195943eb-b0e2-4c07-8998-0ba9c062291e",
		#         "persisted": true
		#     }
		# }
		PACKET_LOSS=$(cat $FILE | jq -r '.packetLoss')
		IDLE_LATENCY=$(cat $FILE | jq -r '.ping.latency')
		IDLE_LATENCY_LOW=$(cat $FILE | jq -r '.ping.low')
		IDLE_LATENCY_HIGH=$(cat $FILE | jq -r '.ping.high')
		IDLE_LATENCY_JITTER=$(cat $FILE | jq -r '.ping.jitter')
		
		DOWNLOAD=$(cat $FILE | jq -r '.download.bandwidth')
		DOWNLOAD_LATENCY=$(cat $FILE | jq -r '.download.latency.iqm') 
		DOWNLOAD_LATENCY_LOW=$(cat $FILE | jq -r '.download.latency.low')
		DOWNLOAD_LATENCY_HIGH=$(cat $FILE | jq -r '.download.latency.high')
		DOWNLOAD_LATENCY_JITTER=$(cat $FILE | jq -r '.download.latency.jitter')
		
		UPLOAD=$(cat $FILE | jq -r '.upload.bandwidth')
		UPLOAD_LATENCY=$(cat $FILE | jq -r '.upload.latency.iqm')
		UPLOAD_LATENCY_LOW=$(cat $FILE | jq -r '.upload.latency.low')
		UPLOAD_LATENCY_HIGH=$(cat $FILE | jq -r '.upload.latency.high')
		UPLOAD_LATENCY_JITTER=$(cat $FILE | jq -r '.upload.latency.jitter')
		
		# ISP=$(cat $FILE | jq -r '.isp')
		# SERVER_NAME=$(cat $FILE | jq -r '.server.name')
		SERVER_ID=$(cat $FILE | jq -r '.server.id')
		# SERVER_HOST=$(cat $FILE | jq -r '.server.host')
		# SERVER_PORT=$(cat $FILE | jq -r '.server.port')
		# SERVER_LOCATION=$(cat $FILE | jq -r '.server.location + ", " + .server.country')
		# SERVER_IP=$(cat $FILE | jq -r '.server.ip')
		# RAW_TIMESTAMP=$(cat $FILE | jq -r '.timestamp')
		RESULT_ID=$(cat $FILE | jq -r '.result.id')
		# RESULT_URL=$(cat $FILE | jq -r '.result.url')
		# RESULT_PERSISTED=$(cat $FILE | jq -r '.result.persisted')
		IP_EXTERNAL=$(cat $FILE | jq -r '.interface.externalIp')
		
		echo "Packet Loss: $PACKET_LOSS"
		echo "Download: $DOWNLOAD"
		echo "Upload: $UPLOAD"
		echo "LATENCY: $IDLE_LATENCY"
		echo "Timestamp: $TIMESTAMP"

	fi
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" result_id=\"$RESULT_ID\" ${TIMESTAMP}")
	echo "result_id send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" server_id=\"$SERVER_ID\" ${TIMESTAMP}")
	echo "server_id send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" external_ip=\"$IP_EXTERNAL\" ${TIMESTAMP}")
	echo "external_ip send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" packet_loss=\"$PACKET_LOSS\" ${TIMESTAMP}")
	echo "packet_loss send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" idle_latency_low=\"$IDLE_LATENCY_LOW\" ${TIMESTAMP}")
	echo "idle_latency_low send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" idle_latency_high=\"$IDLE_LATENCY_HIGH\" ${TIMESTAMP}")
	echo "idle_latency_high send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" idle_latency_jitter=\"$IDLE_LATENCY_JITTER\" ${TIMESTAMP}")
	echo "idle_latency_jitter send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" download=\"$DOWNLOAD\" ${TIMESTAMP}")
	echo "download send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" download_latency=\"$DOWNLOAD_LATENCY\" ${TIMESTAMP}")
	echo "download_latency send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" download_latency_low=\"$DOWNLOAD_LATENCY_LOW\" ${TIMESTAMP}")
	echo "download_latency_low send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" download_latency_high=\"$DOWNLOAD_LATENCY_HIGH\" ${TIMESTAMP}")
	echo "download_latency_high send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" download_latency_jitter=\"$DOWNLOAD_LATENCY_JITTER\" ${TIMESTAMP}")
	echo "download_latency_jitter send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" upload=\"$UPLOAD\" ${TIMESTAMP}")
	echo "upload send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" upload_latency=\"$UPLOAD_LATENCY\" ${TIMESTAMP}")
	echo "upload_latency send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" upload_latency_low=\"$UPLOAD_LATENCY_LOW\" ${TIMESTAMP}")
	echo "upload_latency_low send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" upload_latency_high=\"$UPLOAD_LATENCY_HIGH\" ${TIMESTAMP}")
	echo "upload_latency_high send returned with $RESP_CODE"
	RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest,tracker=\"main\" upload_latency_jitter=\"$UPLOAD_LATENCY_JITTER\" ${TIMESTAMP}")
	echo "upload_latency_jitter send returned with $RESP_CODE"

	# RESP_CODE=$(curl -XPOST "http://$SERVER_HOST:$SERVER_PORT/write?db=$DATABASE&precision=s" --data-binary "speedtest server_id=$SERVER_ID external_ip=$IP_EXTERNAL packet_loss=$PACKET_LOSS idle_latency_low=$IDLE_LATENCY_LOW idle_latency_high=$IDLE_LATENCY_HIGH idle_latency_jitter=$IDLE_LATENCY_JITTER download=$DOWNLOAD download_latency=$DOWNLOAD_LATENCY download_latency_low=$DOWNLOAD_LATENCY_LOW download_latency_high=$DOWNLOAD_LATENCY_HIGH download_latency_jitter=$DOWNLOAD_LATENCY_JITTER upload=$UPLOAD upload_latency=$UPLOAD_LATENCY upload_latency_low=$UPLOAD_LATENCY_LOW upload_latency_high=$UPLOAD_LATENCY_HIGH upload_latency_jitter=$UPLOAD_LATENCY_JITTER result_id=$RESULT_ID $TIMESTAMP")
	# echo "Results send returned with $RESP_CODE"

	END_TIMESTAMP=$(date "+%s")
	DELTA=$(( INTERVAL - (END_TIMESTAMP - TIMESTAMP) ))
	echo "Sleep $INTERVAL before next run. $DELTA s remaining"
	sleep $DELTA

done
