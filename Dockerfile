FROM rocker/tidyverse:latest

RUN install2.r --error \
    --deps TRUE \
    renv

COPY src ./opt/src

COPY ./entry_point.sh /opt/
RUN chmod +x /opt/entry_point.sh

COPY ./requirements.txt /opt/
COPY /packages /usr/local/lib/R/site-library

RUN mkdir -p /opt/tmp && chmod 1777 /opt/tmp
ENV TMPDIR /opt/tmp
ENV TEMP /opt/tmp
ENV TMP /opt/tmp

WORKDIR /opt/src

ENV R_LIBS_USER=/usr/local/lib/R/site-library


RUN R -e "devtools::install_version('glmnet', version = '4.1-8')"
RUN R -e "devtools::install_version('jsonlite', version='1.8.7', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages(c('mlr3', 'mlr3tuning', 'mlr3hyperband', 'mlr3pipelines', 'mlr3filters', 'mlr3misc', 'mlr3oml', 'mlr3learners', 'mlr3extralearners', 'checkmate', 'data.table', 'future', 'lgr', 'paradox', 'xgboost', 'LiblineaR', 'ranger', 'testthat', 'mlbench', 'randomForest', 'e1071', 'class', 'glmnet', 'kknn', 'MASS', 'rpart', 'rpart.plot', 'C50', 'liquidSVM', 'nnet'))"

USER 1000

ENTRYPOINT ["/opt/entry_point.sh"]
