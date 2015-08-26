# STUPS Cassandra

STUPS Cassandra is a [Senza](https://stups.io/senza/) appliance for the 
[STUPS](https://stups.io) AWS environment.
It enables quick boostrapping of Cassandra clusters and basic node failure handling.

Due to the dynamic nature of the STUPS environment this appliance does seed 
registration and discovery using etcd. To support this we built a custom seed
provider, the [Etcd Seed Provider]
(https://github.com/zalando/cassandra-etcd-seed-provider).

The steps below explain how to get your own Cassandra cluster up and running.
If you already have your own etcd appliance running this can be achieve with
one single command!

Additionaly, the cluster can register itself into an existing [STUPS Opscenter]
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

### EtcdDomain

The only mandatory parameter is the ``EtcdDomain``. The Cassandra cluster will 
bootstrap one node at a time, carefully registering a reasonable amount of seed
nodes. Such registrarion and the required distributed locking is done using etcd.
If you followed the instructions from 
[Spilo](http://spilo.readthedocs.org/en/latest/user-guide/deploy_etcd/) 
you'll have an Etcd domain similar to etcd.<my-team-name>.<domain>.
This is the value you need to specify here.

All the remaining parameters have defaults and you don't need to override them,
unless you want to. 

### ClusterSize

The default cluster size is 3 nodes. With this setting there will be a single
seed node in the cluster. For such a modest cluster this can be considered
acceptable. If you increase the cluster size to anything bigger than 3 nodes it
will elect 3 nodes to become seeds nodes. You define the cluster size using the
``ClusterSize`` parameter.

### ImageVersion

This appliance will be kept in sync with the latest Docker image deployed to the
STUPS Open Source Docker Registry (os-registry.stups.zalan.do). You can still
override the image version to some other version using the ``ImageVersion`` parameter.

### OpsCenterIp

If you want to manually specify the IP address of your existing Opscenter
installation you can do so by specifying the ``OpsCenterIp`` parameter. If you
created your OpsCenter instance using the [STUPS Opscenter]
(https://github.com/zalando/stups-opscenter) appliance you can leave the default
and the nodes will discover the OpsCenter appliance and register there.

### ScalyrKey

If you're using Scalyr, one of the supported log shipping providers from Taupage, 
you can specify your Scalyr API key and it will be used to ship your node logs.
For this you specify the value of the ``ScalyrKey`` parameter. if you leave it 
blank logs will be kept locally and you'll have to SSH into the nodes to check them.

### ApplicationId

It's also possible that you created your own application record in [YourTurn]
(https://stups.io/yourturn/) for auditing purposes. If this is the case you 
can also override the ``ApplicationId`` parameter specifying your own 
application id.

## Howto

Creating an instance of this appliance is very easy. You just need to provide 1
parameter which is your etcd domain. Assuming your team's Hosted Zone is
``fsociety.example.com`` and your etcd domain is ``etcd.fsociety.example.com``
you would run senza like:

    senza create stups-cassandra.yaml cluster1 etcd.fsociety.example.com
    
Where ``cluster1`` is the Stack version and it's also used as the name 
for the new cluster.


## Known issues

- After the first seed node, each new node will try to register the cluster again. This is harmless but stupid.

## Todo

- Advanced failure management, particularly to replace dead seed nodes

## License

Copyright 2015 Zalando SE

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
