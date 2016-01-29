#!/bin/sh
# CLUSTER_NAME
# DATA_DIR
# COMMIT_LOG_DIR
# LISTEN_ADDRESS


if [ -z "$CLUSTER_NAME" ] ;
then
    echo "Cluster name is not defined."
    exit 1
fi

if [ -z "$SEEDS" ] ;
then
    echo "Seeds are not defined."
    exit 1
fi

if [ -z "$OPSCENTER" ] ;
then
    echo "OpsCenter address was not defined."
    exit 1
fi

# TODO: use public-ipv4 if multi-region
if [ -z "$LISTEN_ADDRESS" ] ;
then
    export LISTEN_ADDRESS=$(curl -Ls -m 4 http://169.254.169.254/latest/meta-data/local-ipv4)
fi
echo "Node IP address is $LISTEN_ADDRESS ..."

# TODO: Use diff. Snitch if Multi-Region
if [ -z $SNITCH ] ;
then
    export SNITCH="Ec2Snitch"
fi

if [ -z "$DATACENTER" ] ;
then
    echo "Data center name for nodes was not defined."
    exit 1
fi
export AZ=$(curl -Ls -m 4 http://169.254.169.254/latest/meta-data/placement/availability-zone)
echo "Data center: $DATACENTER. Availability zone. $AZ. Writing cassandra-rackdc.properties."
echo "dc=$DATACENTER" > /opt/cassandra/conf/cassandra-rackdc.properties
echo "rack=$AZ" >> /opt/cassandra/conf/cassandra-rackdc.properties
echo "cassandra-rackdc.properties:"
cat /opt/cassandra/conf/cassandra-rackdc.properties
     
export DATA_DIR=${DATA_DIR:-/var/cassandra/data}
export COMMIT_LOG_DIR=${COMMIT_LOG_DIR:-/var/cassandra/data/commit_logs}
            
echo "Finished bootstrapping node."

if [ -n "$OPSCENTER" ] ;
then
    echo "Configuring OpsCenter agent ..."
    echo "stomp_interface: $OPSCENTER" > /var/lib/datastax-agent/conf/address.yaml
    echo "hosts: [\"$LISTEN_ADDRESS\"]" >> /var/lib/datastax-agent/conf/address.yaml
    echo "cassandra_conf: /opt/cassandra/conf/cassandra.yaml" >> /var/lib/datastax-agent/conf/address.yaml
    echo "address.yaml:"
    cat /var/lib/datastax-agent/conf/address.yaml

    echo "Starting OpsCenter agent in the background ..."
    service datastax-agent restart
fi

echo "Generating configuration from template ..."
python -c "import os; print os.path.expandvars(open('/opt/cassandra/conf/cassandra_template.yaml').read())" > /opt/cassandra/conf/cassandra.yaml


echo "Starting Cassandra ..."
/opt/cassandra/bin/cassandra -f \
    -Dcassandra.logdir=/var/cassandra/log \
    -Dcassandra.cluster_name=${CLUSTER_NAME} \
    -Dcassandra.listen_address=${LISTEN_ADDRESS} \
    -Dcassandra.broadcast_rpc_address=${LISTEN_ADDRESS}

