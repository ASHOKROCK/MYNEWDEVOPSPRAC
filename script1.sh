#!/bin/bash
#Author:ASHOK
echo "Checking and describing a aws document db cluster info"
DOC=$(aws docdb describe-db-clusters \
    --db-cluster-identifier awsnewmongodb\
    --query 'DBClusters[*].[DBClusterIdentifier,DBClusterParameterGroup]'  >/dev/null 2>&1)
echo "########################################"
echo "${DOC}"
echo "....................................................."
echo "Displaying aws document db parameter group info"
PARAMINFO=$(aws docdb describe-db-cluster-parameters \
        --db-cluster-parameter-group-name mynewmongogroup >/dev/null 2>&1)
echo "................................................"
echo "${PARAMINFO}"
