#!/bin/bash
go build -o collectorset-build cmd/web/*.go && ./collectorset-build  -cache=false -production=false