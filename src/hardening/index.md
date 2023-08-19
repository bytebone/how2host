# Hardening

## What is hardening?

"Server hardening" is the practice of making a server more secure by putting in place various measures that protect it from potential threats. These measures involve setting up strong defenses to prevent unauthorized access, cyberattacks, and data breaches. Think of it like adding locks, alarms, and security cameras to a building to keep out intruders and keep valuable things safe.

## What can I do?

There are many different ways to protect a server against intrusion, and it is a topic that many engineers have as their exclusive, full time job. These guides will obviously not go into such a depth, and will instead cover only the most common points of entry.

As a rule of thumb, **the most secure entrance is one that doesn't exist**. You can use a firewall to lock every port of your server down, and then add selective rules controlling which ports are allowed to be used, and where traffic is allowed to come from and go to. This helps block unauthorized access and malicious threats from getting in.

Additionally, you can stop password-guessing attacks by rate-limiting - a technique where you set a limit on how many requests can come in within a specific timeframe. By limiting the incoming data, this can prevent performance issues and block bruteforce attacks on the apps you host and the server itself.