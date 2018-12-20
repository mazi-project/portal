\
module Sinatra
  module MaziApp
    module Routing
      module MaziRest

        def self.registered(app)
          app.post '/create/measurements/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            body = JSON.parse(request.body.read)
            request.body.rewind
            MaziLogger.debug "Create measurements table in monitoring Database if doesn't exists."
            begin
             con = Mysql.new('localhost',"#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS measurements(id INT PRIMARY KEY AUTO_INCREMENT,sensor_id INT(4) , time DATETIME)")
             
             body["senstypes"].each do |i|
               id = con.query("SELECT 1  FROM INFORMATION_SCHEMA.COLUMNS WHERE  table_name = 'measurements' AND column_name = '#{i}'")
               exists = id.fetch_row
               if exists.nil? 
                 con.query("ALTER TABLE measurements ADD #{i} varchar(4) NOT NULL default '0';")  
               end
             end
 
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/measurements/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Update measurements table"
            begin
             con = Mysql.new('localhost',"#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("INSERT INTO measurements(#{body.keys.join(",")}) VALUES(#{body.values.map { |e| "\"#{e}\"" }.join(',')})")
              return "OK"
            rescue Mysql::Error => e
              MaziLogger.error e.message
              case e.errno
              when 1044, 1045, 1142, 1143,1227            
               return "Database Access Denied"
              when 1037, 1038, 1041, 1135, 1257
               return "Database Out of memory"
              else
               return "MySqlerror #{e.errno}"
              end
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
            id = con.query("SELECT id FROM sensors WHERE sensor_name LIKE '#{body["sensor_name"]}'AND ip='#{body["ip"]}' AND device_id='#{body["device_id"]}'")
            if( id != nil )
               return id.fetch_row
            end
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/create/nextcloud/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            MaziLogger.debug "Create nextcloud table in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS nextcloud(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                         datasize INT(4), downloads INT(4), users INT(4), files INT(4), click_counter INT(4))")
             if con.query("SELECT 1  FROM INFORMATION_SCHEMA.COLUMNS WHERE  table_name = 'nextcloud' AND column_name = 'click_counter'").fetch_row.nil?
                 con.query("ALTER TABLE nextcloud ADD click_counter INT(4) NOT NULL default '0';")
             end
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/nextcloud/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update nextcloud table in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("INSERT INTO nextcloud(device_id, timestamp, datasize, downloads, users, files,click_counter)
                        VALUES('#{body["device_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["datasize"]}', '#{body["downloads"]}', '#{body["users"]}', '#{body["files"]}', '#{body["click_counter"]}')")
             return "OK"
            rescue Mysql::Error => e
              MaziLogger.error e.message
              case e.errno
              when 1044, 1045, 1142, 1143,1227
               return "Database Access Denied"
              when 1037, 1038, 1041, 1135, 1257
               return "Database Out of memory"
              else
               return "MySqlerror #{e.errno}"
              end
            ensure
              con.close if con
            end
          end

          app.post '/flush/nextcloud/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Flush nextcloud table for divice_id #{body["device_id"]} in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("DELETE FROM nextcloud WHERE device_id LIKE '#{body["device_id"]}'")
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
            MaziLogger.debug "Create framadate table in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS framadate(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        polls  INT(4), votes INT(4), comments INT(4), click_counter INT(4))")
             if con.query("SELECT 1  FROM INFORMATION_SCHEMA.COLUMNS WHERE  table_name = 'framadate' AND column_name = 'click_counter'").fetch_row.nil?
                 con.query("ALTER TABLE framadate ADD click_counter INT(4) NOT NULL default '0';")
             end
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
             con.query("INSERT INTO framadate(device_id, timestamp, polls, votes, comments, click_counter)
                        VALUES('#{body["device_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["polls"]}', '#{body["votes"]}', '#{body["comments"]}', '#{body["click_counter"]}')")
             return "OK"
            rescue Mysql::Error => e
              MaziLogger.error e.message
              case e.errno
              when 1044, 1045, 1142, 1143,1227
               return "Database Access Denied"
              when 1037, 1038, 1041, 1135, 1257
               return "Database Out of memory"
              else
               return "MySqlerror #{e.errno}"
              end
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
            MaziLogger.debug "Create guestbook table in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost',"#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS guestbook(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        submissions INT(4),comments INT(4), images INT(4), datasize INT(8) COMMENT 'Bytes', click_counter INT(4))")
             if con.query("SELECT 1  FROM INFORMATION_SCHEMA.COLUMNS WHERE  table_name = 'guestbook' AND column_name = 'click_counter'").fetch_row.nil?
                 con.query("ALTER TABLE guestbook ADD click_counter INT(4) NOT NULL default '0';")
             end
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
             con.query("INSERT INTO guestbook(device_id, timestamp, submissions, comments, images, datasize, click_counter)
                        VALUES('#{body["device_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["submissions"]}', '#{body["comments"]}', '#{body["images"]}', '#{body["datasize"]}', '#{body["click_counter"]}')")
             return "OK"
            rescue Mysql::Error => e
              MaziLogger.error e.message
              case e.errno
              when 1044, 1045, 1142, 1143,1227
               return "Database Access Denied"
              when 1037, 1038, 1041, 1135, 1257
               return "Database Out of memory"
              else
               return "MySqlerror #{e.errno}"
              end
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
            MaziLogger.debug "Create etherpad table in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS etherpad(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        pads INT(4),users INT(4), datasize INT(8) COMMENT 'Bytes', click_counter INT(4))")
             if con.query("SELECT 1  FROM INFORMATION_SCHEMA.COLUMNS WHERE  table_name = 'etherpad' AND column_name = 'click_counter'").fetch_row.nil?
                 con.query("ALTER TABLE etherpad ADD click_counter INT(4) NOT NULL default '0';")
             end
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
             con.query("INSERT INTO etherpad(device_id, timestamp, pads, users, datasize, click_counter)
                        VALUES('#{body["device_id"]}','#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}',
                               '#{body["pads"]}', '#{body["users"]}', '#{body["datasize"]}', '#{body["click_counter"]}')")
             return "OK"
            rescue Mysql::Error => e
              MaziLogger.error e.message
              case e.errno
              when 1044, 1045, 1142, 1143,1227
               return "Database Access Denied"
              when 1037, 1038, 1041, 1135, 1257
               return "Database Out of memory"
              else
               return "MySqlerror #{e.errno}"
              end
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


          app.post '/create/system/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            MaziLogger.debug "Create tables system and users in monitoring Database if doesn't exists"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("CREATE TABLE IF NOT EXISTS users(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME,
                        online_users INT(4))")
             con.query("CREATE TABLE IF NOT EXISTS system(id INT PRIMARY KEY AUTO_INCREMENT, device_id INT(4), timestamp DATETIME, cpu_temperature FLOAT(3,1) COMMENT 'Celsius',
                        cpu_usage FLOAT(3,1) COMMENT 'percentage %',ram_usage FLOAT(3,1) COMMENT 'percentage %',
                        storage FLOAT(3,1) COMMENT 'percentage %', upload FLOAT(3,1), upload_unit VARCHAR(10), 
                        download FLOAT(3,1), download_unit VARCHAR(10) )")
            con.query ("ALTER TABLE system ADD UNIQUE KEY (device_id)")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/update/system/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update system table in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")          
             con.query("INSERT INTO system(device_id, timestamp, cpu_temperature, cpu_usage, ram_usage, storage, upload, upload_unit,download, download_unit) 
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
              case e.errno
              when 1044, 1045, 1142, 1143,1227
               return "Database Access Denied"
              when 1037, 1038, 1041, 1135, 1257
               return "Database Out of memory"
              else
               return "MySqlerror #{e.errno}"
              end
             ensure
              con.close if con
            end
          end

         app.post '/update/users/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')
            MaziLogger.debug "Update users table in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("INSERT INTO users(device_id, timestamp, online_users)
                        VALUES('#{body["device_id"]}', '#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}','#{body["users"]}')" )
             return "OK"
            rescue Mysql::Error => e
              MaziLogger.error e.message
              case e.errno
              when 1044, 1045, 1142, 1143,1227
               return "Database Access Denied"
              when 1037, 1038, 1041, 1135, 1257
               return "Database Out of memory"
              else
               return "MySqlerror #{e.errno}"
              end
            ensure
              con.close if con
            end
         end

         app.post '/flush/system/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Flush system table for divice_id #{body["device_id"]} in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("DELETE FROM system WHERE device_id LIKE '#{body["device_id"]}'")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

         app.post '/flush/users/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Flush users table for divice_id #{body["device_id"]} in monitoring Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "monitoring")
             con.query("DELETE FROM users WHERE device_id LIKE '#{body["device_id"]}'")
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/create/mesh/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            MaziLogger.debug "Create mesh Database, information table and node table"
            begin
             client = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}")
             client.query("CREATE DATABASE IF NOT EXISTS mesh")
             client.close
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "mesh")
            
             con.query("CREATE TABLE IF NOT EXISTS information(id INT PRIMARY KEY AUTO_INCREMENT, deployment VARCHAR(50), ssid VARCHAR(50), 
                        administrator VARCHAR(50), title VARCHAR(50), description VARCHAR(200), location VARCHAR(50) )")
             con.query("CREATE TABLE IF NOT EXISTS node(id INT PRIMARY KEY AUTO_INCREMENT, node_id INT(4), ip VARCHAR(15) )")
             
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end
	  
  	  app.post '/register/node/information' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Register the node of the mesh network"
            begin
            con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "mesh")
           
            id = con.query("SELECT id FROM information WHERE deployment LIKE '#{body["deployment"]}'AND ssid='#{body["ssid"]}' AND
                            title='#{body["title"]}'AND administrator='#{body["admin"]}' AND description='#{body["description"]}' 
                            AND location='#{body["loc"]}'")
            id = id.fetch_row
	    if( id == nil )
	       con.query("INSERT INTO information(deployment, ssid, administrator, title, description, location)
                          VALUES( '#{body["deployment"]}', '#{body["ssid"]}','#{body["admin"]}', '#{body["title"]}', '#{body["description"]}', 
                          '#{body["loc"]}')")
               id = con.query("SELECT max(id) FROM information")
               id = id.fetch_row
            end
             
            return id

            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.post '/register/node' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Registers the IP of the node"
            begin
            con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "mesh")
           
            id = con.query("SELECT id FROM node WHERE node_id LIKE '#{body["node_id"]}'")
            id = id.fetch_row
       
            if ( id != nil )
               con.query("UPDATE node SET ip = '#{body["ip"]} WHERE id = #{id}'")
            else
               con.query("INSERT INTO node(node_id, ip) VALUES( '#{body["node_id"]}', '#{body["ip"]}')") 
            end        

            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
              con.close if con
            end
          end

          app.get '/sshKey/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            MaziLogger.debug "Send the ssh public key"
            begin
               key =  File.read('/root/.ssh/id_rsa.pub')
               return key
            rescue Mysql::Error => e
              MaziLogger.error e.message
            ensure
            end
          end   
      
          app.post '/flush/node/?' do
            file = File.read('/etc/mazi/sql.conf')
            data = JSON.parse(file)
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "Delete node with IP:#{body["ip"]} from the Database"
            begin
             con = Mysql.new('localhost', "#{data["username"]}", "#{data["password"]}", "mesh")
             node_id = con.query("SELECT node_id FROM node WHERE ip LIKE '#{body["ip"]}'")
             node_id = node_id.fetch_row.first
             con.query("DELETE FROM node WHERE node_id='#{node_id}'")
             con.query("DELETE FROM information WHERE id='#{node_id}'")
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

             id = con.query("SELECT id FROM deployments WHERE deployment LIKE '#{body["deployment"]}'")
             deployment_id = id.fetch_row
             
             unless deployment_id.nil?
                deployment_id = deployment_id.first
               
             else
                con.query("INSERT INTO deployments(deployment) VALUES('#{body["deployment"]}')")
                id = con.query("SELECT max(id) FROM deployments")
                deployment_id = id.fetch_row.first
             end
                                   
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
           
            id = con.query("SELECT id FROM deployments WHERE deployment LIKE '#{body["deployment"]}'")
            deployment_id = id.fetch_row
            unless deployment_id.nil?
               deployment_id = deployment_id.first
            end        

            id = con.query("SELECT id FROM devices WHERE title LIKE '#{body["title"]}'AND administrator='#{body["admin"]}'
                            AND description='#{body["description"]}' AND location='#{body["loc"]}' AND deployment_id=#{deployment_id}")

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


