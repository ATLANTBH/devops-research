# This application serves as an example for generating log output that will be picked up by grok_exporter and kubernetes
require 'logger'

max_loop = ARGV[0]
log_location = ARGV[1]

logger = Logger.new(log_location)

current_loop = 0

while current_loop < max_loop.to_i do
  logger.info("| ACNTST_C: #{Random.rand(100)} | ACNTST_C_HVA: #{Random.rand(100)} | ACTIVE_PINGS: #{Random.rand(100)} | B_WRITERS: #{Random.rand(100)} |")
  sleep 1
  current_loop = current_loop + 1
end