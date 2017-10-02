module Sinatra
  module MaziApp
    module Routing
      module MaziRest

        def self.registered(app)
          app.post '/sensors/register/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Register sensor: #{body["name"]} from ip: #{body["ip"]}"

            begin
            #connect to DATABASE mydb
            con = Mysql.new('localhost', 'mazi_user', '1234', 'sensors')

            con.query("INSERT INTO type(name, ip) VALUES('#{body["name"]}', '#{body["ip"]}')")
            id = con.query("SELECT max(id) FROM type")
            return id.fetch_row

            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.get '/sensors/id/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Search ID for sensor: #{body["name"]} with ip: #{body["ip"]}"
            begin
            #connect to DATABASE mydb
            con = Mysql.new('localhost', 'mazi_user', '1234', 'sensors')
            id = con.query("SELECT id FROM type WHERE name LIKE '#{body["name"]}' AND ip='#{body["ip"]}'")

            if( id != nil )
               return id.fetch_row
            end
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/sensors/store/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "request: post/sensors [#{date.hour}:#{date.minute}:#{date.second}], from sensor_id: #{body["sensor_id"]}"
            begin
            #connect to DATABASE mydb
            con = Mysql.new('localhost', 'mazi_user', '1234', 'sensors')

            #Find the name of the sensor
            name = con.query("SELECT name FROM type WHERE id=#{body["sensor_id"]}").fetch_row.first

            case name
            when "sht11"
               #create TABLE "sensor_SensorId" ==> | ID | TIME | TEMPERATURE | HUMIDITY |
               con.query("CREATE TABLE IF NOT EXISTS sensor_#{body["sensor_id"]}(id INT PRIMARY KEY AUTO_INCREMENT, time DATETIME, temperature VARCHAR(4), humidity VARCHAR(4))")
               con.query("INSERT INTO sensor_#{body["sensor_id"]}(time, temperature, humidity) VALUES('#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}', '#{body["value"]["temp"]}', '#{body["value"]["hum"]}')")
            when "sensehat"
               #create TABLE "sensor_SensorId" ==> | ID | TIME | TEMPERATURE | HUMIDITY |
               con.query("CREATE TABLE IF NOT EXISTS sensor_#{body["sensor_id"]}(id INT PRIMARY KEY AUTO_INCREMENT, time DATETIME, temperature VARCHAR(4), humidity VARCHAR(4))")
               con.query("INSERT INTO sensor_#{body["sensor_id"]}(time, temperature, humidity) VALUES('#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                         '#{body["value"]["temp"]}', '#{body["value"]["hum"]}')")
            end

            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/create/framadate/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Create framadate table in #{body["deployment"]} Database if doesn't exists"
            begin
             con = Mysql.new('localhost', 'root', 'm@z1', "#{body["deployment"]}")
             con.query("CREATE TABLE IF NOT EXISTS framadate(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        polls  INT(4), votes INT(4), comments INT(4), datasize INT(8) COMMENT 'Bytes')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/framadate/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update framadate table in #{body["deployment"]} Database"
            begin
             con = Mysql.new('localhost', 'root', 'm@z1', "#{body["deployment"]}")
             con.query("INSERT INTO framadate(device_id, timestamp, polls, votes, comments, datasize)
                        VALUES('#{body["device_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["polls"]}', '#{body["votes"]}', '#{body["comments"]}', '#{body["datasize"]}')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/create/guestbook/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Create guestbook table in #{body["deployment"]} Database if doesn't exists"
            begin
             con = Mysql.new('localhost', 'root', 'm@z1', "#{body["deployment"]}")
             con.query("CREATE TABLE IF NOT EXISTS guestbook(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        submissions INT(4),comments INT(4), images INT(4), datasize INT(8) COMMENT 'Bytes')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/guestbook/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update guestbook table in #{body["deployment"]} Database"
            begin
             con = Mysql.new('localhost', 'root', 'm@z1', "#{body["deployment"]}")
             con.query("INSERT INTO guestbook(device_id, timestamp, submissions, comments, images, datasize)
                        VALUES('#{body["device_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["submissions"]}', '#{body["comments"]}', '#{body["images"]}', '#{body["datasize"]}')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/create/etherpad/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Create etherpad table in #{body["deployment"]} Database if doesn't exists"
            begin
             con = Mysql.new('localhost', 'root', 'm@z1', "#{body["deployment"]}")
             con.query("CREATE TABLE IF NOT EXISTS etherpad(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        pads INT(4),users INT(4), datasize INT(8) COMMENT 'Bytes')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/etherpad/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update etherpad table in #{body["deployment"]} Database"
            begin
             con = Mysql.new('localhost', 'root', 'm@z1', "#{body["deployment"]}")
             con.query("INSERT INTO etherpad(device_id, timestamp, pads, users, datasize)
                        VALUES('#{body["device_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["pads"]}', '#{body["users"]}', '#{body["datasize"]}')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/create/statistics/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Create table statistics in #{body["deployment"]} Database if doesn't exists"
            begin
             con = Mysql.new('localhost', 'root', 'm@z1', "#{body["deployment"]}")
             con.query("CREATE TABLE IF NOT EXISTS statistics(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        online_users INT(4), cpu_temperature FLOAT(3,1) COMMENT 'Celsius' , cpu_usage FLOAT(3,1) COMMENT 'percentage %',
                        ram_usage FLOAT(3,1) COMMENT 'percentage %', storage FLOAT(3,1) COMMENT 'percentage %', upload FLOAT(3,1),
                        upload_unit VARCHAR(10), download FLOAT(3,1), download_unit VARCHAR(10) )")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/statistics/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update statistics table in #{body["deployment"]} Database"
            begin
             con = Mysql.new('localhost', 'root', 'm@z1', "#{body["deployment"]}")
             con.query("INSERT INTO statistics(device_id, timestamp, online_users, cpu_temperature, cpu_usage, ram_usage, storage, upload, upload_unit,download,
                       download_unit) VALUES('#{body["device_id"]}', '#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                                             '#{body["users"]}', '#{body["temp"]}', '#{body["cpu"]}', '#{body["ram"]}', '#{body["storage"]}',
                                             '#{body["network"]["upload"]}','#{body["network"]["upload_unit"]}','#{body["network"]["download"]}',
                                             '#{body["network"]["download_unit"]}')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/deployment/register/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Create #{body["deployment"]} Database and devices table"
            begin
             client = Mysql.new('localhost', 'root', 'm@z1')
             client.query("CREATE DATABASE IF NOT EXISTS #{body["deployment"]}")
             client.close
             con = Mysql.new('localhost', 'root', 'm@z1', "#{body["deployment"]}")
             con.query("CREATE TABLE IF NOT EXISTS devices(id INT PRIMARY KEY AUTO_INCREMENT, deployment VARCHAR(50), administrator VARCHAR(50),
                        title VARCHAR(50), description VARCHAR(200), location VARCHAR(50) )")
             con.query("INSERT INTO devices(deployment, administrator, title, description, location)
                        VALUES('#{body["deployment"]}', '#{body["admin"]}', '#{body["title"]}', '#{body["description"]}', '#{body["loc"]}')")
             id = con.query("SELECT max(id) FROM devices")
             return id.fetch_row

            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              client.close if client
              con.close if con
            end
          end

          app.get '/device/id/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Search for device ID in #{body["deployment"]} database"
            begin
            con = Mysql.new('localhost', 'root', 'm@z1', "#{body["deployment"]}")
            id = con.query("SELECT id FROM devices WHERE title LIKE '#{body["title"]}'AND administrator='#{body["admin"]}'
                            AND description='#{body["description"]}' AND location='#{body["loc"]}' ")
            if( id != nil )
               return id.fetch_row
            end
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end
        end

      end
    end
  end
end