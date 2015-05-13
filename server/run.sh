#!/bin/bash

SECRET_PASS=$(< /dev/urandom tr -dc "[:alnum:]" | head -c96)
GRAYLOG_PASSWORD_DEFAULT=${GRAYLOG_PASSWORD:=admin}
GRAYLOG_PASSWORD_SHA=$(echo -n ${GRAYLOG_PASSWORD_DEFAULT} | shasum -a 256 | awk '{print $1}')

cat << EOF > /etc/graylog/server/server.conf
# If you are running more than one instances of graylog2-server you have to select one of these
# instances as master. The master will perform some periodical tasks that non-masters won't perform.
is_master = true

# The auto-generated node ID will be stored in this file and read after restarts. It is a good idea
# to use an absolute file path here if you are starting graylog2-server from init scripts or similar.
node_id_file = /etc/graylog/server/node-id

# You MUST set a secret to secure/pepper the stored user passwords here. Use at least 64 characters.
# Generate one by using for example: pwgen -N 1 -s 96
password_secret = ${SECRET_PASS}

# The default root user is named 'admin'
#root_username = admin

# You MUST specify a hash password for the root user (which you only need to initially set up the
# system and in case you lose connectivity to your authentication backend)
# This password cannot be changed using the API or via the web interface. If you need to change it,
# modify it in this file.
# Create one by using for example: echo -n yourpassword | shasum -a 256
# and put the resulting hash value into the following line
root_password_sha2 = ${GRAYLOG_PASSWORD_SHA}

# The email address of the root user.
# Default is empty
#root_email = ""

# The time zone setting of the root user.
# Default is UTC
#root_timezone = ${GRAYLOG_TIMEZONE:=UTC}

# Set plugin directory here (relative or absolute)
plugin_dir = plugin

# REST API listen URI. Must be reachable by other graylog2-server nodes if you run a cluster.
rest_listen_uri = http://0.0.0.0:12900/

# REST API transport address. Defaults to the value of rest_listen_uri. Exception: If rest_listen_uri
# is set to a wildcard IP address (0.0.0.0) the first non-loopback IPv4 system address is used.
# If set, his will be promoted in the cluster discovery APIs, so other nodes may try to connect on
# this address and it is used to generate URLs addressing entities in the REST API. (see rest_listen_uri)
# You will need to define this, if your Graylog server is running behind a HTTP proxy that is rewriting
# the scheme, host name or URI.
#rest_transport_uri = http://192.168.1.1:12900/

# Enable CORS headers for REST API. This is necessary for JS-clients accessing the server directly.
# If these are disabled, modern browsers will not be able to retrieve resources from the server.
# This is disabled by default. Uncomment the next line to enable it.
#rest_enable_cors = true

# Enable GZIP support for REST API. This compresses API responses and therefore helps to reduce
# overall round trip times. This is disabled by default. Uncomment the next line to enable it.
#rest_enable_gzip = true

# Enable HTTPS support for the REST API. This secures the communication with the REST API with
# TLS to prevent request forgery and eavesdropping. This is disabled by default. Uncomment the
# next line to enable it.
#rest_enable_tls = true

# The X.509 certificate file to use for securing the REST API.
#rest_tls_cert_file = /path/to/graylog2.crt

# The private key to use for securing the REST API.
#rest_tls_key_file = /path/to/graylog2.key

# The password to unlock the private key used for securing the REST API.
#rest_tls_key_password = secret

# The maximum size of a single HTTP chunk in bytes.
#rest_max_chunk_size = 8192

# The maximum size of the HTTP request headers in bytes.
#rest_max_header_size = 8192

# The maximal length of the initial HTTP/1.1 line in bytes.
#rest_max_initial_line_length = 4096

# The size of the execution handler thread pool used exclusively for serving the REST API.
#rest_thread_pool_size = 16

# The size of the worker thread pool used exclusively for serving the REST API.
#rest_worker_threads_max_pool_size = 16

# Embedded Elasticsearch configuration file
# pay attention to the working directory of the server, maybe use an absolute path here
#elasticsearch_config_file = /etc/graylog/server/elasticsearch.yml

# Graylog will use multiple indices to store documents in. You can configured the strategy it uses to determine
# when to rotate the currently active write index.
# It supports multiple rotation strategies:
#   - "count" of messages per index, use elasticsearch_max_docs_per_index below to configure
#   - "size" per index, use elasticsearch_max_size_per_index below to configure
# valid values are "count", "size" and "time", default is "count"
rotation_strategy = count

# (Approximate) maximum number of documents in an Elasticsearch index before a new index
# is being created, also see no_retention and elasticsearch_max_number_of_indices.
# Configure this if you used 'rotation_strategy = count' above.
elasticsearch_max_docs_per_index = ${GRAYLOG_ELASTICSEARCH_MAX_DOCS_PER_INDEX:=20000000}

# (Approximate) maximum size in bytes per Elasticsearch index on disk before a new index is being created, also see
# no_retention and elasticsearch_max_number_of_indices. Default is 1GB.
# Configure this if you used 'rotation_strategy = size' above.
#elasticsearch_max_size_per_index = 1073741824

# (Approximate) maximum time before a new Elasticsearch index is being created, also see
# no_retention and elasticsearch_max_number_of_indices. Default is 1 day.
# Configure this if you used 'rotation_strategy = time' above.
# Please note that this rotation period does not look at the time specified in the received messages, but is
# using the real clock value to decide when to rotate the index!
# Specify the time using a duration and a suffix indicating which unit you want:
#  1w  = 1 week
#  1d  = 1 day
#  12h = 12 hours
# Permitted suffixes are: d for day, h for hour, m for minute, s for second.
#elasticsearch_max_time_per_index = 1d

# Disable checking the version of Elasticsearch for being compatible with this Graylog release.
# WARNING: Using Graylog with unsupported and untested versions of Elasticsearch may lead to data loss!
#elasticsearch_disable_version_check = true

# Disable message retention on this node, i. e. disable Elasticsearch index rotation.
#no_retention = false

# How many indices do you want to keep?
elasticsearch_max_number_of_indices = ${GRAYLOG_ELASTICSEARCH_MAX_INDICES:=20}

# Decide what happens with the oldest indices when the maximum number of indices is reached.
# The following strategies are availble:
#   - delete # Deletes the index completely (Default)
#   - close # Closes the index and hides it from the system. Can be re-opened later.
retention_strategy = delete

# How many Elasticsearch shards and replicas should be used per index? Note that this only applies to newly created indices.
elasticsearch_shards = 4
elasticsearch_replicas = 0

# Prefix for all Elasticsearch indices and index aliases managed by Graylog.
elasticsearch_index_prefix = graylog2

# Do you want to allow searches with leading wildcards? This can be extremely resource hungry and should only
# be enabled with care. See also: https://www.graylog.org/documentation/general/queries/
allow_leading_wildcard_searches = false

# Do you want to allow searches to be highlighted? Depending on the size of your messages this can be memory hungry and
# should only be enabled after making sure your Elasticsearch cluster has enough memory.
allow_highlighting = false

# settings to be passed to elasticsearch's client (overriding those in the provided elasticsearch_config_file)
# all these
# this must be the same as for your Elasticsearch cluster
elasticsearch_cluster_name = ${GRAYLOG_ELASTICSEARCH_CLUSTER_NAME:=elasticsearch}

# you could also leave this out, but makes it easier to identify the graylog2 client instance
elasticsearch_node_name = $(hostname)

# we don't want the graylog2 server to store any data, or be master node
#elasticsearch_node_master = false
#elasticsearch_node_data = false

# use a different port if you run multiple Elasticsearch nodes on one machine
elasticsearch_transport_tcp_port = 9350

# we don't need to run the embedded HTTP server here
#elasticsearch_http_enabled = false

elasticsearch_discovery_zen_ping_multicast_enabled = false
elasticsearch_discovery_zen_ping_unicast_hosts = ${GRAYLOG_ELASTICSEARCH_UNICAST_HOSTS:=elasticsearch:9300}

# Change the following setting if you are running into problems with timeouts during Elasticsearch cluster discovery.
# The setting is specified in milliseconds, the default is 5000ms (5 seconds).
#elasticsearch_cluster_discovery_timeout = 5000

# the following settings allow to change the bind addresses for the Elasticsearch client in graylog2
# these settings are empty by default, letting Elasticsearch choose automatically,
# override them here or in the 'elasticsearch_config_file' if you need to bind to a special address
# refer to http://www.elasticsearch.org/guide/en/elasticsearch/reference/0.90/modules-network.html
# for special values here
#elasticsearch_network_host =
#elasticsearch_network_bind_host =
#elasticsearch_network_publish_host =

# The total amount of time discovery will look for other Elasticsearch nodes in the cluster
# before giving up and declaring the current node master.
#elasticsearch_discovery_initial_state_timeout = 3s

# Analyzer (tokenizer) to use for message and full_message field. The "standard" filter usually is a good idea.
# All supported analyzers are: standard, simple, whitespace, stop, keyword, pattern, language, snowball, custom
# Elasticsearch documentation: http://www.elasticsearch.org/guide/reference/index-modules/analysis/
# Note that this setting only takes effect on newly created indices.
elasticsearch_analyzer = standard

# Batch size for the Elasticsearch output. This is the maximum (!) number of messages the Elasticsearch output
# module will get at once and write to Elasticsearch in a batch call. If the configured batch size has not been
# reached within output_flush_interval seconds, everything that is available will be flushed at once. Remember
# that every outputbuffer processor manages its own batch and performs its own batch write calls.
# ("outputbuffer_processors" variable)
output_batch_size = 500

# Flush interval (in seconds) for the Elasticsearch output. This is the maximum amount of time between two
# batches of messages written to Elasticsearch. It is only effective at all if your minimum number of messages
# for this time period is less than output_batch_size * outputbuffer_processors.
output_flush_interval = 1

# As stream outputs are loaded only on demand, an output which is failing to initialize will be tried over and
# over again. To prevent this, the following configuration options define after how many faults an output will
# not be tried again for an also configurable amount of seconds.
output_fault_count_threshold = 5
output_fault_penalty_seconds = 30

# The number of parallel running processors.
# Raise this number if your buffers are filling up.
processbuffer_processors = 5
outputbuffer_processors = 3

#outputbuffer_processor_keep_alive_time = 5000
#outputbuffer_processor_threads_core_pool_size = 3
#outputbuffer_processor_threads_max_pool_size = 30

# UDP receive buffer size for all message inputs (e. g. SyslogUDPInput).
#udp_recvbuffer_sizes = 1048576

# Wait strategy describing how buffer processors wait on a cursor sequence. (default: sleeping)
# Possible types:
#  - yielding
#     Compromise between performance and CPU usage.
#  - sleeping
#     Compromise between performance and CPU usage. Latency spikes can occur after quiet periods.
#  - blocking
#     High throughput, low latency, higher CPU usage.
#  - busy_spinning
#     Avoids syscalls which could introduce latency jitter. Best when threads can be bound to specific CPU cores.
processor_wait_strategy = blocking

# Size of internal ring buffers. Raise this if raising outputbuffer_processors does not help anymore.
# For optimum performance your LogMessage objects in the ring buffer should fit in your CPU L3 cache.
# Start server with --statistics flag to see buffer utilization.
# Must be a power of 2. (512, 1024, 2048, ...)
ring_size = 65536

inputbuffer_ring_size = 65536
inputbuffer_processors = 2
inputbuffer_wait_strategy = blocking

# Enable the disk based message journal.
message_journal_enabled = true

# The directory which will be used to store the message journal. The directory must me exclusively used by Graylog and
# must not contain any other files than the ones created by Graylog itself.
message_journal_dir = data/journal

# Journal hold messages before they could be written to Elasticsearch.
# For a maximum of 12 hours or 5 GB whichever happens first.
# During normal operation the journal will be smaller.
#message_journal_max_age = 12h
#message_journal_max_size = 5gb

#message_journal_flush_age = 1m
#message_journal_flush_interval = 1000000
#message_journal_segment_age = 1h
#message_journal_segment_size = 100mb

# Number of threads used exclusively for dispatching internal events. Default is 2.
#async_eventbus_processors = 2

# EXPERIMENTAL: Dead Letters
# Every failed indexing attempt is logged by default and made visible in the web-interface. You can enable
# the experimental dead letters feature to write every message that was not successfully indexed into the
# MongoDB "dead_letters" collection to make sure that you never lose a message. The actual writing of dead
# letter should work fine already but it is not heavily tested yet and will get more features in future
# releases.
dead_letters_enabled = false

# How many seconds to wait between marking node as DEAD for possible load balancers and starting the actual
# shutdown process. Set to 0 if you have no status checking load balancers in front.
lb_recognition_period_seconds = 3

# Every message is matched against the configured streams and it can happen that a stream contains rules which
# take an unusual amount of time to run, for example if its using regular expressions that perform excessive backtracking.
# This will impact the processing of the entire server. To keep such misbehaving stream rules from impacting other
# streams, Graylog limits the execution time for each stream.
# The default values are noted below, the timeout is in milliseconds.
# If the stream matching for one stream took longer than the timeout value, and this happened more than "max_faults" times
# that stream is disabled and a notification is shown in the web interface.
#stream_processing_timeout = 2000
#stream_processing_max_faults = 3

# Length of the interval in seconds in which the alert conditions for all streams should be checked
# and alarms are being sent.
#alert_check_interval = 60

# Since 0.21 the graylog2 server supports pluggable output modules. This means a single message can be written to multiple
# outputs. The next setting defines the timeout for a single output module, including the default output module where all
# messages end up.
#
# Time in milliseconds to wait for all message outputs to finish writing a single message.
#output_module_timeout = 10000

# Time in milliseconds after which a detected stale master node is being rechecked on startup.
#stale_master_timeout = 2000

# Time in milliseconds which Graylog is waiting for all threads to stop on shutdown.
#shutdown_timeout = 30000

# MongoDB Configuration
mongodb_useauth = false
mongodb_user = ${GRAYLOG_MONGODB_USER:=grayloguser}
mongodb_password = ${GRAYLOG_MONGODB_PASS:=123}
mongodb_host = ${GRAYLOG_MONGODB_HOST:=mongodb}
mongodb_replica_set = ${GRAYLOG_MONGODB_REPLICA_SET}
mongodb_database = ${GRAYLOG_MONGODB_DATABASE:=graylog}
mongodb_port = ${GRAYLOG_MONGO_PORT:=27017}

# Raise this according to the maximum connections your MongoDB server can handle if you encounter MongoDB connection problems.
mongodb_max_connections = ${GRAYLOG_MONGO_MAX_CONNECTIONS:=100}

# Number of threads allowed to be blocked by MongoDB connections multiplier. Default: 5
# If mongodb_max_connections is 100, and mongodb_threads_allowed_to_block_multiplier is 5, then 500 threads can block. More than that and an exception will be thrown.
# http://api.mongodb.org/java/current/com/mongodb/MongoOptions.html#threadsAllowedToBlockForConnectionMultiplier
mongodb_threads_allowed_to_block_multiplier = 5

# Drools Rule File (Use to rewrite incoming log messages)
# See: https://www.graylog.org/documentation/general/rewriting/
#rules_file = /etc/graylog/server/rules.drl

# Email transport
transport_email_enabled = ${GRAYLOG_SMTP_ENABLED:=false}
transport_email_hostname = ${GRAYLOG_SMTP_SERVER:=mail}
transport_email_port = ${GRAYLOG_SMTP_PORT:=25}
transport_email_use_auth = ${GRAYLOG_SMTP_USE_AUTH:=false}
transport_email_use_tls = ${GRAYLOG_SMTP_USE_TLS:=false}
transport_email_use_ssl = ${GRAYLOG_SMTP_USE_SSL:=false}
transport_email_auth_username = ${GRAYLOG_SMTP_USERNAME}
transport_email_auth_password = ${GRAYLOG_SMTP_PASSWORD}
transport_email_subject_prefix = [graylog2]
transport_email_from_email = ${GRAYLOG_SMTP_FROM_EMAIL:=graylog@example.com}

# Specify and uncomment this if you want to include links to the stream in your stream alert mails.
# This should define the fully qualified base url to your web interface exactly the same way as it is accessed by your users.
transport_email_web_interface_url = ${GRAYLOG_INTERFACE_URL:=http://graylog.example.com}

# HTTP proxy for outgoing HTTP calls
#http_proxy_uri =

# Disable the optimization of Elasticsearch indices after index cycling. This may take some load from Elasticsearch
# on heavily used systems with large indices, but it will decrease search performance. The default is to optimize
# cycled indices.
#disable_index_optimization = true

# Optimize the index down to <= index_optimization_max_num_segments. A higher number may take some load from Elasticsearch
# on heavily used systems with large indices, but it will decrease search performance. The default is 1.
#index_optimization_max_num_segments = 1

# Disable the index range calculation on all open/available indices and only calculate the range for the latest
# index. This may speed up index cycling on systems with large indices but it might lead to wrong search results
# in regard to the time range of the messages (i. e. messages within a certain range may not be found). The default
# is to calculate the time range on all open/available indices.
#disable_index_range_calculation = true

# The threshold of the garbage collection runs. If GC runs take longer than this threshold, a system notification
# will be generated to warn the administrator about possible problems with the system. Default is 1 second.
#gc_warning_threshold = 1s

# Connection timeout for a configured LDAP server (e. g. ActiveDirectory) in milliseconds.
#ldap_connection_timeout = 2000

# https://github.com/bazhenov/groovy-shell-server
#groovy_shell_enable = false
#groovy_shell_port = 6789

# Enable collection of Graylog-related metrics into MongoDB
#enable_metrics_collection = false

# Disable the use of SIGAR for collecting system stats
#disable_sigar = false
EOF

/opt/graylog/bin/graylogctl run
