require 'logger'

class MaziLogger

  def self.log
    if @logger.nil?
      @logger = Logger.new STDOUT
      @logger.level = Logger::DEBUG
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S '
    end
    if @filelogger.nil?
      @filelogger = Logger.new('/var/log/mazizone.log', 'daily')
      @filelogger.level = Logger::DEBUG
      @filelogger.datetime_format = '%Y-%m-%d %H:%M:%S '
    end
    [@logger, @filelogger]
  end

  def self.info(msg)
    logger, filelogger = self.log
    logger.info(msg)
    filelogger.info(msg)
  end

  def self.debug(msg)
    logger, filelogger = self.log
    logger.debug(msg)
    filelogger.debug(msg)
  end

  def self.error(msg)
    logger, filelogger = self.log
    logger.error(msg)
    filelogger.error(msg)
  end

  def self.warn(msg)
    logger, filelogger = self.log
    logger.warn(msg)
    filelogger.warn(msg)
  end

  def self.read_log_file(nof_lines = 100)
    `tail -n #{nof_lines} /var/log/mazizone.log`
  end
end
