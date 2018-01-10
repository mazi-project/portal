SENSORS_DB_IP      = 'localhost'                 # this should be localhost
SELECT_QUERY_LIMIT = 'GROUP BY id DESC LIMIT 50' # default query for the select on the sensors db
SENSORS_ENABLED    = true                        # a quick way to disable the sensors module
MONITORING_DB      = 'monitoring'                # the database name on localhost
MYSQL_PASS_FILE    = '/etc/mazi/sql.conf'        # the mysql creds file

module MaziSensors
  def init_sensors
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    @sensors_enabled = true
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    @sensors_enabled = false
  ensure
    con.close if con
  end

  def initialize_sensors_module(password)
    # `sh /root/back-end/mazi-sense.sh --init #{password}`
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    # i = 1
    # `sh /root/back-end/mazi-sense.sh -a`.split("\n").each do |line|
    #   line = line.split
    #   con.query("INSERT INTO type(name, ip) VALUES('#{line[0]}', '#{line[2]}')")
    #   con.query("CREATE TABLE IF NOT EXISTS sensor_#{i}(id INT PRIMARY KEY AUTO_INCREMENT, time DATETIME, temperature VARCHAR(4), humidity VARCHAR(4))")
    #   i += 1
    # end
    @sensors_enabled = true
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL."
    @sensors_enabled = false
  ensure
    con.close if con
  end

  def sensors_enabled?
    SENSORS_ENABLED && @config[:sensors] && @config[:sensors][:enable] && @sensors_enabled
  end

  def sensors_db_exist?
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    @sensors_enabled = true
    true
  rescue Mysql::Error => ex
    MaziLogger.error "Cannot connect to mySQL, Sensor interface is disabled"
    @sensors_enabled = false
    false
  ensure
    con.close if con
  end

  def toggle_sensors_enabled
    current_value = @config[:sensors][:enable]
    changeConfigFile("sensors->enable", !current_value)
    writeConfigFile
  end

  def getAllAvailableSensors
    if @config[:general][:mode] == 'demo'
      return [{type: 'sensehat', status: 'active', id: 1, ip: '10.0.0.1', nof_entries: 12}, {type: 'sht11', status: 'not found', id: 2, ip: '10.0.0.1', nof_entries: 0}]
    end
    unless sensors_db_exist?
      puts "aaa"
      sensors = []
      i = 0
      `sh /root/back-end/mazi-sense.sh -a`.split("\n").each do |line|
        sensors << {id: i, type: line.split[0], status: line.split[1], ip: line.split[2], nof_entries: 0}
        i += 1
      end
      return sensors
    end
    mysql_username, mysql_password = mysql_creds
    con = Mysql.new(SENSORS_DB_IP, mysql_username, mysql_password, MONITORING_DB)
    result = []
    `sh /root/back-end/mazi-sense.sh -a`.split("\n").each do |line|
      line = line.split
      sensor_type = line[0]
      tmp = {}
      tmp[:type]   = line[0]
      tmp[:status] = line[1]
      tmp[:ip]     = line[2]
      q = "SELECT COUNT(*), sensors.id FROM sensors INNER JOIN measurements ON sensors.id = measurements.sensor_id AND sensors.ip = '#{tmp[:ip]}' AND sensors.sensor_name = '#{tmp[:type]}'"
      a = con.query(q)
      a.each_hash do |row|
        tmp[:nof_entries] = row["COUNT(*)"]
        tmp[:id]          = row["id"]
      end
      result << tmp
    end
    return result
  rescue Mysql::Error => ex
    MaziLogger.debug "mySQL error: #{ex.inspect}"
    return []
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
          `sh /root/back-end/mazi-sense.sh -n #{sensor_name} -t -h -p -s -d #{duration} -i #{interval}`
        else
          `sh /root/back-end/mazi-sense.sh -n #{sensor_name} -t -h -p -s -d #{duration} -i #{interval} -D #{end_point}`
        end
      else
        if end_point == 'localhost'
          `sh /root/back-end/mazi-sense.sh -n #{sensor_name} -t -h -s -d #{duration} -i #{interval}`
        else
          `sh /root/back-end/mazi-sense.sh -n #{sensor_name} -t -h -s -d #{duration} -i #{interval} -D #{end_point}`
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
      `sh /root/back-end/mazi-sense.sh --status`.split("\n").each do |line|
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
end