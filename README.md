# STUPS Cassandra
----

STUPS Cassandra is a Senza appliance enabling quick Cassandra cluster creation 
and basic node failure handling for the [STUPS](https://stups.io) environment.

Due to the dynamic nature of the STUPS environment this appliance does seed 
discovery using etcd and a custom seed provider, the 
[Etcd Seed Provider](https://github.com/zalando/cassandra-etcd-seed-provider).

The steps below explain how to get your own Cassandra cluster up and running.
If you already have your own etcd appliance running this can be achieve in one 
single step.

Additionaly, the cluster will register itself into an existing [STUPS Opscenter]
(https://github.com/zalando/stups-opscenter) appliance.

## Node configuration

Each node will be created as a c3.2xlarge instance. These instances have 
2 x 80GB SSDs. A RAID0 volume is created with those two SSDs and given to
Cassandra as a single volume for both data and commit logs.

These instances are [suggested as adequate]
(http://docs.datastax.com/en/cassandra/2.1/cassandra/install/installAMILaunch.html)
for SSD production with light data.

## Parameters

There are some parameters you can use to change the appliance's behavior. Some
of those parameters provide sane defaults but you can always override those
defaults with values that better match your own requirements.

    +----------------+------------------------------------------------------------------+---------------------+
    | Parameter      | Description                                                      | Default             |
    +----------------+------------------------------------------------------------------+---------------------+
    | EtcdDomain     | Your etcd appliance domain name                                  | NONE                |
    | ClusterSize    | The initial size (number of nodes) for the new Cassandra cluster | 3                   |
    | ImageVersion   | Opscenter docker image version (for ex. 5.2.0-p0)                | 2.1.8-p0-SNAPSHOT   |
    | OpsCenterIp    | Register to Opscenter using Ip address                           | Discover using etcd |
    | ScalyrKey      | The API key of Scalyr logging service used by Taupage            | Don't use Scalyr    |
    | ApplicationId  | The application id according to yourturn                         | stups-cassandra     |
    +----------------+------------------------------------------------------------------+---------------------+

        
The only mandatory parameter is the ``EtcdDomain``. The Cassandra cluster will 
bootstrap one node at a time carefully registering a reasonable amount of seed
nodes. Such registrarion and the required distributed locking is done using etcd.
If you followed the instructions from 
[Spilo](http://spilo.readthedocs.org/en/latest/user-guide/deploy_etcd/) 
you'll have an Etcd domain similar to etcd.<my-team-name>.<domain>.
This is the value you need to specify here.

All the remaining parameters have defaults and you don't need to override them
unless you want to. 

The default cluster size is 3 nodes which will elect one of them as the single
seed node in the cluster. For such a modest cluster this can be considered
acceptable. If you increase the cluster size to anything bigger than 3 nodes it
will elect 3 nodes to become seeds nodes.

This appliance will be kept in sync with the latest Docker image deployed to 
STUPS Open Source Docker Registry (os-registry.stups.zalan.do). You can still
override this version to some other existing image if you need to, using the
``ImageVersion`` parameter.

If you want to manually specify the IP address of your existing Opscenter
installation you can do so by specifying the ``OpsCenterIp`` parameter. If you
created your OpsCenter instance using the [STUPS Opscenter]
(https://github.com/zalando/stups-opscenter) appliance you can leave the default
and the nodes will discover the OpsCenter appliance and register there.

If you're using Scalyr, one of the supported log shipping providers from Taupage, 
you can specify your Scalyr API key and it will be used to ship your node logs.
Leaving it blank will just keep them locally and you'll have to SSH into the
nodes to check them.

It's also possible that you created your own application record in YourTurn for
auditing purposes. If this is the case you can also override the ``ApplicationId``
parameter specifying your own application id.

## Howto

Creating an instance of this appliance is very easy. You just need to provide 1
parameter which is your etcd domain. Assuming your team's Hosted Zone is
``cassandra.rocks.org`` and your etcd domain is ``etcd.cassandra.rocks.org``
you would run senza like:

    senza create stups-cassandra.yaml cluster1 etcd.cassandra.rocks.org
    
Where ``cluster1`` is the Stack version and is also used as the cluster name 
for the new cluster.


## Known issues

- Each new node will try to register the cluster again. This is harmless but stupid.
