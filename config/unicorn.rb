# Set the working application directory
# working_directory "/path/to/your/app"
working_directory "/srv/skoolgate/"

# Unicorn PID file location

# Path to logs
# stderr_path "/path/to/log/unicorn.log"
# stdout_path "/path/to/log/unicorn.log"
stderr_path "/srv/skoolgate/log/unicorn.stderr.log"
stdout_path "/srv/skoolgate/log/unicorn_stdout.log"

# Unicorn socket
listen "/tmp/unicorn.skoolgate.sock"
# listen "/tmp/unicorn.myapp.sock"

# Number of processes
worker_processes 4
# worker_processes 2

# Time-out
timeout 30
