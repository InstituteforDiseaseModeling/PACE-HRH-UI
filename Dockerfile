FROM rocker/shiny-verse:latest

RUN apt-get update


#Copy files
WORKDIR /srv/shiny-server
COPY .. /srv/shiny-server/


# Install PACE-HRH R packages

RUN Rscript install_packages.R

# expose shiny error
ENV SHINY_LOG_STDERR=1
EXPOSE 3838

RUN sudo chown -R shiny:shiny /srv/shiny-server

CMD ["/usr/bin/shiny-server"]
