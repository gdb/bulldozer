# Bulldozer

A distributed job running service.

# Security model

Bulldozer assumes that all its clients are trusted processes that you
control. It does its best to protect against bugs, but a malicious
attacker with control of the network can cause arbitrary code to
execute. That is, after all, what job running services are for.
