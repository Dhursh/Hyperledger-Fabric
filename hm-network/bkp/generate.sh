#!/bin/sh
#
#copyright IBM Corp All Rights Reserved
# SCRIPT FOR GENERATING CERTIFICATES AND ARTIFACTS
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=
CHANNEL_NAME=mychannel
# remove previous crypto material and config transactions
rm -fr config/*
rm -fr crypto-config/*
# generate crypto material
./bin/cryptogen generate --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
echo "Failed to generate crypto material..."
exit 1
fi
# generate genesis block for orderer
./bin/configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./genesis.block
if [ "$?" -ne 0 ]; then
echo "Failed to generate orderer genesis block..."
exit 1
fi
# generate channel configuration transaction
./bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
echo "Failed to generate channel configuration transaction..."
exit 1
fi
# generate anchor peer transaction
./bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
if [ "$?" -ne 0 ]; then
echo "Failed to generate anchor peer update for Org1MSP..."
exit 1
fi
# generate anchor peer transaction
./bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
if [ "$?" -ne 0 ]; then
echo "Failed to generate anchor peer update for Org2MSP..."
exit 1
fi
