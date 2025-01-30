# Partie 2
2-a- /var/www/html
2-b- wp-content
3-a- Port choisi: 8080
    sur 8080: aucune sorite
    sur 8081: curl: (7) Failed to connect to localhost port 8081 after 0 ms: Couldn't connect to server
3-c- Logs: on constate des log de connection après chaque appel à localhost:8080
    WordPress not found in /var/www/html - copying now...
    Complete! WordPress has been successfully copied to /var/www/html
    AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message
    AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message
    [Thu Jan 30 09:14:00.361466 2025] [mpm_prefork:notice] [pid 1:tid 1] AH00163: Apache/2.4.62 (Debian) PHP/8.2.27 configured -- resuming normal operations
    [Thu Jan 30 09:14:00.361561 2025] [core:notice] [pid 1:tid 1] AH00094: Command line: 'apache2 -D FOREGROUND'
    172.17.0.1 - - [30/Jan/2025:09:14:12 +0000] "GET / HTTP/1.1" 302 235 "-" "curl/8.5.0"
    172.17.0.1 - - [30/Jan/2025:09:15:41 +0000] "GET / HTTP/1.1" 302 235 "-" "curl/8.5.0"
3-d- on arrive à une page de connection de DB (beige) de WordPress

# Partie 3
4- j'ai eu une page de refus de connection db (surement j'ai du me tromper sur les identifiants)