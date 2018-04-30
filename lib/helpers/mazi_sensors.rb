SENSORS_DB_IP      = 'localhost'                 # this should be localhost
SELECT_QUERY_LIMIT = 'GROUP BY id DESC LIMIT 50' # default query for the select on the sensors db
SENSORS_ENABLED    = true                        # a quick way to disable the sensors module
MONITORING_DB      = 'monitoring'                # the database name on localhost
MYSQL_PASS_FILE    = '/etc/mazi/sql.conf'        # the mysql creds file

module MaziSensors
  def init_sensors
    @sensehat_metrics = {}
    @sensehat_metrics[:comp] = 0
    @sensehat_metrics[:acc]  = [0, 0, 0]
    @sensehat_metrics[:gyro] = [0, 0, 0]
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
  ensure
    con.close if con
  end

  def initialize_sensors_module(password)
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL."
  ensure
    con.close if con
  end

  def sensors_enabled?
    SENSORS_ENABLED && @config[:sensors] && @config[:sensors][:enable]
  end

  def sensors_db_exist?
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    true
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    false
  ensure
    con.close if con
  end

  def toggle_sensors_enabled
    current_value = @config[:sensors][:enable]
    changeConfigFile("sensors->enable", !current_value)
    writeConfigFile
  end

  def getAllDevices
    if @config[:general][:mode] == 'demo'
      return [{latLng: [39.366071, 22.923611], name: 'Volos', status: "OK"}, {latLng: [34.366071, 19.923611], name: 'EU', status: "ERROR"}]
    end
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    q = "SELECT * FROM deployments INNER JOIN devices ON devices.deployment_id = deployments.id"
    a = con.query(q)
    out = []
    a.each_hash do |row|
      tmp               = {}
      tmp[:id]          = row['id']
      tmp[:name]        = row['title']
      tmp[:latLng]      = row['location'].split(',')
      tmp[:admin]       = row['administrator']
      tmp[:description] = row['description']
      tmp[:deployment]  = row['deployment']
      out << tmp
    end
    out
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL"
    []
  ensure
    con.close if con
  end

  def getAllDeploymentsWithData
    # if @config[:general][:mode] == 'demo'
    #   return [{latLng: [39.366071, 22.923611], name: 'Volos', status: "OK"}, {latLng: [34.366071, 19.923611], name: 'EU', status: "ERROR"}]
    # end
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    q = "SELECT * FROM deployments INNER JOIN devices ON devices.deployment_id = deployments.id"
    a = con.query(q)
    out = {}
    a.each_hash do |row|
      if out[row['deployment_id']].nil?
        out[row['deployment_id']]              = {}
        out[row['deployment_id']][:id]         = row['deployment_id']
        out[row['deployment_id']][:deployment] = row['deployment']
        out[row['deployment_id']][:devices]    = {}
      end
      if out[row['deployment_id']][:devices][row['id']].nil?
        out[row['deployment_id']][:devices][row['id']]                 = {}
        out[row['deployment_id']][:devices][row['id']][:id]            = row['id']
        out[row['deployment_id']][:devices][row['id']][:administrator] = row['administrator']
        out[row['deployment_id']][:devices][row['id']][:title]         = row['title']
        out[row['deployment_id']][:devices][row['id']][:description]   = row['description']
        out[row['deployment_id']][:devices][row['id']][:latLng]        = row['location'].split(',')
        out[row['deployment_id']][:devices][row['id']][:sensors]       = {}
        out[row['deployment_id']][:devices][row['id']][:applications]  = {}
        out[row['deployment_id']][:devices][row['id']][:system]        = {}
        out[row['deployment_id']][:devices][row['id']][:users]         = {}
      end
      out[row['deployment_id']][:devices][row['id']][:sensors]      = getSensorDataForDevice(row['id'])
      out[row['deployment_id']][:devices][row['id']][:applications] = getApplicationDataForDevice(row['id'])
      out[row['deployment_id']][:devices][row['id']][:system]       = getSystemDataForDevice(row['id'])
      out[row['deployment_id']][:devices][row['id']][:users]        = getUserDataForDevice(row['id'])
    end
    out
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL"
    {}
  ensure
    con.close if con
  end

  def enrichDeployments(deployments)
    deployments.each do |id, deployment|
      if deployment[:devices].nil? || deployment[:devices].empty?
        deployment[:latLng] = nil
      else
        deployment[:latLng] = deployment[:devices].values.first[:latLng]
      end
    end
    deployments
  end

  def getSensorDataForDevice(device_id, start_time=nil, end_time=nil)
    output = {}
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)

    q = "SELECT * FROM devices d INNER JOIN sensors s ON s.device_id = d.id INNER JOIN measurements m ON m.sensor_id = s.id WHERE d.id = #{device_id}"
    a = con.query(q)
    a.each_hash do |row|
      if output[row['sensor_id']].nil?
        output[row['sensor_id']]                       = {}
        output[row['sensor_id']][:id]                  = row['sensor_id']
        output[row['sensor_id']][:sensor_name]         = row['sensor_name']
        output[row['sensor_id']][:data]                = {}
        output[row['sensor_id']][:data][:temperatures] = []
        output[row['sensor_id']][:data][:humidities]   = []
        output[row['sensor_id']][:data][:pressures]    = []
      end
      output[row['sensor_id']][:data][:temperatures] << {date: row['time'], temp: row['temperature']} if row['temperature']
      output[row['sensor_id']][:data][:humidities]   << {date: row['time'], hum: row['humidity']} if row['humidity']
      output[row['sensor_id']][:data][:pressures]    << {date: row['time'], pres: row['pressure']} if row['pressure']
    end
    output
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    return output
  ensure
    con.close if con
  end

  def getApplicationDataForDevice(device_id, start_time=nil, end_time=nil)
    output = {}
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)

    q = "SELECT * FROM devices d INNER JOIN etherpad e ON e.device_id = d.id WHERE d.id = #{device_id}"
    a = con.query(q)
    a.each_hash do |row|
      if output['etherpad'].nil?
        output['etherpad']                   = {}
        output['etherpad'][:data]            = {}
        output['etherpad'][:data][:pads]     = []
        output['etherpad'][:data][:users]    = []
        output['etherpad'][:data][:datasize] = []
        output['etherpad'][:data][:clicks]   = []
      end
      output['etherpad'][:data][:pads]     << {date: row['timestamp'], pads: row['pads']} if row['pads']
      output['etherpad'][:data][:users]    << {date: row['timestamp'], users: row['users']} if row['users']
      output['etherpad'][:data][:datasize] << {date: row['timestamp'], datasize: row['datasize']} if row['datasize']
      output['etherpad'][:data][:clicks]   << {date: row['timestamp'], datasize: row['click_counter']} if row['click_counter']
    end
    q = "SELECT * FROM devices d INNER JOIN guestbook e ON e.device_id = d.id WHERE d.id = #{device_id}"
    a = con.query(q)
    a.each_hash do |row|
      if output['guestbook'].nil?
        output['guestbook']                      = {}
        output['guestbook'][:data]               = {}
        output['guestbook'][:data][:submissions] = []
        output['guestbook'][:data][:comments]    = []
        output['guestbook'][:data][:images]      = []
        output['guestbook'][:data][:datasize]    = []
        output['guestbook'][:data][:clicks]      = []
      end
      output['guestbook'][:data][:submissions] << {date: row['timestamp'], submissions: row['submissions']} if row['submissions']
      output['guestbook'][:data][:comments]    << {date: row['timestamp'], comments: row['comments']} if row['comments']
      output['guestbook'][:data][:images]      << {date: row['timestamp'], images: row['images']} if row['images']
      output['guestbook'][:data][:datasize]    << {date: row['timestamp'], datasize: row['datasize']} if row['datasize']
      output['guestbook'][:data][:clicks]      << {date: row['timestamp'], datasize: row['click_counter']} if row['click_counter']
    end
    q = "SELECT * FROM devices d INNER JOIN framadate e ON e.device_id = d.id WHERE d.id = #{device_id}"
    a = con.query(q)
    a.each_hash do |row|
      if output['framadate'].nil?
        output['framadate']                   = {}
        output['framadate'][:data]            = {}
        output['framadate'][:data][:polls]    = []
        output['framadate'][:data][:votes]    = []
        output['framadate'][:data][:comments] = []
        output['framadate'][:data][:clicks]   = []
      end
      output['framadate'][:data][:polls]    << {date: row['timestamp'], polls: row['polls']} if row['polls']
      output['framadate'][:data][:votes]    << {date: row['timestamp'], votes: row['votes']} if row['votes']
      output['framadate'][:data][:comments] << {date: row['timestamp'], comments: row['comments']} if row['comments']
      output['framadate'][:data][:clicks]   << {date: row['timestamp'], comments: row['click_counter']} if row['click_counter']
    end
    q = "SELECT * FROM devices d INNER JOIN nextcloud e ON e.device_id = d.id WHERE d.id = #{device_id}"
    a = con.query(q)
    a.each_hash do |row|
      if output['nextcloud'].nil?
        output['nextcloud']                    = {}
        output['nextcloud'][:data]             = {}
        output['nextcloud'][:data][:users]     = []
        output['nextcloud'][:data][:files]     = []
        output['nextcloud'][:data][:downloads] = []
        output['nextcloud'][:data][:datasize]  = []
        output['nextcloud'][:data][:clicks]    = []
      end
      output['nextcloud'][:data][:users]     << {date: row['timestamp'], polls: row['users']} if row['users']
      output['nextcloud'][:data][:files]     << {date: row['timestamp'], votes: row['files']} if row['files']
      output['nextcloud'][:data][:downloads] << {date: row['timestamp'], comments: row['downloads']} if row['downloads']
      output['nextcloud'][:data][:datasize]  << {date: row['timestamp'], comments: row['datasize']} if row['datasize']
      output['nextcloud'][:data][:clicks]    << {date: row['timestamp'], comments: row['click_counter']} if row['click_counter']
    end
    output
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    return output
  ensure
    con.close if con
  end

  def getSystemDataForDevice(device_id, start_time=nil, end_time=nil)
    output = {}
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)

    q = "SELECT * FROM devices d INNER JOIN system s ON s.device_id = d.id WHERE d.id = #{device_id}"
    a = con.query(q)
    a.each_hash do |row|
      output[:timestamp] = row['timestamp']
      output[:cpu_temp]  = row['cpu_temperature']
      output[:cpu_usage] = row['cpu_usage']
      output[:ram_usage] = row['ram_usage']
      output[:storage]   = row['storage']
    end
    output
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    return output
  ensure
    con.close if con
  end

  def getUserDataForDevice(device_id, start_time=nil, end_time=nil)
    output = []
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)

    q = "SELECT * FROM devices d INNER JOIN users u ON u.device_id = d.id WHERE d.id = #{device_id}"
    a = con.query(q)
    a.each_hash do |row|
      tmp                = {}
      tmp[:date]         = row['timestamp']
      tmp[:online_users] = row['online_users']
      output << tmp 
    end
    output
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    return output
  ensure
    con.close if con
  end

  def get_data_for_device(device, start_time=nil, end_time=nil)
    output = {}
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)

    q = "SELECT * FROM measurements m INNER JOIN sensors s ON m.sensor_id = s.id INNER JOIN devices d ON s.device_id = d.id"
    a = con.query(q)
    a.each_hash do |row|
      # {"id"=>"1", "sensor_id"=>"1", "device_id"=>"1", "deployment_id"=>"1",
      # "time"=>"2018-02-08 00:06:01", "pressure"=>"1012", "humidity"=>"50.1", "temperature"=>"20.4",
      #  "sensor_name"=>"sensehat", "ip"=>"10.0.0.1", "administrator"=>"Aris Dadoukis", "title"=>"GreatMazi",
      # "description"=>"The great big Mazizone deployment", "location"=>"39.366071, 22.923611"}
      output[row['device_id']] = {} unless output[row['device_id']]
      unless output[row['device_id']][row['sensor_name']]
        output[row['device_id']][row['sensor_name']] = {}
        output[row['device_id']][row['sensor_name']][:temperatures] = []
        output[row['device_id']][row['sensor_name']][:humidities]   = []
        output[row['device_id']][row['sensor_name']][:pressures]    = []
      end
      output[row['device_id']][row['sensor_name']][:temperatures] << {date: row['time'], temp: row['temperature']} if row['temperature']
      output[row['device_id']][row['sensor_name']][:humidities]   << {date: row['time'], hum: row['humidity']} if row['humidity']
      output[row['device_id']][row['sensor_name']][:pressures]    << {date: row['time'], pres: row['pressure']} if row['pressure']
    end
    q = "SELECT * FROM etherpad e INNER JOIN devices d ON e.device_id = d.id"
    a = con.query(q)
    a.each_hash do |row|
      output[row['device_id']] = {} unless output[row['device_id']]
      unless output[row['device_id']]['etherpad']
        output[row['device_id']]['etherpad'] = {}
        output[row['device_id']]['etherpad'][:pads]     = []
        output[row['device_id']]['etherpad'][:users]    = []
        output[row['device_id']]['etherpad'][:datasize] = []
      end
      output[row['device_id']]['etherpad'][:pads]     << {date: row['timestamp'], pads: row['pads']} if row['pads']
      output[row['device_id']]['etherpad'][:users]    << {date: row['timestamp'], users: row['users']} if row['users']
      output[row['device_id']]['etherpad'][:datasize] << {date: row['timestamp'], datasize: row['datasize']} if row['datasize']
    end
    q = "SELECT * FROM framadate f INNER JOIN devices d ON f.device_id = d.id"
    a = con.query(q)
    a.each_hash do |row|
      output[row['device_id']] = {} unless output[row['device_id']]
      unless output[row['device_id']]['framadate']
        output[row['device_id']]['framadate'] = {}
        output[row['device_id']]['framadate'][:polls]    = []
        output[row['device_id']]['framadate'][:votes]    = []
        output[row['device_id']]['framadate'][:comments] = []
      end
      output[row['device_id']]['framadate'][:polls]    << {date: row['timestamp'], polls: row['polls']} if row['polls']
      output[row['device_id']]['framadate'][:votes]    << {date: row['timestamp'], votes: row['votes']} if row['votes']
      output[row['device_id']]['framadate'][:comments] << {date: row['timestamp'], comments: row['comments']} if row['comments']
    end
    q = "SELECT * FROM guestbook f INNER JOIN devices d ON f.device_id = d.id"
    a = con.query(q)
    a.each_hash do |row|
      output[row['device_id']] = {} unless output[row['device_id']]
      unless output[row['device_id']]['guestbook']
        output[row['device_id']]['guestbook'] = {}
        output[row['device_id']]['guestbook'][:submissions] = []
        output[row['device_id']]['guestbook'][:comments]    = []
        output[row['device_id']]['guestbook'][:images]      = []
        output[row['device_id']]['guestbook'][:datasize]    = []
      end
      output[row['device_id']]['guestbook'][:submissions] << {date: row['timestamp'], submissions: row['submissions']} if row['submissions']
      output[row['device_id']]['guestbook'][:comments]    << {date: row['timestamp'], comments: row['comments']} if row['comments']
      output[row['device_id']]['guestbook'][:images]      << {date: row['timestamp'], images: row['images']} if row['images']
      output[row['device_id']]['guestbook'][:datasize]    << {date: row['timestamp'], datasize: row['datasize']} if row['datasize']
    end
    q = "SELECT * FROM system s INNER JOIN devices d ON s.device_id = d.id"
    a = con.query(q)
    a.each_hash do |row|
      output[row['device_id']] = {} unless output[row['device_id']]
      unless output[row['device_id']]['system']
        output[row['device_id']]['system'] = {}
      end
      output[row['device_id']]['system'][:timestamp] = row['timestamp']
      output[row['device_id']]['system'][:cpu_temp]  = row['cpu_temperature']
      output[row['device_id']]['system'][:cpu_usage] = row['cpu_usage']
      output[row['device_id']]['system'][:ram_usage] = row['ram_usage']
      output[row['device_id']]['system'][:storage]   = row['storage']
    end
    output
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    return output
  ensure
    con.close if con
  end

  def getAllAvailableSensorsFromDB
    MaziLogger.debug("getAllAvailableSensorsFromDB")
    if @config[:general][:mode] == 'demo'
      return [{type: 'sensehat', status: 'active', id: 1, ip: '10.0.0.1', nof_entries: 12}, {type: 'sht11', status: 'not found', id: 2, ip: '10.0.0.1', nof_entries: 0}]
    end

    mysql_username, mysql_password = mysql_creds
    sensors_con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    q = "SELECT * FROM sensors"

    a = sensors_con.query(q)
    result = []
    a.each_hash do |h|
      result << {type: h['sensor_name'], id: h['id'], ip: h['ip']}
    end
    return result
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    return nil
  ensure
    sensors_con.close if sensors_con
  end

  def getAllAvailableSensors
    if @config[:general][:mode] == 'demo'
      return [{type: 'sensehat', status: 'active', id: 1, ip: '10.0.0.1', nof_entries: 12}, {type: 'sht11', status: 'not found', id: 2, ip: '10.0.0.1', nof_entries: 0}]
    end
    unless sensors_db_exist?
      sensors = []
      i = 0
      `bash /root/back-end/mazi-sense.sh -a`.split("\n").each do |line|
        sensors << {id: i, type: line.split[0], status: line.split[1], ip: line.split[2], nof_entries: 0}
        i += 1
      end
      return sensors
    end
    mysql_username, mysql_password = mysql_creds
    begin
      con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    rescue Mysql::Error => ex
      con = nil
    end
    result = []
    `bash /root/back-end/mazi-sense.sh -a`.split("\n").each do |line|
      line = line.split
      sensor_type = line[0]
      tmp = {}
      tmp[:type]        = line[0]
      tmp[:status]      = line[1]
      tmp[:ip]          = line[2]
      tmp[:id]          = line[3]
      tmp[:nof_entries] = 0
      begin
        q = "SELECT COUNT(*) FROM sensors s INNER JOIN measurements m ON m.sensor_id = '#{tmp[:id]}'"
        a = con.query(q)
        a.each_hash do |row|
          tmp[:nof_entries] = row["COUNT(*)"]
        end
      rescue Mysql::Error => ex
        tmp[:nof_entries] = 0
      end
      result << tmp
    end
    return result
  ensure
    con.close if con
  end

  def getTemperatures(id, type, start_time=nil, end_time=nil)
    MaziLogger.debug("getTemperatures: #{id} #{type} #{start_time} #{end_time}")
    if @config[:general][:mode] == 'demo'
      return [{date: '2012-10-01', temp: 30}, {date: '2012-10-02', temp: 31}, {date: '2012-10-03', temp: 32}, {date: '2012-10-04', temp: 29}, {date: '2012-10-05', temp: 28}, {date: '2012-10-06', temp: 25}, {date: '2012-10-07', temp: 32}, {date: '2012-10-08',temp: 33}, {date: '2012-10-09', temp: 17}, {date: '2012-10-10', temp: 19}, {date: '2012-10-11', temp: 21}, {date: '2012-10-12', temp: 24}, {date: '2012-10-13', temp: 20}, {date: '2012-10-14', temp: 18}, {date: '2012-10-15', temp: 32}, {date: '2012-10-16', temp: 24}, {date: '2012-10-17', temp: 15}, {date: '2012-10-18', temp: 14}, { date: '2012-10-19', temp: -11}, {date: '2012-10-20', temp: -12}, {date: '2012-10-21', temp: 29}, {date: '2012-10-22', temp: 31}, {date: '2012-10-23', temp: 15}, {date: '2012-10-24', temp: 16}, {date: '2012-10-25', temp: 17}, {date: '2012-10-26', temp: 18}, {date: '2012-10-27', temp: 19}, {date: '2012-10-28', temp: 20}, {date: '2012-10-29', temp: 21}, {date: '2012-10-30', temp: 22}, {date: '2012-10-31', temp: 50}]
    end

    mysql_username, mysql_password = mysql_creds
    sensors_con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    if start_time == '*' && end_time == '*'
      q = "SELECT * FROM measurements"
    elsif start_time == '*'
      q = "SELECT * FROM measurements WHERE time <= '#{end_time}'"
    elsif end_time == '*'
      q = "SELECT * FROM measurements WHERE time >= '#{start_time}'"
    elsif start_time.nil? && end_time.nil?
      q = "SELECT * FROM measurements #{SELECT_QUERY_LIMIT}"
    elsif start_time && end_time
      q = "SELECT * FROM measurements WHERE time >= '#{start_time}' AND time <= '#{end_time}'"
    else
      q = "SELECT * FROM measurements"
    end

    a = sensors_con.query(q)
    result = []
    a.each_hash do |h|
      result << {date: h['time'], temp: h['temperature']}
    end
    return result
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    return nil
  ensure
    sensors_con.close if sensors_con
  end

  def getHumidities(id, type, start_time=nil, end_time=nil)
    if @config[:general][:mode] == 'demo'
      return [{date: '2012-10-01', hum: 55}, {date: '2012-10-02', hum: 56}, {date: '2012-10-03', hum: 58}, {date: '2012-10-04', hum: 70}, {date: '2012-10-05', hum: 60}, {date: '2012-10-06', hum: 65}, {date: '2012-10-07', hum: 45}, {date: '2012-10-08',hum: 44}, {date: '2012-10-09', hum: 39}, {date: '2012-10-10', hum: 49}, {date: '2012-10-11', hum: 54}, {date: '2012-10-12', hum: 53}, {date: '2012-10-13', hum: 54}, {date: '2012-10-14', hum: 60}, {date: '2012-10-15', hum: 70}, {date: '2012-10-16', hum: 77}, {date: '2012-10-17', hum: 78}, {date: '2012-10-18', hum: 79}, { date: '2012-10-19', hum: 80}, {date: '2012-10-20', hum: 81}, {date: '2012-10-21', hum: 82}, {date: '2012-10-22', hum: 83}, {date: '2012-10-23', hum: 45}, {date: '2012-10-24', hum: 46}, {date: '2012-10-25', hum: 50}, {date: '2012-10-26', hum: 50}, {date: '2012-10-27', hum: 50}, {date: '2012-10-28', hum: 50}, {date: '2012-10-29', hum: 50}, {date: '2012-10-30', hum: 50}, {date: '2012-10-31', hum: 99}]
    end

    mysql_username, mysql_password = mysql_creds
    sensors_con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    if start_time == '*' && end_time == '*'
      q = "SELECT * FROM measurements"
    elsif start_time == '*'
      q = "SELECT * FROM measurements WHERE time <= '#{end_time}'"
    elsif end_time == '*'
      q = "SELECT * FROM measurements WHERE time >= '#{start_time}'"
    elsif start_time.nil? && end_time.nil?
      q = "SELECT * FROM measurements #{SELECT_QUERY_LIMIT}"
    elsif start_time && end_time
      q = "SELECT * FROM measurements WHERE time >= '#{start_time}' AND time <= '#{end_time}'"
    else
      q = "SELECT * FROM measurements"
    end

    a = sensors_con.query(q)
    result = []
    a.each_hash do |h|
      result << {date: h['time'], hum: h['humidity']}
    end
    return result
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    return nil
  ensure
    sensors_con.close if sensors_con
  end

  def start_sensing(sensor_name, duration = 1800, interval = 30, end_point='localhost')
    MaziLogger.debug "start sensing: #{sensor_name} - #{duration} - #{interval} - #{end_point}"

    Thread.new do
      if sensor_name == "sensehat"
        if end_point == 'localhost'
          `bash /root/back-end/mazi-sense.sh -n #{sensor_name} -t -h -p -s -d #{duration} -i #{interval}`
        else
          `bash /root/back-end/mazi-sense.sh -n #{sensor_name} -t -h -p -s -d #{duration} -i #{interval} -D #{end_point}`
        end
      else
        if end_point == 'localhost'
          `bash /root/back-end/mazi-sense.sh -n #{sensor_name} -t -h -s -d #{duration} -i #{interval}`
        else
          `bash /root/back-end/mazi-sense.sh -n #{sensor_name} -t -h -s -d #{duration} -i #{interval} -D #{end_point}`
        end
      end
    end
    sleep 1
    true
  end

  def delete_measurements(sensor_id)
    MaziLogger.debug "start delete_measurements: #{sensor_id}"
    mysql_username, mysql_password = mysql_creds
    sensors_con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    q = "DELETE FROM measurements WHERE sensor_id = #{sensor_id}"
    sensors_con.query(q)
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    return nil
  ensure
    sensors_con.close if sensors_con
  end

  def mysql_creds
    data = JSON.parse(File.read(MYSQL_PASS_FILE))
    [data["username"], data["password"]]
  end

  def get_sensor_status(id)
    MaziLogger.debug "get_sensor_status: #{id}"
    mysql_username, mysql_password = mysql_creds
    sensors_con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    q = "SELECT * FROM sensors WHERE id = #{id}"
    a = sensors_con.query(q)
    a.each_hash do |h|
      type = h["sensor_name"]
      `bash /root/back-end/mazi-sense.sh --status`.split("\n").each do |line|
        line = line.split
        if line[0] == type
          return line[1]
        end
      end
    end
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    return nil
  ensure
    sensors_con.close if sensors_con
  end

  def get_nof_sensor_measurements(id)
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    q = "SELECT COUNT(*) FROM measurements WHERE sensor_id = #{id}"
    a = con.query(q)
    a.each_hash do |row|
      return row["COUNT(*)"]
    end
  end

  def start_sensehat_metrics
    command = 'bash /root/back-end/mazi-sense.sh -n sensehat -m -ac -g'
    Thread.new do
      begin
        PTY.spawn( command ) do |stdout, stdin, pid|
          begin
            stdin.close
            stdout.each { |line|
              line = line.split
              if line.first == 'direction'
                @sensehat_metrics[:comp] = line.last.to_f.round(2)
              elsif line.first == 'pitch:'
                @sensehat_metrics[:gyro][0] = line.last.to_f.round(2)
              elsif line.first == 'yaw:'
                @sensehat_metrics[:gyro][1] = line.last.to_f.round(2)
              elsif line.first == 'roll:'
                @sensehat_metrics[:gyro][2] = line.last.to_f.round(2)
              elsif line.first == 'ac_x:'
                @sensehat_metrics[:acc][0] = line.last.to_f.round(2)
              elsif line.first == 'ac_y:'
                @sensehat_metrics[:acc][1] = line.last.to_f.round(2)
              elsif line.first == 'ac_z:'
                @sensehat_metrics[:acc][2] = line.last.to_f.round(2)
              end
            }
          rescue Errno::EIO
            MaziLogger.debug "bash /root/back-end/mazi-sense.sh Errno:EIO error, but this probably just means that the process has finished giving output"
          end
        end
      rescue PTY::ChildExited
        MaziLogger.debug "The child process exited!"
      end
    end
  end

  def stop_sensehat_metrics
    pid = `ps aux | grep -v grep | grep 'bash /root/back-end/mazi-sense.sh -n sensehat -m -ac -g' | awk '{print $2}'`
    `kill -9 #{pid}`
  end

  def get_sensehat_metrics
    @sensehat_metrics
  end
end
