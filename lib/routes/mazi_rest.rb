
module Sinatra
  module MaziApp
    module Routing
      module MaziRest

        def self.registered(app)
          app.post '/create/sensehat/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
#            body = JSON.parse(request.body.read)
            MaziLogger.debug "Create sensehat table in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost',"#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS sensehat(id INT PRIMARY KEY AUTO_INCREMENT,sensor_id INT(4) , time DATETIME, temperature VARCHAR(4), humidity VARCHAR(4))")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/sensehat/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update sensehat table "
            begin
             con = Mysql.new('localhost',"#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("INSERT INTO sensehat(sensor_id, time, temperature, humidity)
                        VALUES('#{body["sensor_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                              '#{body["value"]["temp"]}','#{body["value"]["hum"]}')")
              return "OK"
            rescue Mysql::Error => e
              MaziLogger.error e.message
              return e.message 
            ensure
              con.close if con
            end
          end
 


          app.post '/create/sht11/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
#            body = JSON.parse(request.body.read)
            MaziLogger.debug "Create sht11 table in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost',"#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS sht11(id INT PRIMARY KEY AUTO_INCREMENT,sensor_id INT(4) , time DATETIME, temperature VARCHAR(4), humidity VARCHAR(4))")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end


          app.post '/update/sht11/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update sht11 table "
            begin
             con = Mysql.new('localhost',"#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("INSERT INTO sht11(sensor_id, time, temperature, humidity)
                        VALUES('#{body["sensor_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["value"]["temp"]}','#{body["value"]["hum"]}')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/sensor/register/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)            
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Register sensor: #{body["sensor_name"]} from ip: #{body["ip"]}"
            begin
              con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
              con.query("CREATE TABLE IF NOT EXISTS sensors(id INT PRIMARY KEY AUTO_INCREMENT, sensor_name VARCHAR(50), ip VARCHAR(15), device_id INT(4))")
 
              con.query("INSERT INTO sensors(sensor_name, ip, device_id)
                        VALUES('#{body["sensor_name"]}', '#{body["ip"]}', '#{body["device_id"]}')")
              id = con.query("SELECT max(id) FROM sensors")
              return id.fetch_row
            
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end

          end

          app.get '/sensors/id/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Search ID for sensor: #{body["name"]} with ip: #{body["ip"]}"
            begin
            con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
            id = con.query("SELECT id FROM sensors WHERE sensor_name LIKE '#{body["sensor_name"]}'AND ip='#{body["ip"]}'")
            if( id != nil )
               return id.fetch_row
            end
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/create/framadate/?' do
 	    file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
     #       body = JSON.parse(request.body.read)
            MaziLogger.debug "Create framadate table in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS framadate(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        polls  INT(4), votes INT(4), comments INT(4))")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/framadate/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update framadate table in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("INSERT INTO framadate(device_id, timestamp, polls, votes, comments)
                        VALUES('#{body["device_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["polls"]}', '#{body["votes"]}', '#{body["comments"]}')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/flush/framadate/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Flush framadate table for divice_id #{body["device_id"]} in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("DELETE FROM framadate WHERE device_id LIKE '#{body["device_id"]}'")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/create/guestbook/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
          #  body = JSON.parse(request.body.read)
            MaziLogger.debug "Create guestbook table in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost',"#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS guestbook(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        submissions INT(4),comments INT(4), images INT(4), datasize INT(8) COMMENT 'Bytes')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/guestbook/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)    
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update guestbook table in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("INSERT INTO guestbook(device_id, timestamp, submissions, comments, images, datasize)
                        VALUES('#{body["device_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["submissions"]}', '#{body["comments"]}', '#{body["images"]}', '#{body["datasize"]}')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/flush/guestbook/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Flush guestbook table for divice_id #{body["device_id"]} in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("DELETE FROM guestbook WHERE device_id LIKE '#{body["device_id"]}'")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end


          app.post '/create/etherpad/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
          #  body = JSON.parse(request.body.read)
            MaziLogger.debug "Create etherpad table in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS etherpad(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        pads INT(4),users INT(4), datasize INT(8) COMMENT 'Bytes')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/etherpad/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update etherpad table in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("INSERT INTO etherpad(device_id, timestamp, pads, users, datasize)
                        VALUES('#{body["device_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["pads"]}', '#{body["users"]}', '#{body["datasize"]}')")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/flush/etherpad/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Flush etherpad table for divice_id #{body["device_id"]} in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("DELETE FROM etherpad WHERE device_id LIKE '#{body["device_id"]}'")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end


          app.post '/create/statistics/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
#            body = JSON.parse(request.body.read)
            MaziLogger.debug "Create tables statistics and users in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS users(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        online_users INT(4))")
             con.query("CREATE TABLE IF NOT EXISTS statistics(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME, cpu_temperature FLOAT(3,1) COMMENT 'Celsius',
                        cpu_usage FLOAT(3,1) COMMENT 'percentage %',ram_usage FLOAT(3,1) COMMENT 'percentage %',
                        storage FLOAT(3,1) COMMENT 'percentage %', upload FLOAT(3,1), upload_unit VARCHAR(10), 
                        download FLOAT(3,1), download_unit VARCHAR(10) )")
            con.query ("ALTER TABLE statistics ADD UNIQUE KEY (device_id)")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/statistics/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update statistics and users tables in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("INSERT INTO users(device_id, timestamp, online_users) 
                        VALUES('#{body["device_id"]}', '#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}','#{body["users"]}')")
          
             con.query("INSERT INTO statistics(device_id, timestamp, cpu_temperature, cpu_usage, ram_usage, storage, upload, upload_unit,download, download_unit) 
                        VALUES('#{body["device_id"]}', '#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                                             '#{body["temp"]}', '#{body["cpu"]}', '#{body["ram"]}', '#{body["storage"]}','#{body["network"]["upload"]}',
                                             '#{body["network"]["upload_unit"]}','#{body["network"]["download"]}',
                                             '#{body["network"]["download_unit"]}') 
                        ON DUPLICATE KEY UPDATE timestamp = '#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}', cpu_temperature = '#{body["temp"]}',
                                                cpu_usage = '#{body["cpu"]}', ram_usage = '#{body["ram"]}', storage = '#{body["storage"]}', upload = '#{body["network"]["upload"]}',
                                                upload_unit = '#{body["network"]["upload_unit"]}', download = '#{body["network"]["download"]}', download_unit = '#{body["network"]["download_unit"]}' ; ")
              return "OK"
            rescue Mysql::Error => e
              MaziLogger.error e.message
              return e.message
             ensure
              con.close if con
            end
          end

         app.post '/flush/statistics/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Flush statistics and users table for divice_id #{body["device_id"]} in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("DELETE FROM statistics WHERE device_id LIKE '#{body["device_id"]}'")
             con.query("DELETE FROM users WHERE device_id LIKE '#{body["device_id"]}'")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end



          app.post '/monitoring/register/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Create monitoring Database, devices table and deployment table"
            begin
             client = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}")
             client.query("CREATE DATABASE IF NOT EXISTS monitoring")
             client.close
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
            
             con.query("CREATE TABLE IF NOT EXISTS deployments(id INT PRIMARY KEY AUTO_INCREMENT, deployment VARCHAR(50))")
             con.query("INSERT INTO deployments(deployment) VALUES('#{body["deployment"]}')")
             id = con.query("SELECT max(id) FROM deployments")
             deployment_id = id.fetch_row.join.to_i  
             

             con.query("CREATE TABLE IF NOT EXISTS devices(id INT PRIMARY KEY AUTO_INCREMENT, deployment_id INT(4), administrator VARCHAR(50),
                        title VARCHAR(50), description VARCHAR(200), location VARCHAR(50) )")
             con.query("INSERT INTO devices(deployment_id, administrator, title, description, location)
                        VALUES( #{deployment_id}, '#{body["admin"]}', '#{body["title"]}', '#{body["description"]}', '#{body["loc"]}')")
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
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Search for device ID in monitoring database"
            begin
            con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
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

