# Security

## Reporting

Email `security@whisper.security`. We read it and we answer.

## What is in this repository

Measurement data and a shell script. There is no service here and no credential material: every key
recorded in this dataset is a public key that its operator publishes at a well-known URL for anyone
to fetch.

## If your host appears here and you think we got it wrong

Open an issue or email the address above. Every classification is one HTTPS request from being
rechecked, the script that produced it is in the repository, and we will correct the dataset and say
in the commit message what changed and why. Three findings in this report were already corrected that
way before publication.

## If you would rather we did not probe you

Our crawler identifies itself and links to our RFC 9511 probing declaration at
`https://whisper.online/.well-known/probing.txt`, which carries the contact address. Tell us and we
will drop the host from the population.
