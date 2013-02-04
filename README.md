# Bulldozer

A distributed job tracking service.

# Security model

Bulldozer assumes that all its clients are trusted processes that you
control. It does its best to protect against bugs, but a malicious
attacker with control of the network could likely cause arbitrary code
to execute.
