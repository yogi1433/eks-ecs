FROM ubuntu:latest
ENV MY_NAME="Mobinulla"
ENV MY_COMPANY="AmvoWordPressWebsite"
LABEL Designedby="Mubeen" Email="smobinulla@gmail.com"
RUN apt update -y && apt install -y wget unzip net-tools tree vim nginx
RUN mkdir html
RUN wget https://downloads.wordpress.org/theme/medisat.1.0.3.zip
RUN rm -rf /var/www/html
RUN unzip medisat.1.0.3.zip -d /var/www/html
CMD ["nginx","-g","daemon off;"]
