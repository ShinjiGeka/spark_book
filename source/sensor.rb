#
# サンプルデータ作成用プログラム
# 気象庁、過去の気象データダウンロードページよりダウンロードした
# 気温、湿度データよりセンサーデータサンプルを作成する。
# http://www.data.jma.go.jp/gmd/risk/obsdl/index.php
#
# 入力データのイメージは以下の通り、
# 2016/6/1 1:00:00,98,8,1,10.8,8,1
# 2016/6/1 2:00:00,99,8,1,9.9,8,1
# 2016/6/1 3:00:00,98,8,1,10.3,8,1
# 2016/6/1 4:00:00,99,8,1,9.4,8,1
#
# ただし、先頭６行は項目名など余分なデータが含まれている。
#
# Rubyバージョンは 2.4.2p198
#
require "time"

# 引数のチェック。 
if ARGV.size != 3
	then
		print("usage : command filename id type(csv or json)\n")
		exit(1)
end

filename = ARGV[0]
id       = ARGV[1]
type     = ARGV[2]

file = File.open(filename)

lon = 143.19
lat = 42.92

random = Random.new
pH = random.rand(5.0..8.0)

# 先頭６行を読み飛ばし。
i = 0
file.each_line do 
	i += 1
	if i > 5 then
		break
	end
end

# １行先読み。
line = file.readline
currentLine = line.split(",")
current_date_time   = Time.parse(currentLine[0])
current_humidity    = currentLine[1].to_i
current_temperature = currentLine[4].to_f

file.each_line do |next_line|

	# １時間後の湿度、気温を知りたいので次の行を処理する。
	nextLine         = next_line.split(",")
	next_date_time   = Time.parse(nextLine[0])
	next_humidity    = nextLine[1].to_i
	next_temperature = nextLine[4].to_f

	# 現在行を、５分刻みに増幅。
	12.times do |i|
		# 現在～１時間後の湿度の間でランダムな値を生成する。
		if (current_humidity - next_humidity) <= 0 then 
			range = Range.new(current_humidity, next_humidity )
		else
			range = Range.new(next_humidity, current_humidity )
		end
		humidity = random.rand(range)
		# 現在～１時間後の温度の間でランダムな値を生成する。
		if (current_temperature - next_temperature) <= 0 then 
			range = Range.new(current_temperature, next_temperature )
		else
			range = Range.new(next_temperature, current_temperature )
		end
		temperature = random.rand(range).round(1)
		# pHは先頭でセットした値の前後0.3程度で変動させる。
		pH = (pH + random.rand(-0.3..0.3)).round(1)
		# Water Holding Capacity は湿度から適当に計算。
		whc = humidity - 30 - random.rand(1..10) + random.rand(0.1..0.9).round(1)
		if whc < 0 then
			whc = 0 
		end
		# 適度にエラーデータを入れるブロック。
		random_number = random.rand(1..20000)
		if random_number == 20000 then
		 	temperature = nil # 気温がNULL
		end
		if random_number == 19999 then
			humidity += 100 # 湿度が100%を超える。
		end
		# 時間を５分進める。(iはゼロから始まる。) 
		date_time = current_date_time + (i * 60 * 5)
		case type
			when "csv" then
				print date_time.strftime("%F %H:%M"), ",", id, ",", lon, ",", lat, ",", temperature, ",", humidity, ",", pH, ",", whc,"\n"
			when "json" then
				print "{\"id\":", id, ",", "\n"
				print "\"date\":", date_time.strftime("%F %H:%M"), ",", "\n"
				print "\"coord\":{\"lon\":",lon, ", ", "\"lat\":", lat, "},", "\n"
				print "\"main\":{\"temperature\":", temperature, ", ", "\"humidity\":", humidity, ", ", "\"ph\":", pH, ", ", "\"whc\":", whc, "}}", "\n"
			else
		end

	end

	# 現在行を進める。
	current_date_time      = next_date_time 
	current_humidity       = next_humidity 
	current_temperature    = next_temperature 

end
file.close
