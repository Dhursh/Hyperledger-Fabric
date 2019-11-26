#!/bin/bash
#
#copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -e
# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
starttime=$(date +%s)
LANGUAGE=${1:-"node"}
# clean the keystore
rm -rf ./hfc-key-store
docker-compose -f docker-compose-cli.yaml down
export IMAGE_TAG=latest
docker-compose -f docker-compose-ca.yaml up -d ca0 ca1
docker-compose -f docker-compose-cli.yaml up -d orderer.example.com peer0.org1.example.com peer1.org2.example.com
docker-compose -f docker-compose-couch.yaml up -d couchdb
# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export 
export FABRIC_START_TIMEOUT=10
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}
# Create the channel
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
# Join peer0.org1.example.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block
# fetch channel config block org2
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users1/Admin@org2.example.com/msp"  peer0.org2.example.com peer channel fetch 0 mychannel.block -c mychannel -o orderer.example.com:7050
# join org2 peer to channel
docker exec -e  "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users1/Admin@org2.example.com/msp"  peer0.org2.example.com peer channel join -b mychannel.block
# update anchor peers
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp"  peer0.org1.example.com  peer channel update -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/Org1MSPanchors.tx
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users1/Admin@org2.example.com/msp"  peer0.org2.example.com  peer channel update -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/Org2MSPanchors.tx
docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users1/Admin@org3.example.com/msp"  peer0.org3.example.com  peer channel update -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/Org3MSPanchors.tx
