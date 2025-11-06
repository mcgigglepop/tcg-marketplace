#!/bin/bash
go build -o tcg-marketplace-build cmd/web/*.go && ./tcg-marketplace-build  -cache=false -production=false -cognito-user-pool-id=us-east-1234 -cognito-client-id=1234