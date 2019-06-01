# This application serves as an example for generating log output that will be picked up by grok_exporter and kubernetes
require 'logger'

log_location = ARGV[0]
logger = Logger.new(log_location)
logger.info("| ACNTST_C: #{Random.rand(100)} | ACNTST_C_HVA: #{Random.rand(100)} | ACTIVE_PINGS: #{Random.rand(100)} | B_WRITERS: #{Random.rand(100)} |")