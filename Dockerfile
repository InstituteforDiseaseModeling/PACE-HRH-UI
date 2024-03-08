FROM rocker/shiny-verse:4

RUN apt-get update

# Install R packages
COPY install_packages.R .
RUN Rscript install_packages.R
RUN R -e "devtools::install_github('trestletech/shinyStore')"

#Copy files
COPY .. /srv/shiny-server/

# Install PACE-HRH R package
WORKDIR /srv/shiny-server
RUN R -e "devtools::install_github('InstituteforDiseaseModeling/PACE-HRH', subdir='pacehrh')"
# expose shiny error
ENV SHINY_LOG_STDERR=1
EXPOSE 3838

RUN sudo chown -R shiny:shiny /srv/shiny-server

CMD ["/usr/bin/shiny-server"]
