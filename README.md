# FusionPBX + FreeSWITCH + PostgreSQL (containerized)

This repository contains a Docker Compose setup for FusionPBX, FreeSWITCH and PostgreSQL.

Key points:
- FreeSWITCH runs with `network_mode: host` for SIP and RTP (avoid NAT for RTP).

How to use:
1. Build and start:
   docker build --no-cache --progress=plain -t fusionpbx-docker . 2> build.log
   docker compose up -d

Notes:
- Single stage build at the moment, expect rather large docker image
